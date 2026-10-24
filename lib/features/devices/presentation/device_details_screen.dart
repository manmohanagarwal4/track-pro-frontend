import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/providers.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_shadows.dart';
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
import '../../alerts/application/alerts_controller.dart';
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
    const label = EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, 0);
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: AppSpacing.huge + MediaQuery.paddingOf(context).bottom),
            children: [
              _MapHeader(view: view),
              ResponsiveCenter(
                child: Padding(
                  padding: AppSpacing.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 14,
                    children: [
                      if (view.status.isEmergency) _EmergencyBanner(view: view),
                      _HeaderRow(view: view),
                      _WhereRow(view: view),
                      _StateCallout(view: view),
                      _StatTiles(view: view),
                      _ActionsGrid(view: view),
                      const SectionHeader('Telemetry', padding: label),
                      view.device.location == null
                          ? AppCard(
                              padding: AppSpacing.cardCompact,
                              child: Text(
                                'No telemetry received yet.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.tones.neutral500),
                              ),
                            )
                          : TelemetryGrid(items: telemetryFor(view, ref.watch(settingsProvider.select((s) => s.unit)))),
                      const SectionHeader('Asset & tracker', padding: label),
                      _AssetCard(view: view),
                      const SectionHeader('Recent events', padding: label),
                      _RecentEvents(view: view),
                      if (!view.status.isEmergency) ...[AppSpacing.gapXs, _EmergencyButton(view: view)],
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Pinned so it stays reachable after the map header scrolls away.
          Positioned(
            top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
            left: AppSpacing.md,
            child: _Glass(
              child: SizedBox(width: 44, child: BackButton(color: Theme.of(context).colorScheme.onSurface)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass control floating over the map header.
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.height = 44, this.padding = EdgeInsets.zero});

  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.tones.glass,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.hairline(Theme.of(context).brightness),
      ),
      child: child,
    );
  }
}

class _MapHeader extends ConsumerStatefulWidget {
  const _MapHeader({required this.view});

  final DeviceView view;

  @override
  ConsumerState<_MapHeader> createState() => _MapHeaderState();
}

class _MapHeaderState extends ConsumerState<_MapHeader> {
  final _controller = MapController();
  bool _ready = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final v = widget.view;
    final pos = v.position;
    final loc = v.device.location;
    final trail = ref.watch(liveTrailsProvider.select((t) => t[v.id]));
    final fences = (ref.watch(geofencesProvider).value ?? const []).where((g) => g.appliesTo(v.id)).toList();
    final top = MediaQuery.paddingOf(context).top + AppSpacing.sm;
    final onGlass = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface);

    return SizedBox(
      height: 270,
      child: Stack(
        children: [
          // The map dissolves into the page's backdrop at its bottom edge.
          Positioned.fill(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white, Color(0x00FFFFFF)],
                stops: [0, 0.74, 1],
              ).createShader(r),
              child: pos == null
                ? ColoredBox(
                    color: tones.neutral900,
                    child: Center(
                      child: Text(
                        'Waiting for first GPS fix...',
                        style: theme.textTheme.bodySmall?.copyWith(color: tones.neutral500),
                      ),
                    ),
                  )
                : TrackerMap(
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
            ),
          ),
          if (loc != null)
            Positioned(
              top: top + 8,
              right: AppSpacing.md,
              child: _Glass(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${v.status.isOnline ? loc.telemetry.gpsSignal.label : 'Last fix'} · ±${loc.accuracy.round()} m',
                  style: onGlass,
                ),
              ),
            ),
          if (pos != null)
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: _Glass(
                height: 40,
                child: TextButton.icon(
                  onPressed: () => context.go(Routes.mapFocus(v.id)),
                  icon: Icon(AppIcons.navigation, size: 16, color: tones.accent300),
                  label: Text(
                    'Track Live',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        DeviceAvatar(view, size: 52),
        AppSpacing.gapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                view.name,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                view.device.model,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: context.tones.neutral500),
              ),
            ],
          ),
        ),
        AppSpacing.gapSm,
        StatusBadge(view.status),
      ],
    );
  }
}

class _WhereRow extends ConsumerWidget {
  const _WhereRow({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.tones.neutral300);
    final pos = view.position;
    return Row(
      children: [
        Icon(AppIcons.pin, size: 16, color: context.tones.neutral300),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            pos == null ? 'Location unknown' : ref.read(placeResolverProvider).describe(pos),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TimeAgoText(view.lastUpdate, prefix: ' · ', style: style),
      ],
    );
  }
}

/// Sleeping / offline info callout (accent900 tile).
class _StateCallout extends StatelessWidget {
  const _StateCallout({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final d = view.device;
    final String text;
    final IconData icon;
    if (!view.status.isOnline) {
      icon = AppIcons.offline;
      text =
          'Offline · last seen ${view.lastUpdate == null ? 'never' : Fmt.timeAgo(view.lastUpdate!)}. '
          'Commands wait in a queue until it reconnects.';
    } else if (d.trackingMode == TrackingMode.sleep) {
      icon = AppIcons.moon;
      text = 'Sleeping · ${d.trackingMode.description.toLowerCase()}. Commands wait in a queue until then.';
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: tones.accent900, borderRadius: AppRadius.mdAll),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tones.accent300),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13))),
        ],
      ),
    );
  }
}

class _StatTiles extends ConsumerWidget {
  const _StatTiles({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final unit = ref.watch(settingsProvider.select((s) => s.unit));
    final loc = view.device.location;
    final online = view.status.isOnline;
    final value = theme.textTheme.titleLarge?.copyWith(fontFeatures: AppTypography.tabular);
    final label = theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: tones.neutral500);
    final signal = online && loc != null ? loc.telemetry.signal : SignalQuality.none;
    final barColor = signal.bars >= 3
        ? tones.ok
        : signal.bars >= 2
        ? tones.warn
        : tones.crit;

    Widget tile(Widget top, String caption) => Expanded(
      child: AppCard(
        radius: AppRadius.mdAll,
        padding: AppSpacing.cardCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 28,
              child: Align(alignment: Alignment.bottomLeft, child: top),
            ),
            const SizedBox(height: 2),
            Text(caption, style: label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );

    return Row(
      spacing: AppSpacing.sm,
      children: [
        tile(
          Text(
            view.battery == null ? '--' : '${view.battery}%',
            style: value?.copyWith(color: tones.tone(StatusStyle.battery(view.battery))),
          ),
          'Battery',
        ),
        tile(
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 3,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 5,
                  height: 8.0 + i * 5,
                  decoration: BoxDecoration(
                    color: i < signal.bars ? barColor : tones.neutral700,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
          online && loc != null ? '${signal.label} · 4G' : 'Offline',
        ),
        tile(
          TweenAnimationBuilder<double>(
            tween: Tween(end: view.speedKmh),
            duration: const Duration(milliseconds: 600),
            builder: (_, v, _) => Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: Fmt.speedValue(v, unit)),
                  TextSpan(text: ' ${unit.speed}', style: label),
                ],
              ),
              style: value,
            ),
          ),
          'Speed · ${loc == null ? '--' : GeoUtils.compass(loc.heading)}',
        ),
      ],
    );
  }
}

class _ActionsGrid extends StatelessWidget {
  const _ActionsGrid({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final actions = [
      (AppIcons.navigation, 'Track Live', () => context.go(Routes.mapFocus(view.id))),
      (AppIcons.history, 'History', () => context.push(Routes.deviceHistory(view.id))),
      (AppIcons.trips, 'Trips', () => context.push(Routes.deviceTrips(view.id))),
      (AppIcons.geofence, 'Geofence', () => context.push(Routes.newGeofenceFor(view.id))),
      (AppIcons.settings, 'Settings', () => context.push(Routes.deviceSettings(view.id))),
      (AppIcons.share, 'Share', () => context.push(Routes.deviceShare(view.id))),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 560 ? 6 : 3;
        final w = (c.maxWidth - (cols - 1) * AppSpacing.sm) / cols;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final a in actions)
              SizedBox(
                width: w,
                child: AppCard(
                  key: Key('action-${a.$2}'),
                  onTap: a.$3,
                  radius: AppRadius.mdAll,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  child: Column(
                    children: [
                      Icon(a.$1, size: 22, color: tones.accent300),
                      const SizedBox(height: 6),
                      Text(a.$2, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AssetCard extends ConsumerWidget {
  const _AssetCard({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final d = view.device;
    final pos = view.position;
    final unit = ref.watch(settingsProvider.select((s) => s.unit));
    final keyStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.neutral400);
    final valueStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: theme.colorScheme.onSurface);

    Future<void> changeAsset() async {
      final pick = await showAssetPicker(context, deviceId: d.id, currentAssetId: d.assetId);
      if (pick == null) return;
      await ref.read(devicesProvider.notifier).assignAsset(d.id, pick.unassign ? null : pick.assetId);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(pick.unassign ? 'Asset unassigned' : 'Asset assigned')));
      }
    }

    final rows = <(IconData, String, Widget, VoidCallback?)>[
      (
        AppIcons.pin,
        'Current Location',
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                pos == null ? 'Unknown' : Fmt.coordinates(pos.latitude, pos.longitude),
                textAlign: TextAlign.right,
                style: valueStyle?.copyWith(fontFeatures: AppTypography.tabular),
              ),
            ),
            if (pos != null)
              IconButton(
                tooltip: 'Copy coordinates',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: Fmt.coordinates(pos.latitude, pos.longitude)));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coordinates copied')));
                },
                icon: Icon(AppIcons.copy, size: 16, color: tones.neutral400),
              ),
          ],
        ),
        null,
      ),
      (
        AppIcons.asset(view.type),
        'Assigned Asset',
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                view.asset?.name ?? 'Unassigned tracker',
                textAlign: TextAlign.right,
                style: valueStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              key: const Key('change-asset'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: changeAsset,
              child: Text(view.isAssigned ? 'Change' : 'Assign'),
            ),
          ],
        ),
        null,
      ),
      if (view.driver != null)
        (
          AppIcons.driver,
          'Driver',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(view.driver!.name, style: valueStyle),
              const SizedBox(width: 4),
              Icon(AppIcons.chevronRight, size: 16, color: tones.neutral600),
            ],
          ),
          () => context.push(Routes.driver(view.driver!.id)),
        ),
      (AppIcons.tracker, 'Device ID', Text(d.id, style: valueStyle), null),
      if (view.registration != null)
        (AppIcons.fleet, 'Registration', Text(view.registration!, style: valueStyle), null),
      (AppIcons.assets, 'Type', Text(view.type.label, style: valueStyle), null),
      (AppIcons.qr, 'IMEI', Text(d.imei, style: valueStyle), null),
      (AppIcons.tracker, 'Model', Text('${d.model} · ${d.firmware}', style: valueStyle), null),
      (
        AppIcons.timer,
        'Tracking mode',
        Text('${d.trackingMode.label} · every ${d.updateInterval.inSeconds}s', style: valueStyle),
        null,
      ),
      if (view.type.isVehicle)
        (AppIcons.odometer, 'Odometer', Text(Fmt.distance(d.odometerKm, unit, decimals: 0), style: valueStyle), null),
      (
        AppIcons.route,
        'Distance today',
        Text(Fmt.distance(d.tripDistanceKm, unit, decimals: 1), style: valueStyle),
        null,
      ),
      (AppIcons.calendar, 'Added', Text(Fmt.date(d.addedAt), style: valueStyle), null),
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            InkWell(
              onTap: rows[i].$4,
              child: Container(
                constraints: const BoxConstraints(minHeight: 42),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: i < rows.length - 1
                    ? BoxDecoration(
                        border: Border(bottom: BorderSide(color: tones.divider)),
                      )
                    : null,
                child: Row(
                  children: [
                    Icon(rows[i].$1, size: 17, color: tones.neutral400),
                    const SizedBox(width: 10),
                    Text(rows[i].$2, style: keyStyle),
                    AppSpacing.gapMd,
                    Expanded(
                      child: Align(alignment: Alignment.centerRight, child: rows[i].$3),
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

class _RecentEvents extends ConsumerWidget {
  const _RecentEvents({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final events = (ref.watch(alertsProvider).value ?? const []).where((a) => a.deviceId == view.id).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final base = theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: theme.colorScheme.onSurface);
    final muted = base?.copyWith(color: tones.neutral500);
    if (events.isEmpty) {
      return AppCard(
        radius: AppRadius.mdAll,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text('No recent events.', style: muted),
      );
    }
    final time = DateFormat('HH:mm');
    return Column(
      spacing: 6,
      children: [
        for (final e in events.take(5))
          AppCard(
            radius: AppRadius.mdAll,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(time.format(e.timestamp), style: muted?.copyWith(fontFeatures: AppTypography.tabular)),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(e.title, style: base, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (e.value != null) ...[AppSpacing.gapSm, Text(e.value!, style: muted)],
              ],
            ),
          ),
      ],
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({required this.view});

  final DeviceView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: tones.crit.withValues(alpha: 0.45)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tones.critBg, Color.lerp(tones.critBg, context.tones.groundBase, 0.55)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: tones.crit,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: tones.crit.withValues(alpha: 0.25), spreadRadius: 5)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'EMERGENCY MODE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: tones.critInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tracking frequency increased to every second. Emergency alert generated. Device highlighted on map.',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.neutral300),
          ),
          const SizedBox(height: 12),
          _EmergencyButton(view: view),
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
        builder: (ctx) {
          final tones = ctx.tones;
          return AlertDialog(
            icon: Icon(AppIcons.emergency, color: tones.crit, size: 32),
            title: const Text('Activate emergency mode?'),
            content: Text(
              '${widget.view.name} will report its location every second and an emergency alert will be sent to all account members.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tones.crit),
                  foregroundColor: tones.critInk,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Activate'),
              ),
            ],
          );
        },
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    await ref.read(devicesProvider.notifier).setEmergency(widget.view.id, !active);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final active = widget.view.status.isEmergency;
    final child = _busy
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(active ? 'Turn off emergency mode' : 'Activate emergency mode');
    return OutlinedButton.icon(
      key: const Key('emergency-toggle'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: tones.crit),
        foregroundColor: tones.critInk,
        backgroundColor: active ? tones.crit.withValues(alpha: 0.14) : AppColors.transparent,
      ),
      onPressed: _busy ? null : _toggle,
      icon: Icon(active ? AppIcons.close : AppIcons.emergency, size: 18),
      label: child,
    );
  }
}
