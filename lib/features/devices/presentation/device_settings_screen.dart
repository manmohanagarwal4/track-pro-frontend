import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/tracker_device.dart';
import '../../../domain/device_view.dart';
import '../../assets/application/assets_controller.dart';
import '../../assets/presentation/asset_picker_sheet.dart';
import '../application/devices_controller.dart';

const _sectionPad = EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.sm);

class DeviceSettingsScreen extends ConsumerWidget {
  const DeviceSettingsScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(deviceViewProvider(deviceId));
    if (view == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyView(icon: AppIcons.devices, title: 'Device not found', message: 'It may have been removed.'),
      );
    }
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.huge + MediaQuery.paddingOf(context).bottom),
          children: [
            ResponsiveCenter(
              child: Padding(
                padding: AppSpacing.screen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Transform.translate(
                      offset: const Offset(-8, 0),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: Icon(AppIcons.back, size: 22, color: theme.colorScheme.onSurface),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Device settings', style: theme.textTheme.titleLarge),
                                Text(
                                  '${view.name} · ${view.device.model}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: context.tones.neutral500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (view.device.emergency) ...[
                      AppSpacing.gapMd,
                      const _EmergencyCallout(),
                    ],
                    const SectionHeader('General', padding: _sectionPad),
                    _GeneralSection(view: view),
                    const SectionHeader('Reporting interval', padding: _sectionPad),
                    _IntervalSection(view: view),
                    const SectionHeader('Tracking mode', padding: _sectionPad),
                    _TrackingModeSection(view: view),
                    const SectionHeader('Alerts', padding: _sectionPad),
                    _AlertSection(view: view),
                    AppSpacing.gapXxl,
                    _RemoveButton(view: view),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Changing the tracking mode, shared by the interval segments and the mode cards.
void _setMode(BuildContext context, WidgetRef ref, DeviceView view, TrackingMode m) {
  ref.read(devicesProvider.notifier).setTrackingMode(view.id, m);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${m.label} mode · updates every ${m.interval.inSeconds}s')),
  );
}

Iterable<TrackingMode> get _userModes => TrackingMode.values.where((m) => m != TrackingMode.emergency);

class _EmergencyCallout extends StatelessWidget {
  const _EmergencyCallout();

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tones.critBg,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: tones.crit.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.emergency, size: 18, color: tones.crit),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency mode is active',
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 13, color: tones.critInk)),
                const SizedBox(height: 2),
                Text('Reporting every second until turned off on the device page.',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.critInk)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Surface tile of rows separated by dividers.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.tones.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _GeneralSection extends ConsumerWidget {
  const _GeneralSection({required this.view});

  final DeviceView view;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final asset = view.asset;
    if (asset == null) return;
    final controller = TextEditingController(text: asset.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          key: const Key('rename-field'),
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            key: const Key('rename-save'),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || name == asset.name) return;
    await ref.read(assetsProvider.notifier).save(asset.copyWith(name: name));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Renamed to $name')));
    }
  }

  Future<void> _changeAsset(BuildContext context, WidgetRef ref) async {
    final pick = await showAssetPicker(context, deviceId: view.id, currentAssetId: view.device.assetId);
    if (pick == null) return;
    await ref.read(devicesProvider.notifier).assignAsset(view.id, pick.unassign ? null : pick.assetId);
  }

  Future<void> _changeIcon(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<AssetType>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final tones = ctx.tones;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Map icon', style: theme.textTheme.titleMedium),
                AppSpacing.gapLg,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final t in AssetType.values)
                      InkWell(
                        borderRadius: AppRadius.mdAll,
                        onTap: () => Navigator.pop(ctx, t),
                        child: Container(
                          width: 72,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          decoration: BoxDecoration(
                            color: tones.neutral900,
                            borderRadius: AppRadius.mdAll,
                            border: Border.all(
                              width: 1.5,
                              color: t == view.iconType ? theme.colorScheme.primary : AppColors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(AppIcons.asset(t), size: 22),
                              const SizedBox(height: 6),
                              Text(t.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null) return;
    final d = view.device;
    await ref.read(devicesProvider.notifier).updateDevice(
          picked == view.type ? d.copyWith(clearIcon: true) : d.copyWith(iconOverride: picked),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final chevron = Icon(AppIcons.chevronRight, size: 18, color: tones.neutral600);
    const pad = EdgeInsets.zero;
    return _Group(
      children: [
        ListTile(
          key: const Key('settings-rename'),
          contentPadding: pad,
          leading: const Icon(AppIcons.edit, size: 19),
          title: const Text('Rename'),
          subtitle: Text(view.asset?.name ?? 'Assign an asset to name this tracker'),
          trailing: chevron,
          enabled: view.asset != null,
          onTap: () => _rename(context, ref),
        ),
        ListTile(
          contentPadding: pad,
          leading: const Icon(AppIcons.assets, size: 19),
          title: const Text('Change asset'),
          subtitle: Text(view.asset == null ? 'Unassigned' : '${view.asset!.name} · ${view.type.label}'),
          trailing: chevron,
          onTap: () => _changeAsset(context, ref),
        ),
        ListTile(
          contentPadding: pad,
          leading: Icon(AppIcons.asset(view.iconType), size: 19),
          title: const Text('Change icon'),
          subtitle: Text(view.device.iconOverride == null ? 'Default for ${view.type.label}' : view.iconType.label),
          trailing: chevron,
          onTap: () => _changeIcon(context, ref),
        ),
        ListTile(
          contentPadding: pad,
          leading: const Icon(AppIcons.tracker, size: 19),
          title: const Text('Tracker'),
          subtitle: Text('${view.device.id} · ${view.device.model}'),
          trailing: Text(view.device.firmware,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.neutral500)),
        ),
      ],
    );
  }
}

class _IntervalSection extends ConsumerWidget {
  const _IntervalSection({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = view.device.trackingMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Update every',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13, color: context.tones.neutral400)),
        const SizedBox(height: 6),
        SegmentedButton<TrackingMode>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: [
            for (final m in _userModes) ButtonSegment(value: m, label: Text('${m.interval.inSeconds}s')),
          ],
          selected: {if (current != TrackingMode.emergency) current},
          onSelectionChanged: (s) {
            if (s.isNotEmpty && s.first != current) _setMode(context, ref, view, s.first);
          },
        ),
      ],
    );
  }
}

class _TrackingModeSection extends ConsumerWidget {
  const _TrackingModeSection({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final current = view.device.trackingMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        for (final m in _userModes)
          AppCard(
            key: Key('mode-${m.name}'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: Border.all(width: 1.5, color: m == current ? theme.colorScheme.primary : AppColors.transparent),
            onTap: m == current ? null : () => _setMode(context, ref, view, m),
            child: Semantics(
              selected: m == current,
              child: Row(
                children: [
                  Icon(
                    m == current ? AppIcons.success : AppIcons.circle,
                    size: 20,
                    color: m == current ? theme.colorScheme.primary : tones.neutral600,
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.label, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15)),
                        Text(m.description,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500)),
                      ],
                    ),
                  ),
                  Text('${m.interval.inSeconds}s',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.accent300)),
                ],
              ),
            ),
          ),
        Text(
          'Simulation values. Faster modes give smoother live tracking but use more battery.',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500),
        ),
      ],
    );
  }
}

class _AlertSection extends ConsumerWidget {
  const _AlertSection({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tones = context.tones;
    final cfg = view.device.alertConfig;
    void save(AlertConfig c) =>
        ref.read(devicesProvider.notifier).updateDevice(view.device.copyWith(alertConfig: c));
    Widget toggle(IconData icon, String title, bool value, ValueChanged<bool> onChanged, {String? subtitle}) =>
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(icon, size: 19, color: tones.neutral400),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          value: value,
          onChanged: onChanged,
        );
    return _Group(
      children: [
        if (view.type.isVehicle) ...[
          toggle(AppIcons.overspeed, 'Overspeed', cfg.overspeed, (v) => save(cfg.copyWith(overspeed: v)),
              subtitle: 'Alert above ${cfg.speedLimit.round()} km/h'),
          if (cfg.overspeed)
            Row(
              children: [
                Text('Limit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.neutral400)),
                Expanded(
                  child: Slider(
                    value: cfg.speedLimit,
                    min: 30,
                    max: 140,
                    divisions: 22,
                    label: '${cfg.speedLimit.round()} km/h',
                    onChanged: (v) => save(cfg.copyWith(speedLimit: v)),
                  ),
                ),
                Text('${cfg.speedLimit.round()} km/h', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13)),
              ],
            ),
        ],
        toggle(AppIcons.geofence, 'Geofence enter / exit', cfg.geofence, (v) => save(cfg.copyWith(geofence: v))),
        toggle(AppIcons.batteryLow, 'Low battery', cfg.lowBattery, (v) => save(cfg.copyWith(lowBattery: v)),
            subtitle: 'Below 20%'),
        toggle(AppIcons.offline, 'Device offline', cfg.offline, (v) => save(cfg.copyWith(offline: v))),
        toggle(AppIcons.emergency, 'SOS / emergency', cfg.sos, (v) => save(cfg.copyWith(sos: v))),
      ],
    );
  }
}

class _RemoveButton extends ConsumerWidget {
  const _RemoveButton({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tones = context.tones;
    final destructive = OutlinedButton.styleFrom(
      foregroundColor: tones.critInk,
      iconColor: tones.critInk,
      side: BorderSide(color: tones.crit),
    );
    return OutlinedButton.icon(
      key: const Key('remove-device'),
      style: destructive,
      icon: const Icon(AppIcons.delete, size: 18),
      label: const Text('Remove device'),
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Remove ${view.name}?'),
            content: const Text(
                'The tracker will stop reporting to your account. Its asset and history are kept and it can be added again later.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              OutlinedButton(
                key: const Key('remove-confirm'),
                style: destructive,
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
        if (ok != true || !context.mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        final router = GoRouter.of(context);
        await ref.read(devicesProvider.notifier).remove(view.id);
        router.go(Routes.devices);
        messenger.showSnackBar(SnackBar(content: Text('${view.name} removed')));
      },
    );
  }
}
