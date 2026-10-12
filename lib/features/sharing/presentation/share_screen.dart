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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final view = ref.watch(deviceViewProvider(widget.deviceId));
    final links = ref.watch(shareLinksProvider(widget.deviceId));
    final now = clock.now();
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
                  Text('Permission', style: theme.textTheme.titleSmall),
                  AppSpacing.gapSm,
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: RadioGroup<SharePermission>(
                      groupValue: _permission,
                      onChanged: (p) => setState(() => _permission = p!),
                      child: Column(
                        children: [
                          for (final p in SharePermission.values)
                            RadioListTile<SharePermission>(
                              value: p,
                              title: Text(p.label),
                              subtitle: Text(p.description),
                            ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapXl,
                  Text('Duration', style: theme.textTheme.titleSmall),
                  AppSpacing.gapSm,
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
                              color: AppColors.moving.withValues(alpha: 0.1),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(AppIcons.success, color: AppColors.moving, size: 20),
                                      AppSpacing.gapSm,
                                      Text('Share link created.',
                                          style: theme.textTheme.titleSmall?.copyWith(color: AppColors.moving)),
                                    ],
                                  ),
                                  AppSpacing.gapMd,
                                  SelectableText(_created!.url, style: theme.textTheme.bodyMedium),
                                  AppSpacing.gapSm,
                                  Text(
                                    '${_created!.permission.label} · expires ${Fmt.dateTime(_created!.expiresAt)}',
                                    style: theme.textTheme.bodySmall,
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
                  const SectionHeader('Active links', padding: EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, AppSpacing.sm)),
                  links.when(
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                    error: (e, _) => Text('$e'),
                    data: (list) {
                      final active = list.where((l) => l.isActive(now)).toList();
                      if (active.isEmpty) {
                        return Text('No active share links.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant));
                      }
                      return Column(
                        children: [
                          for (final l in active)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: AppCard(
                                padding: AppSpacing.cardCompact,
                                child: Row(
                                  children: [
                                    const IconBadge(icon: AppIcons.link, color: AppColors.iris, size: 36),
                                    AppSpacing.gapMd,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(l.url.replaceFirst('https://', ''),
                                              maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                                          Text('${l.permission.label} · until ${Fmt.dateTime(l.expiresAt)}',
                                              style: theme.textTheme.bodySmall),
                                        ],
                                      ),
                                    ),
                                    IconButton(onPressed: () => _copy(l.url), icon: const Icon(AppIcons.copy, size: 18)),
                                    IconButton(
                                      tooltip: 'Revoke',
                                      onPressed: () async {
                                        await ref.read(shareRepositoryProvider).revoke(l.id);
                                        ref.invalidate(shareLinksProvider(widget.deviceId));
                                        if (_created?.id == l.id) setState(() => _created = null);
                                      },
                                      icon: const Icon(AppIcons.delete, size: 18, color: AppColors.emergency),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
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
