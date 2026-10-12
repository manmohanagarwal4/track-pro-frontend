import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_style.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../data/models/enums.dart';
import '../../../domain/device_view.dart';
import '../../assets/presentation/asset_picker_sheet.dart';
import '../../geofences/application/geofences_controller.dart';
import '../../map/presentation/widgets/map_layers.dart';
import '../../map/presentation/widgets/tracker_map.dart';
import '../../settings/application/settings_controller.dart';
import '../application/devices_controller.dart';
import 'widgets/telemetry_grid.dart';

class DeviceDetailsScreen extends ConsumerWidget {
  const DeviceDetailsScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allDeviceViewsProvider);
    final view = ref.watch(deviceViewProvider(deviceId));
    if (view == null) {
      return Scaffold(
        appBar: AppBar(),
        body: all.isLoading && !all.hasValue
            ? const LoadingView(message: 'Loading device...')
            : all.hasError && !all.hasValue
                ? ErrorView(message: 'Unable to load device data.', onRetry: () => ref.invalidate(devicesProvider))
                : const EmptyView(
                    icon: AppIcons.devices,
                    title: 'Device not found',
                    message: 'This tracker may have been removed from your account.',
                  ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(view.name),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () => context.push(Routes.deviceShare(deviceId)),
            icon: const Icon(AppIcons.share),
          ),
          IconButton(
            tooltip: 'Device settings',
            onPressed: () => context.push(Routes.deviceSettings(deviceId)),
            icon: const Icon(AppIcons.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.huge),
        children: [
          ResponsiveCenter(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (view.status.isEmergency) ...[
                    _EmergencyBanner(view: view),
                    AppSpacing.gapMd,
                  ],
                  _HeaderCard(view: view),
                  AppSpacing.gapMd,
                  _MiniMap(view: view),
                  AppSpacing.gapMd,
                  _LocationCard(view: view),
                  const SectionHeader('Actions', padding: EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, AppSpacing.sm)),
                  _ActionsGrid(view: view),
                  const SectionHeader('Telemetry', padding: EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, AppSpacing.sm)),
                  view.device.location == null
                      ? const AppCard(child: Text('No telemetry received yet.'))
                      : TelemetryGrid(items: telemetryFor(view, ref.watch(settingsProvider.select((s) => s.unit)))),
                  const SectionHeader('Asset & tracker', padding: EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, AppSpacing.sm)),
                  _AssetCard(view: view),
                  AppSpacing.gapXl,
                  _EmergencyButton(view: view),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(settingsProvider.select((s) => s.unit));
    final loc = view.device.location;
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final online = view.status.isOnline;

    Widget stat(String label, Widget value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: muted),
              const SizedBox(height: 4),
              value,
            ],
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DeviceAvatar(view, size: 52),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(view.name, style: theme.textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    StatusBadge(view.status),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: view.speedKmh),
                    duration: const Duration(milliseconds: 600),
                    builder: (_, v, _) => Text(Fmt.speedValue(v, unit), style: AppTypography.metric.copyWith(fontSize: 32)),
                  ),
                  Text(
                    '${unit.speed} · ${loc == null ? '--' : GeoUtils.compass(loc.heading)}',
                    style: muted,
                  ),
                ],
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider()),
          Row(
            children: [
              stat('Battery', BatteryIndicator(view.battery)),
              stat(
                'GPS',
                Text(online && loc != null ? loc.telemetry.gpsSignal.label : 'No fix',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              stat(
                'Network',
                Row(
                  children: [
                    if (loc != null) SignalBars(online ? loc.telemetry.signal : SignalQuality.none),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(online && loc != null ? loc.telemetry.signal.label : 'Offline',
                          maxLines: 1, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              stat('Last Updated', TimeAgoText(view.lastUpdate, style: theme.textTheme.titleSmall)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMap extends ConsumerStatefulWidget {
  const _MiniMap({required this.view});

  final DeviceView view;

  @override
  ConsumerState<_MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends ConsumerState<_MiniMap> {
  final _controller = MapController();
  bool _ready = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.view;
    final pos = v.position;
    final trail = ref.watch(liveTrailsProvider.select((t) => t[v.id]));
    final fences = (ref.watch(geofencesProvider).value ?? const []).where((g) => g.appliesTo(v.id)).toList();
    if (pos == null) {
      return const AppCard(child: SizedBox(height: 120, child: Center(child: Text('Waiting for first GPS fix...'))));
    }
    return ClipRRect(
      borderRadius: AppRadius.lgAll,
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            TrackerMap(
              controller: _controller,
              devices: [v],
              selectedId: v.id,
              geofences: fences,
              initialCenter: pos,
              initialZoom: 14.5,
              clustering: false,
              showUserLocation: false,
              onMapReady: () => _ready = true,
              onSelectedPosition: (p) {
                if (_ready) _controller.move(p, _controller.camera.zoom);
              },
              layersBelowDevices: [
                if (trail != null && trail.length > 1)
                  RouteLayers(points: trail, color: StatusStyle.of(v.status), showEndpoints: false, width: 4),
              ],
            ),
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: FilledButton.tonalIcon(
                onPressed: () => context.go(Routes.mapFocus(v.id)),
                icon: const Icon(AppIcons.navigation, size: 16),
                label: const Text('Track Live'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends ConsumerWidget {
  const _LocationCard({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pos = view.position;
    final resolver = ref.read(placeResolverProvider);
    return AppCard(
      child: Row(
        children: [
          const IconBadge(icon: AppIcons.pin, color: AppColors.iris),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Location', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(pos == null ? 'Unknown' : resolver.describe(pos), style: theme.textTheme.titleSmall),
                if (pos != null)
                  Text(Fmt.coordinates(pos.latitude, pos.longitude),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: AppTypography.tabular,
                      )),
              ],
            ),
          ),
          if (pos != null)
            IconButton(
              tooltip: 'Copy coordinates',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: Fmt.coordinates(pos.latitude, pos.longitude)));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coordinates copied')));
              },
              icon: const Icon(AppIcons.copy, size: 18),
            ),
        ],
      ),
    );
  }
}

class _ActionsGrid extends StatelessWidget {
  const _ActionsGrid({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (AppIcons.navigation, 'Track Live', AppColors.moving, () => context.go(Routes.mapFocus(view.id))),
      (AppIcons.history, 'History', AppColors.iris, () => context.push(Routes.deviceHistory(view.id))),
      (AppIcons.trips, 'Trips', AppColors.signal, () => context.push(Routes.deviceTrips(view.id))),
      (AppIcons.geofence, 'Geofence', AppColors.warning, () => context.push(Routes.newGeofenceFor(view.id))),
      (AppIcons.settings, 'Settings', AppColors.stationary, () => context.push(Routes.deviceSettings(view.id))),
      (AppIcons.share, 'Share', AppColors.idle, () => context.push(Routes.deviceShare(view.id))),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 560 ? 6 : 3;
      final w = (c.maxWidth - (cols - 1) * AppSpacing.md) / cols;
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (final a in actions)
            SizedBox(
              width: w,
              child: AppCard(
                key: Key('action-${a.$2}'),
                onTap: a.$4,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Column(
                  children: [
                    IconBadge(icon: a.$1, color: a.$3, size: 38),
                    AppSpacing.gapSm,
                    Text(a.$2, style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _AssetCard extends ConsumerWidget {
  const _AssetCard({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final d = view.device;
    final unit = ref.watch(settingsProvider.select((s) => s.unit));
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(k, style: muted)),
              Flexible(child: Text(v, style: theme.textTheme.bodyMedium, textAlign: TextAlign.right)),
            ],
          ),
        );

    Future<void> changeAsset() async {
      final pick = await showAssetPicker(context, deviceId: d.id, currentAssetId: d.assetId);
      if (pick == null) return;
      await ref.read(devicesProvider.notifier).assignAsset(d.id, pick.unassign ? null : pick.assetId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pick.unassign ? 'Asset unassigned' : 'Asset assigned')),
        );
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: AppIcons.asset(view.type), color: theme.colorScheme.primary),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned Asset', style: muted),
                    Text(view.asset?.name ?? 'Unassigned tracker', style: theme.textTheme.titleSmall),
                  ],
                ),
              ),
              TextButton(
                key: const Key('change-asset'),
                onPressed: changeAsset,
                child: Text(view.isAssigned ? 'Change' : 'Assign'),
              ),
            ],
          ),
          if (view.driver != null) ...[
            AppSpacing.gapMd,
            InkWell(
              borderRadius: AppRadius.mdAll,
              onTap: () => context.push(Routes.driver(view.driver!.id)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                    child: Text(view.driver!.initials,
                        style: theme.textTheme.labelLarge?.copyWith(color: AppColors.warning)),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Driver', style: muted),
                        Text(view.driver!.name, style: theme.textTheme.titleSmall),
                      ],
                    ),
                  ),
                  Icon(AppIcons.chevronRight, size: 18, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ],
          const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Divider()),
          row('Device ID', d.id),
          if (view.registration != null) row('Registration', view.registration!),
          row('Type', view.type.label),
          row('IMEI', d.imei),
          row('Model', '${d.model} · ${d.firmware}'),
          row('Tracking mode', '${d.trackingMode.label} · every ${d.updateInterval.inSeconds}s'),
          if (view.type.isVehicle) row('Odometer', Fmt.distance(d.odometerKm, unit, decimals: 0)),
          row('Distance today', Fmt.distance(d.tripDistanceKm, unit, decimals: 1)),
          row('Added', Fmt.date(d.addedAt)),
        ],
      ),
    );
  }
}

class _EmergencyBanner extends ConsumerWidget {
  const _EmergencyBanner({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(color: AppColors.emergency, borderRadius: AppRadius.lgAll),
      child: Row(
        children: [
          const StatusDot(color: Colors.white, pulse: true, size: 10),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EMERGENCY MODE',
                    style: theme.textTheme.titleSmall?.copyWith(color: Colors.white, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(
                  'Tracking frequency increased to every second. Emergency alert generated. Device highlighted on map.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyButton extends ConsumerStatefulWidget {
  const _EmergencyButton({required this.view});

  final DeviceView view;

  @override
  ConsumerState<_EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends ConsumerState<_EmergencyButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    final active = widget.view.status.isEmergency;
    if (!active) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(AppIcons.emergency, color: AppColors.emergency, size: 32),
          title: const Text('Activate emergency mode?'),
          content: Text(
              '${widget.view.name} will report its location every second and an emergency alert will be sent to all account members.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Activate'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    await ref.read(devicesProvider.notifier).setEmergency(widget.view.id, !active);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.view.status.isEmergency;
    final child = _busy
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(active ? 'Turn off emergency mode' : 'Activate emergency mode');
    return active
        ? OutlinedButton.icon(
            key: const Key('emergency-toggle'),
            onPressed: _busy ? null : _toggle,
            icon: const Icon(AppIcons.close, size: 18),
            label: child,
          )
        : FilledButton.icon(
            key: const Key('emergency-toggle'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.emergency, foregroundColor: Colors.white),
            onPressed: _busy ? null : _toggle,
            icon: const Icon(AppIcons.emergency, size: 18),
            label: child,
          );
  }
}
