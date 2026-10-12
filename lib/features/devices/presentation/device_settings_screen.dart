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
    return Scaffold(
      appBar: AppBar(title: const Text('Device settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.huge),
        children: [
          ResponsiveCenter(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GeneralSection(view: view),
                  const SectionHeader('Tracking mode', padding: EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, AppSpacing.sm)),
                  _TrackingModeSection(view: view),
                  const SectionHeader('Alerts', padding: EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, AppSpacing.sm)),
                  _AlertSection(view: view),
                  AppSpacing.gapXxl,
                  _RemoveButton(view: view),
                ],
              ),
            ),
          ),
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
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Map icon', style: Theme.of(ctx).textTheme.titleMedium),
              AppSpacing.gapLg,
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final t in AssetType.values)
                    InkWell(
                      borderRadius: AppRadius.mdAll,
                      onTap: () => Navigator.pop(ctx, t),
                      child: Container(
                        width: 64,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(
                            color: t == view.iconType ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.outline,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(AppIcons.asset(t), size: 24),
                            const SizedBox(height: 4),
                            Text(t.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(ctx).textTheme.labelSmall),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
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
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            key: const Key('settings-rename'),
            leading: const Icon(AppIcons.edit),
            title: const Text('Rename'),
            subtitle: Text(view.asset?.name ?? 'Assign an asset to name this tracker'),
            trailing: const Icon(AppIcons.chevronRight, size: 18),
            enabled: view.asset != null,
            onTap: () => _rename(context, ref),
          ),
          const Divider(indent: 56),
          ListTile(
            leading: const Icon(AppIcons.assets),
            title: const Text('Change asset'),
            subtitle: Text(view.asset == null ? 'Unassigned' : '${view.asset!.name} · ${view.type.label}'),
            trailing: const Icon(AppIcons.chevronRight, size: 18),
            onTap: () => _changeAsset(context, ref),
          ),
          const Divider(indent: 56),
          ListTile(
            leading: Icon(AppIcons.asset(view.iconType)),
            title: const Text('Change icon'),
            subtitle: Text(view.device.iconOverride == null ? 'Default for ${view.type.label}' : view.iconType.label),
            trailing: const Icon(AppIcons.chevronRight, size: 18),
            onTap: () => _changeIcon(context, ref),
          ),
          const Divider(indent: 56),
          ListTile(
            leading: const Icon(AppIcons.tracker),
            title: const Text('Tracker'),
            subtitle: Text('${view.device.id} · ${view.device.model}'),
            trailing: Text(view.device.firmware, style: theme.textTheme.labelMedium),
          ),
        ],
      ),
    );
  }
}

class _TrackingModeSection extends ConsumerWidget {
  const _TrackingModeSection({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final emergency = view.device.emergency;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          if (emergency)
            ListTile(
              leading: const Icon(AppIcons.emergency, color: AppColors.emergency),
              title: const Text('Emergency mode is active'),
              subtitle: const Text('Reporting every second until turned off on the device page.'),
              titleTextStyle: theme.textTheme.titleSmall?.copyWith(color: AppColors.emergency),
            ),
          RadioGroup<TrackingMode>(
            groupValue: view.device.trackingMode,
            onChanged: (m) {
              if (m == null) return;
              ref.read(devicesProvider.notifier).setTrackingMode(view.id, m);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${m.label} mode · updates every ${m.interval.inSeconds}s')),
              );
            },
            child: Column(
              children: [
                for (final m in TrackingMode.values.where((m) => m != TrackingMode.emergency))
                  RadioListTile<TrackingMode>(
                    key: Key('mode-${m.name}'),
                    value: m,
                    title: Text(m.label),
                    subtitle: Text(m.description),
                    secondary: Text('${m.interval.inSeconds}s', style: theme.textTheme.labelLarge),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: Text(
              'Simulation values. Faster modes give smoother live tracking but use more battery.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertSection extends ConsumerWidget {
  const _AlertSection({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = view.device.alertConfig;
    void save(AlertConfig c) =>
        ref.read(devicesProvider.notifier).updateDevice(view.device.copyWith(alertConfig: c));
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          if (view.type.isVehicle) ...[
            SwitchListTile(
              secondary: const Icon(AppIcons.overspeed),
              title: const Text('Overspeed'),
              subtitle: Text('Alert above ${cfg.speedLimit.round()} km/h'),
              value: cfg.overspeed,
              onChanged: (v) => save(cfg.copyWith(overspeed: v)),
            ),
            if (cfg.overspeed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Slider(
                  value: cfg.speedLimit,
                  min: 30,
                  max: 140,
                  divisions: 22,
                  label: '${cfg.speedLimit.round()} km/h',
                  onChanged: (v) => save(cfg.copyWith(speedLimit: v)),
                ),
              ),
          ],
          SwitchListTile(
            secondary: const Icon(AppIcons.geofence),
            title: const Text('Geofence enter / exit'),
            value: cfg.geofence,
            onChanged: (v) => save(cfg.copyWith(geofence: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.batteryLow),
            title: const Text('Low battery'),
            subtitle: const Text('Below 20%'),
            value: cfg.lowBattery,
            onChanged: (v) => save(cfg.copyWith(lowBattery: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.offline),
            title: const Text('Device offline'),
            value: cfg.offline,
            onChanged: (v) => save(cfg.copyWith(offline: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.emergency),
            title: const Text('SOS / emergency'),
            value: cfg.sos,
            onChanged: (v) => save(cfg.copyWith(sos: v)),
          ),
        ],
      ),
    );
  }
}

class _RemoveButton extends ConsumerWidget {
  const _RemoveButton({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      key: const Key('remove-device'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.emergency,
        side: const BorderSide(color: AppColors.emergency),
      ),
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
              FilledButton(
                key: const Key('remove-confirm'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
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
