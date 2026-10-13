import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/repositories.dart';
import '../../auth/application/session_controller.dart';
import '../application/devices_controller.dart';
import 'widgets/qr_scanner_sheet.dart';

/// Add Tracker: identify → asset type → asset name → success.
class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  int _step = 0;
  final _id = TextEditingController();
  final _name = TextEditingController();
  final _reg = TextEditingController();
  AssetType? _type;
  String? _error;
  String? _model;
  bool _busy = false;
  String? _addedId;

  static const _titles = ['Add Tracker', 'Select Asset Type', 'Asset Name', 'Done'];

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _reg.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final id = await showQrScanner(context);
    if (id != null && mounted) {
      _id.text = id;
      await _verify();
    }
  }

  Future<void> _verify() async {
    final id = _id.text.trim().toUpperCase();
    if (id.isEmpty) {
      setState(() => _error = 'Enter the device ID printed on your tracker.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(trackingRepositoryProvider).verifyDeviceId(id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.valid) {
        _model = result.model;
        _id.text = id;
        _step = 1;
      } else {
        _error = result.message;
      }
    });
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give your ${_type!.label.toLowerCase()} a name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final device = await ref.read(devicesProvider.notifier).add(NewDeviceRequest(
            deviceId: _id.text,
            assetType: _type!,
            assetName: name,
            registration: _reg.text,
            category: ref.read(accountTypeProvider) == AccountType.personal
                ? AssetCategory.personal
                : AssetCategory.business,
          ));
      if (!mounted) return;
      setState(() {
        _addedId = device.id;
        _step = 3;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() {
    setState(() {
      _step = 0;
      _id.clear();
      _name.clear();
      _reg.clear();
      _type = null;
      _addedId = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final cta = _cta();
    return PopScope(
      canPop: _step == 0 || _step == 3,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        body: SafeArea(
          child: ResponsiveCenter(
            maxWidth: 560,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
                  child: Row(
                    children: [
                      if (_step == 3)
                        const SizedBox(width: 48, height: 48)
                      else
                        IconButton(
                          icon: Icon(_step == 0 ? AppIcons.close : AppIcons.back, size: 22, color: theme.colorScheme.onSurface),
                          onPressed: () => _step == 0 ? context.pop() : setState(() => _step--),
                        ),
                      const SizedBox(width: 4),
                      Expanded(child: Text(_titles[_step], style: theme.textTheme.titleSmall?.copyWith(fontSize: 15))),
                      if (_step < 3)
                        Text('Step ${_step + 1} of 3',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500)),
                    ],
                  ),
                ),
                Container(
                  height: 4,
                  margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 10),
                  decoration: BoxDecoration(color: tones.neutral800, borderRadius: BorderRadius.circular(2)),
                  clipBehavior: Clip.antiAlias,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: AppDurations.medium,
                      curve: Curves.easeOut,
                      widthFactor: (_step + 1).clamp(1, 3) / 3,
                      heightFactor: 1,
                      child: ColoredBox(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppDurations.medium,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(key: ValueKey(_step), child: _buildStep(context)),
                  ),
                ),
                if (cta != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: tones.divider))),
                    child: cta,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The full-width primary action in the bottom bar for the current step.
  Widget? _cta() {
    const size = Size.fromHeight(48);
    return switch (_step) {
      0 => FilledButton(
          key: const Key('add-device-continue'),
          style: FilledButton.styleFrom(minimumSize: size),
          onPressed: _busy ? null : _verify,
          child: _busy ? const _Busy(label: 'Verifying tracker...') : const Text('Continue'),
        ),
      2 => FilledButton(
          key: const Key('add-device-submit'),
          style: FilledButton.styleFrom(minimumSize: size),
          onPressed: _busy ? null : _add,
          child: _busy ? const _Busy(label: 'Activating tracker...') : const Text('Add device'),
        ),
      3 => FilledButton(
          key: const Key('add-device-view'),
          style: FilledButton.styleFrom(minimumSize: size),
          onPressed: () => context.pushReplacement(Routes.device(_addedId!)),
          child: Text('Open ${_name.text.trim()}'),
        ),
      _ => null,
    };
  }

  Widget _buildStep(BuildContext context) => switch (_step) {
        0 => _identifyStep(context),
        1 => _typeStep(context),
        2 => _nameStep(context),
        _ => _successStep(context),
      };

  static const _stepPadding = EdgeInsets.fromLTRB(AppSpacing.lg, 6, AppSpacing.lg, AppSpacing.lg);

  Widget _heading(BuildContext context, String title, [String? sub]) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 22)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub, style: theme.textTheme.bodyMedium?.copyWith(color: context.tones.neutral400)),
          ],
        ],
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: context.tones.neutral500)),
      );

  Widget _errorText(BuildContext context) {
    if (_error == null) return const SizedBox.shrink();
    final tones = context.tones;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        children: [
          Icon(AppIcons.warning, size: 16, color: tones.crit),
          AppSpacing.gapSm,
          Expanded(
            child: Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tones.critInk)),
          ),
        ],
      ),
    );
  }

  Widget _identifyStep(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final accent = theme.colorScheme.primary;
    return ListView(
      padding: _stepPadding,
      children: [
        _heading(context, 'Find your tracker', 'Scan the QR code on the back of the tracker or on the box, or type its ID.'),
        Material(
          color: tones.neutral900,
          borderRadius: AppRadius.lgAll,
          child: InkWell(
            borderRadius: AppRadius.lgAll,
            onTap: _busy ? null : _scan,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent, width: 2),
                      boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 30)],
                    ),
                    child: Icon(AppIcons.qr, size: 36, color: tones.accent300),
                  ),
                  AppSpacing.gapLg,
                  Text('Scan QR', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Point your camera at the code on the tracker',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral400)),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('OR', style: theme.textTheme.labelSmall?.copyWith(color: tones.neutral500, letterSpacing: 0.9)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ),
        _fieldLabel(context, 'Enter Device ID'),
        TextField(
          key: const Key('add-device-id'),
          controller: _id,
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (_) => _verify(),
          decoration: InputDecoration(
            hintText: 'e.g. DEMO-001',
            prefixIcon: Icon(AppIcons.tracker, size: 20, color: tones.neutral400),
          ),
        ),
        AppSpacing.gapSm,
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ActionChip(
              label: const Text('Use demo ID: DEMO-001'),
              onPressed: () => _id.text = 'DEMO-001',
            ),
          ],
        ),
        _errorText(context),
      ],
    );
  }

  Widget _typeStep(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final facts = [
      ('Device ID', _id.text, null),
      ('Model', _model ?? 'TrackPro tracker', null),
      ('Status', 'Found', tones.ok),
    ];
    return ListView(
      padding: _stepPadding,
      children: [
        _heading(context, 'What is it attached to?', 'Pick the closest match. You can change the icon later.'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Column(
            children: [
              for (var i = 0; i < facts.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: i < facts.length - 1
                      ? BoxDecoration(border: Border(bottom: BorderSide(color: tones.divider)))
                      : null,
                  child: Row(
                    children: [
                      Text(facts[i].$1,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.neutral500)),
                      const Spacer(),
                      if (facts[i].$3 != null) ...[
                        Icon(AppIcons.success, size: 14, color: facts[i].$3),
                        const SizedBox(width: 4),
                      ],
                      Text(facts[i].$2,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontSize: 13, color: facts[i].$3 ?? theme.colorScheme.onSurface)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        AppSpacing.gapLg,
        LayoutBuilder(builder: (context, c) {
          const cols = 4;
          const gap = AppSpacing.sm;
          final w = (c.maxWidth - (cols - 1) * gap) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final t in AssetType.selectable)
                SizedBox(
                  width: w,
                  child: AppCard(
                    key: Key('asset-type-${t.name}'),
                    radius: AppRadius.mdAll,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    onTap: () => setState(() {
                      _type = t;
                      _error = null;
                      _step = 2;
                    }),
                    border: Border.all(
                      color: _type == t ? theme.colorScheme.primary : AppColors.transparent,
                      width: 1.5,
                    ),
                    child: Column(
                      children: [
                        Icon(AppIcons.asset(t), size: 22, color: theme.colorScheme.onSurface),
                        const SizedBox(height: 6),
                        Text(
                          t == AssetType.item ? 'Other' : t.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _nameStep(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final t = _type!;
    return ListView(
      padding: _stepPadding,
      children: [
        _heading(context, 'Name your tracker'),
        AppCard(
          radius: AppRadius.mdAll,
          padding: AppSpacing.cardCompact,
          child: Row(
            children: [
              Icon(AppIcons.asset(t), size: 18, color: tones.accent300),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${t == AssetType.item ? 'Other' : t.label} · ${_id.text}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
              ),
            ],
          ),
        ),
        AppSpacing.gapLg,
        _fieldLabel(context, 'Asset Name'),
        TextField(
          key: const Key('add-device-name'),
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
          decoration: InputDecoration(
            hintText: switch (t) {
              AssetType.pet => 'e.g. Bruno',
              AssetType.key => 'e.g. Car keys',
              AssetType.person => 'e.g. Aarav',
              AssetType.truck => 'e.g. Truck 22',
              AssetType.taxi => 'e.g. Taxi 22',
              _ => 'Name',
            },
          ),
        ),
        if (t.usesRegistration) ...[
          AppSpacing.gapLg,
          _fieldLabel(context, 'Registration number (optional)'),
          TextField(
            controller: _reg,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'e.g. DL01AB1234'),
          ),
        ],
        _errorText(context),
      ],
    );
  }

  Widget _successStep(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 60, AppSpacing.lg, AppSpacing.lg),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: tones.ok, width: 1.5)),
              child: Icon(AppIcons.check, color: tones.ok, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text('Device Added Successfully', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 14),
        Text(
          '${_name.text.trim()} is now live. Its location will appear on the map within seconds.',
          style: theme.textTheme.bodyMedium?.copyWith(color: tones.neutral400),
        ),
        const SizedBox(height: 28),
        OutlinedButton(onPressed: _reset, child: const Text('Add another tracker')),
        AppSpacing.gapSm,
        TextButton(onPressed: () => context.pop(), child: const Text('Done')),
      ],
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          AppSpacing.gapMd,
          Text(label),
        ],
      );
}
