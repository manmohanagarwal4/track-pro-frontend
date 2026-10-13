import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user.dart';
import '../../devices/application/devices_controller.dart';

final shareLinksProvider = FutureProvider.autoDispose.family<List<ShareLink>, String>(
  (ref, deviceId) => ref.watch(shareRepositoryProvider).getShareLinks(deviceId),
);

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  SharePermission _permission = SharePermission.liveTracking;
  Duration _duration = const Duration(hours: 6);
  bool _busy = false;
  ShareLink? _created;

  static const _durations = [Duration(hours: 1), Duration(hours: 6), Duration(hours: 24)];

  Future<void> _create() async {
    setState(() => _busy = true);
    final link = await ref.read(shareRepositoryProvider).createShareLink(
          deviceId: widget.deviceId,
          permission: _permission,
          duration: _duration,
        );
    ref.invalidate(shareLinksProvider(widget.deviceId));
    if (mounted) {
      setState(() {
        _busy = false;
        _created = link;
      });
    }
  }

  void _copy(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final view = ref.watch(deviceViewProvider(widget.deviceId));
    final links = ref.watch(shareLinksProvider(widget.deviceId));
    final now = clock.now();
    final meta = theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500);
    const label = EdgeInsets.fromLTRB(2, AppSpacing.xl, 0, AppSpacing.sm);
    return Scaffold(
      appBar: AppBar(title: Text('Share ${view?.name ?? ''}')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.huge),
        children: [
          ResponsiveCenter(
            maxWidth: 560,
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader('Permission', padding: EdgeInsets.fromLTRB(2, AppSpacing.xs, 0, AppSpacing.sm)),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: ListTileTheme.merge(
                      contentPadding: EdgeInsets.zero,
                      child: RadioGroup<SharePermission>(
                        groupValue: _permission,
                        onChanged: (p) => setState(() => _permission = p!),
                        child: Column(
                          children: [
                            for (final (i, p) in SharePermission.values.indexed) ...[
                              if (i > 0) const Divider(),
                              RadioListTile<SharePermission>(
                                value: p,
                                controlAffinity: ListTileControlAffinity.trailing,
                                title: Text(p.label),
                                subtitle: Text(p.description),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SectionHeader('Duration', padding: label),
                  SegmentedButton<Duration>(
                    segments: [
                      for (final d in _durations) ButtonSegment(value: d, label: Text('${d.inHours} hour${d.inHours == 1 ? '' : 's'}')),
                    ],
                    selected: {_duration},
                    onSelectionChanged: (s) => setState(() => _duration = s.first),
                  ),
                  AppSpacing.gapXl,
                  FilledButton.icon(
                    key: const Key('create-share'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: _busy ? null : _create,
                    icon: _busy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(AppIcons.link, size: 18),
                    label: const Text('Create Share Link'),
                  ),
                  AnimatedSwitcher(
                    duration: AppDurations.medium,
                    child: _created == null
                        ? const SizedBox.shrink()
                        : Padding(
                            key: ValueKey(_created!.id),
                            padding: const EdgeInsets.only(top: AppSpacing.lg),
                            child: AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(color: tones.okBg, borderRadius: AppRadius.mdAll),
                                    child: Row(
                                      children: [
                                        Icon(AppIcons.success, color: tones.okInk, size: 18),
                                        AppSpacing.gapSm,
                                        Text('Share link created.',
                                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.okInk)),
                                      ],
                                    ),
                                  ),
                                  AppSpacing.gapMd,
                                  SelectableText(_created!.url, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_created!.permission.label} · expires ${Fmt.dateTime(_created!.expiresAt)}',
                                    style: meta,
                                  ),
                                  AppSpacing.gapMd,
                                  OutlinedButton.icon(
                                    onPressed: () => _copy(_created!.url),
                                    icon: const Icon(AppIcons.copy, size: 18),
                                    label: const Text('Copy link'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SectionHeader('Active links', padding: label),
                  links.when(
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                    error: (e, _) => Text('$e'),
                    data: (list) {
                      final active = list.where((l) => l.isActive(now)).toList();
                      if (active.isEmpty) {
                        return Text('No active share links.',
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, color: tones.neutral500));
                      }
                      return AppCard(
                        padding: const EdgeInsets.fromLTRB(14, 2, 4, 2),
                        child: Column(
                          children: [
                            for (final (i, l) in active.indexed)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: i == active.length - 1
                                    ? null
                                    : BoxDecoration(border: Border(bottom: BorderSide(color: tones.divider))),
                                child: Row(
                                  children: [
                                    Icon(AppIcons.link, size: 19, color: tones.neutral400),
                                    AppSpacing.gapMd,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(l.url.replaceFirst('https://', ''),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15)),
                                          Text('${l.permission.label} · until ${Fmt.dateTime(l.expiresAt)}', style: meta),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Copy',
                                      onPressed: () => _copy(l.url),
                                      icon: Icon(AppIcons.copy, size: 18, color: tones.neutral400),
                                    ),
                                    IconButton(
                                      tooltip: 'Revoke',
                                      onPressed: () async {
                                        await ref.read(shareRepositoryProvider).revoke(l.id);
                                        ref.invalidate(shareLinksProvider(widget.deviceId));
                                        if (_created?.id == l.id) setState(() => _created = null);
                                      },
                                      icon: Icon(AppIcons.delete, size: 18, color: tones.crit),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
