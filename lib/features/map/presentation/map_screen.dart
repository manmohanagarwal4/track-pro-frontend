import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

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
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../data/mock/geo/ncr_geo.dart';
import '../../../data/models/enums.dart';
import '../../../domain/device_query.dart';
import '../../../domain/device_status_engine.dart';
import '../../../domain/device_view.dart';
import '../../devices/application/devices_controller.dart';
import '../../devices/presentation/widgets/device_card.dart';
import '../../geofences/application/geofences_controller.dart';
import '../../settings/application/settings_controller.dart';
import 'widgets/map_layers.dart';
import 'widgets/tracker_map.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.focusDeviceId});

  final String? focusDeviceId;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin, AnimatedMapMixin<MapScreen> {
  final _controller = MapController();
  String? _selectedId;
  bool _follow = false;
  StatusFilter _filter = StatusFilter.all;
  bool _ready = false;

  @override
  MapController get mapController => _controller;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.focusDeviceId;
    _follow = widget.focusDeviceId != null;
  }

  @override
  void didUpdateWidget(MapScreen old) {
    super.didUpdateWidget(old);
    if (widget.focusDeviceId != null && widget.focusDeviceId != old.focusDeviceId) {
      _select(widget.focusDeviceId!, follow: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(String id, {bool follow = false}) {
    setState(() {
      _selectedId = id;
      _follow = follow;
    });
    final pos = ref.read(deviceViewProvider(id))?.position;
    if (pos != null && _ready) {
      animateCamera(pos, _controller.camera.zoom < 13.5 ? 14.5 : _controller.camera.zoom);
    }
  }

  void _fitAll(List<DeviceView> views) {
    final pts = [for (final v in views) if (v.position != null) v.position!];
    if (pts.length < 2) return;
    setState(() => _follow = false);
    _controller.fitCamera(CameraFit.coordinates(
      coordinates: pts,
      padding: const EdgeInsets.fromLTRB(60, 140, 60, 200),
      maxZoom: 15,
    ));
  }

  void _onSelectedFrame(LatLng p) {
    if (!_follow || !_ready) return;
    final c = _controller.camera;
    if (GeoUtils.distanceMeters(c.center, p) > 0.5) _controller.move(p, c.zoom);
  }

  Future<void> _searchSheet(List<DeviceView> views) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _DeviceSearchSheet(views: views),
    );
    if (id != null) _select(id, follow: true);
  }

  void _layersSheet() {
    showModalBottomSheet<void>(context: context, builder: (_) => const _LayersSheet());
  }

  @override
  Widget build(BuildContext context) {
    final viewsAsync = ref.watch(deviceViewsProvider);
    final settings = ref.watch(settingsProvider);
    final fences = settings.showGeofences ? (ref.watch(geofencesProvider).value ?? const []) : const <Never>[];
    final views = viewsAsync.value ?? const <DeviceView>[];
    final filtered = views.where((v) => DeviceStatusEngine.matchesFilter(v.status, _filter)).toList();
    final selected = _selectedId == null ? null : ref.watch(deviceViewProvider(_selectedId!));
    final trail = selected != null && settings.showTrails
        ? ref.watch(liveTrailsProvider.select((t) => t[selected.id]))
        : null;
    final theme = Theme.of(context);
    final tones = context.tones;
    final ground = context.tones.groundBase;
    final top = MediaQuery.paddingOf(context).top;

    if (!viewsAsync.hasValue) {
      return Scaffold(
        body: AsyncView<List<DeviceView>>(
          value: viewsAsync,
          onRetry: () => ref.invalidate(devicesProvider),
          loadingMessage: 'Loading map...',
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }

    final focus = widget.focusDeviceId == null ? null : ref.read(deviceViewProvider(widget.focusDeviceId!));
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: TrackerMap(
              controller: _controller,
              devices: filtered,
              selectedId: _selectedId,
              geofences: fences,
              onDeviceTap: (id) => _select(id),
              initialCenter: focus?.position,
              initialZoom: focus?.position != null ? 14.5 : null,
              onSelectedPosition: _onSelectedFrame,
              onTap: (_, _) => setState(() {
                _selectedId = null;
                _follow = false;
              }),
              onMapReady: () => _ready = true,
              onPositionChanged: (camera, gesture) {
                if (gesture && _follow) setState(() => _follow = false);
              },
              layersBelowDevices: [
                if (trail != null && trail.length > 1)
                  RouteLayers(points: trail, showEndpoints: false, width: 4),
              ],
            ),
          ),
          // Fade from the ground behind the top controls.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top + 150,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ground, ground.withAlpha(0)],
                  ),
                ),
              ),
            ),
          ),
          // Top: search + layers, then status filters
          Positioned(
            left: 0,
            right: 0,
            top: top + AppSpacing.sm,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: MapGlass(
                          child: InkWell(
                            borderRadius: AppRadius.lgAll,
                            onTap: () => _searchSheet(views),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              child: Row(
                                children: [
                                  Icon(AppIcons.search, size: 18, color: tones.neutral500),
                                  AppSpacing.gapSm,
                                  Expanded(
                                    child: Text(
                                      'Search ${views.length} devices',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.neutral500),
                                    ),
                                  ),
                                  Text(
                                    '${filtered.where((v) => v.status.isMoving).length} moving',
                                    style: theme.textTheme.labelMedium?.copyWith(color: tones.accent300),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapSm,
                      MapButton(icon: AppIcons.layers, tooltip: 'Map layers', onPressed: _layersSheet),
                    ],
                  ),
                ),
                AppSpacing.gapSm,
                _StatusChips(
                  selected: _filter,
                  counts: {
                    for (final f in StatusFilter.values)
                      f: views.where((v) => DeviceStatusEngine.matchesFilter(v.status, f)).length,
                  },
                  onSelected: (s) => setState(() => _filter = s),
                ),
              ],
            ),
          ),
          // Right: controls
          Positioned(
            right: AppSpacing.md,
            top: top + 112,
            child: Column(
              children: [
                MapButton(icon: AppIcons.zoomIn, tooltip: 'Zoom in', onPressed: () => zoomBy(1)),
                AppSpacing.gapSm,
                MapButton(icon: AppIcons.zoomOut, tooltip: 'Zoom out', onPressed: () => zoomBy(-1)),
                AppSpacing.gapSm,
                MapButton(
                  icon: AppIcons.locate,
                  tooltip: 'My location',
                  onPressed: () {
                    setState(() => _follow = false);
                    animateCamera(NcrGeo.userLocation, 14);
                  },
                ),
                AppSpacing.gapSm,
                MapButton(icon: AppIcons.crosshair, tooltip: 'Show all devices', onPressed: () => _fitAll(filtered)),
              ],
            ),
          ),
          // Bottom: selected device sheet (runs under the glass nav bar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSwitcher(
              duration: AppDurations.medium,
              transitionBuilder: (child, a) => SlideTransition(
                position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(a),
                child: child,
              ),
              child: selected == null
                  ? const SizedBox.shrink()
                  : _SelectedDevicePanel(
                      key: ValueKey(selected.id),
                      view: selected,
                      following: _follow,
                      onFollow: () {
                        setState(() => _follow = !_follow);
                        if (_follow && selected.position != null) {
                          animateCamera(selected.position!, _controller.camera.zoom.clamp(14, 17));
                        }
                      },
                      onClose: () => setState(() {
                        _selectedId = null;
                        _follow = false;
                      }),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass status filter pills: 7px status dot, label, count.
class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.selected, required this.counts, required this.onSelected});

  final StatusFilter selected;
  final Map<StatusFilter, int> counts;
  final ValueChanged<StatusFilter> onSelected;

  Color _dot(BuildContext context, StatusFilter f) {
    final tones = context.tones;
    return switch (f) {
      StatusFilter.all => Theme.of(context).colorScheme.primary,
      StatusFilter.online || StatusFilter.moving => tones.ok,
      StatusFilter.offline => tones.neutral500,
      StatusFilter.idle => tones.tone(AppColors.idle),
      StatusFilter.alert => tones.warn,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: StatusFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final f = StatusFilter.values[i];
          final shape = StadiumBorder(
            side: BorderSide(color: f == selected ? theme.colorScheme.primary : tones.divider),
          );
          return Material(
            color: tones.glass,
            shape: shape,
            child: InkWell(
              customBorder: shape,
              onTap: () => onSelected(f),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: _dot(context, f), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(f.label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: theme.colorScheme.onSurface)),
                    const SizedBox(width: 5),
                    Text(
                      '${counts[f] ?? 0}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: tones.neutral500,
                        fontFeatures: AppTypography.tabular,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SelectedDevicePanel extends ConsumerWidget {
  const _SelectedDevicePanel({
    super.key,
    required this.view,
    required this.following,
    required this.onFollow,
    required this.onClose,
  });

  final DeviceView view;
  final bool following;
  final VoidCallback onFollow;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final unit = ref.watch(settingsProvider.select((s) => s.unit));
    final place = view.position == null ? 'Location unavailable' : ref.read(placeResolverProvider).describe(view.position!);
    final location = view.device.location;
    final telemetry = location?.telemetry;
    final hasGps = telemetry != null && telemetry.gpsSignal != SignalQuality.none;
    final value = theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500, fontFeatures: AppTypography.tabular);
    final bottom = MediaQuery.paddingOf(context).bottom;
    const buttonSize = Size(0, 44);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 10, AppSpacing.lg, 14 + bottom),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.sheet,
            boxShadow: AppShadows.floating(theme.brightness),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: tones.neutral700, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              AppSpacing.gapMd,
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          view.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        TimeAgoText(
                          view.lastUpdate,
                          prefix: '$place · ',
                          short: true,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.neutral400),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapSm,
                  StatusBadge(view.status, compact: true),
                  IconButton(
                    onPressed: onClose,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(AppIcons.close, size: 20, color: tones.neutral400),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Stat(
                    label: 'Speed',
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: Fmt.speedValue(view.speedKmh, unit)),
                        TextSpan(
                          text: ' ${unit.speed}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: tones.neutral500),
                        ),
                      ]),
                      style: value,
                    ),
                  ),
                  _Stat(
                    label: 'Battery',
                    child: Text(
                      view.battery == null ? '--' : '${view.battery}%',
                      style: value?.copyWith(color: tones.tone(StatusStyle.battery(view.battery))),
                    ),
                  ),
                  _Stat(
                    label: telemetry?.signal.label ?? 'No data',
                    child: SizedBox(
                      height: 20,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: SignalBars(telemetry?.signal ?? SignalQuality.none),
                      ),
                    ),
                  ),
                  _Stat(
                    label: location == null ? 'No fix' : '± ${Fmt.meters(location.accuracy)}',
                    child: Text(location == null ? '--' : (hasGps ? 'GPS' : 'Cell'), style: value),
                  ),
                ],
              ),
              AppSpacing.gapLg,
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('map-follow'),
                      onPressed: onFollow,
                      icon: Icon(following ? AppIcons.check : AppIcons.follow, size: 18),
                      label: Text(following ? 'Following' : 'Follow'),
                      style: FilledButton.styleFrom(minimumSize: buttonSize),
                    ),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(Routes.deviceHistory(view.id)),
                      icon: const Icon(AppIcons.history, size: 18),
                      label: const Text('History'),
                      style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                    ),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('map-details'),
                      onPressed: () => context.push(Routes.device(view.id)),
                      style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                      child: const Text('Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: context.tones.neutral500),
          ),
        ],
      ),
    );
  }
}

class _DeviceSearchSheet extends StatefulWidget {
  const _DeviceSearchSheet({required this.views});

  final List<DeviceView> views;

  @override
  State<_DeviceSearchSheet> createState() => _DeviceSearchSheetState();
}

class _DeviceSearchSheetState extends State<_DeviceSearchSheet> {
  String _text = '';

  @override
  Widget build(BuildContext context) {
    final list = DeviceQuery(text: _text, sort: DeviceSort.name).apply(widget.views);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: AppSpacing.screen,
            child: TextField(
              autofocus: true,
              onChanged: (t) => setState(() => _text = t),
              decoration: const InputDecoration(
                hintText: 'Find a device, plate or driver',
                prefixIcon: Icon(AppIcons.search, size: 20),
              ),
            ),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: list.isEmpty
                ? const EmptyView(icon: AppIcons.search, title: 'No matches', message: 'Try another name or ID.')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => AppSpacing.gapSm,
                    itemBuilder: (_, i) => DeviceCard(
                      view: list[i],
                      dense: true,
                      onTap: () => Navigator.pop(context, list[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LayersSheet extends ConsumerWidget {
  const _LayersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final update = ref.read(settingsProvider.notifier).update;
    final service = ref.watch(mapServiceProvider);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Map layers', style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(service.name),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.devices),
            title: const Text('Cluster nearby devices'),
            value: s.clustering,
            onChanged: (v) => update((x) => x.copyWith(clustering: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.route),
            title: const Text('Show live trail'),
            value: s.showTrails,
            onChanged: (v) => update((x) => x.copyWith(showTrails: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.geofence),
            title: const Text('Show geofences'),
            value: s.showGeofences,
            onChanged: (v) => update((x) => x.copyWith(showGeofences: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.pin),
            title: const Text('Show place labels'),
            value: s.showMapLabels,
            onChanged: (v) => update((x) => x.copyWith(showMapLabels: v)),
          ),
          AppSpacing.gapMd,
        ],
      ),
    );
  }
}
