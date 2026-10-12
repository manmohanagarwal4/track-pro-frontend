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
    return PopScope(
      canPop: _step == 0 || _step == 3,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_step]),
          leading: _step == 3
              ? null
              : IconButton(
                  icon: Icon(_step == 0 ? AppIcons.close : AppIcons.back),
                  onPressed: () => _step == 0 ? context.pop() : setState(() => _step--),
                ),
          automaticallyImplyLeading: false,
        ),
        body: ResponsiveCenter(
          maxWidth: 560,
          child: Column(
            children: [
              if (_step < 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        Expanded(
                          child: AnimatedContainer(
                            duration: AppDurations.medium,
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= _step ? theme.colorScheme.primary : theme.colorScheme.outline,
                              borderRadius: AppRadius.pillAll,
                            ),
                          ),
                        ),
                        if (i < 2) AppSpacing.gapSm,
                      ],
                    ],
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) => switch (_step) {
        0 => _identifyStep(context),
        1 => _typeStep(context),
        2 => _nameStep(context),
        _ => _successStep(context),
      };

  Widget _errorText(BuildContext context) => _error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Row(
            children: [
              Icon(AppIcons.warning, size: 16, color: Theme.of(context).colorScheme.error),
              AppSpacing.gapSm,
              Expanded(
                child: Text(_error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        );

  Widget _identifyStep(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: AppSpacing.screenAll,
      children: [
        AppCard(
          onTap: _busy ? null : _scan,
          child: Column(
            children: [
              const IconBadge(icon: AppIcons.qr, color: AppColors.iris, size: 64),
              AppSpacing.gapMd,
              Text('Scan QR', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Point your camera at the code on the tracker',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('OR', style: theme.textTheme.labelSmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ),
        Text('Enter Device ID', style: theme.textTheme.titleSmall),
        AppSpacing.gapSm,
        TextField(
          key: const Key('add-device-id'),
          controller: _id,
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (_) => _verify(),
          decoration: const InputDecoration(hintText: 'e.g. DEMO-001', prefixIcon: Icon(AppIcons.tracker, size: 20)),
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
        AppSpacing.gapXl,
        FilledButton(
          key: const Key('add-device-continue'),
          onPressed: _busy ? null : _verify,
          child: _busy ? const _Busy(label: 'Verifying tracker...') : const Text('Continue'),
        ),
      ],
    );
  }

  Widget _typeStep(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: AppSpacing.screenAll,
      children: [
        AppCard(
          padding: AppSpacing.cardCompact,
          child: Row(
            children: [
              const Icon(AppIcons.success, color: AppColors.moving, size: 20),
              AppSpacing.gapMd,
              Expanded(child: Text('${_id.text} found · ${_model ?? 'TrackPro tracker'}', style: theme.textTheme.bodyMedium)),
            ],
          ),
        ),
        AppSpacing.gapLg,
        Text('What will this tracker be attached to?', style: theme.textTheme.titleSmall),
        AppSpacing.gapMd,
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 420 ? 4 : 3;
          final w = (c.maxWidth - (cols - 1) * AppSpacing.md) / cols;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final t in AssetType.selectable)
                SizedBox(
                  width: w,
                  child: AppCard(
                    key: Key('asset-type-${t.name}'),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    onTap: () => setState(() {
                      _type = t;
                      _error = null;
                      _step = 2;
                    }),
                    border: _type == t ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null,
                    child: Column(
                      children: [
                        Icon(AppIcons.asset(t), color: theme.colorScheme.primary, size: 28),
                        AppSpacing.gapSm,
                        Text(t == AssetType.item ? 'Other' : t.label,
                            style: theme.textTheme.labelMedium, textAlign: TextAlign.center),
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
    final t = _type!;
    return ListView(
      padding: AppSpacing.screenAll,
      children: [
        Center(child: IconBadge(icon: AppIcons.asset(t), color: theme.colorScheme.primary, size: 72)),
        AppSpacing.gapLg,
        Text('Asset Name', style: theme.textTheme.titleSmall),
        AppSpacing.gapSm,
        TextField(
          key: const Key('add-device-name'),
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
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
          Text('Registration number (optional)', style: theme.textTheme.titleSmall),
          AppSpacing.gapSm,
          TextField(
            controller: _reg,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'e.g. DL01AB1234'),
          ),
        ],
        _errorText(context),
        AppSpacing.gapXl,
        FilledButton(
          key: const Key('add-device-submit'),
          onPressed: _busy ? null : _add,
          child: _busy ? const _Busy(label: 'Activating tracker...') : const Text('Add device'),
        ),
      ],
    );
  }

  Widget _successStep(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: AppColors.moving, shape: BoxShape.circle),
                child: const Icon(AppIcons.check, color: Colors.white, size: 48),
              ),
            ),
            AppSpacing.gapXl,
            Text('Device Added Successfully', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            AppSpacing.gapSm,
            Text(
              '${_name.text.trim()} is now live. Its location will appear on the map within seconds.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('add-device-view'),
                onPressed: () => context.pushReplacement(Routes.device(_addedId!)),
                child: Text('Open ${_name.text.trim()}'),
              ),
            ),
            AppSpacing.gapMd,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: _reset, child: const Text('Add another tracker')),
            ),
            AppSpacing.gapSm,
            TextButton(onPressed: () => context.pop(), child: const Text('Done')),
          ],
        ),
      ),
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
