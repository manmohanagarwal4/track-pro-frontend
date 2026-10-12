import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/di/providers.dart';
import '../../../core/routing/routes.dart';
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
    final scheme = Theme.of(context).colorScheme;
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
                  RouteLayers(
                    points: trail,
                    color: StatusStyle.of(selected!.status),
                    showEndpoints: false,
                    width: 4,
                  ),
              ],
            ),
          ),
          // Top: search + filters
          Positioned(
            left: 0,
            right: 0,
            top: top + AppSpacing.sm,
            child: Column(
              children: [
                Padding(
                  padding: AppSpacing.screen,
                  child: Material(
                    color: scheme.surface,
                    borderRadius: AppRadius.lgAll,
                    elevation: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.lgAll,
                        boxShadow: AppShadows.floating(Theme.of(context).brightness),
                      ),
                      child: InkWell(
                        borderRadius: AppRadius.lgAll,
                        onTap: () => _searchSheet(views),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                          child: Row(
                            children: [
                              Icon(AppIcons.search, size: 20, color: scheme.onSurfaceVariant),
                              AppSpacing.gapMd,
                              Expanded(
                                child: Text('Search ${views.length} devices',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                              ),
                              Text('${filtered.where((v) => v.status.isMoving).length} moving',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.primary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapSm,
                ChipFilterBar<StatusFilter>(
                  values: StatusFilter.values,
                  selected: _filter,
                  label: (s) => s.label,
                  onSelected: (s) => setState(() => _filter = s),
                ),
              ],
            ),
          ),
          // Right: controls
          Positioned(
            right: AppSpacing.lg,
            top: top + 128,
            child: Column(
              children: [
                MapButton(icon: AppIcons.layers, tooltip: 'Map layers', onPressed: _layersSheet),
                AppSpacing.gapSm,
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
          // Bottom: selected device
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
    final unit = ref.watch(settingsProvider.select((s) => s.unit));
    final place = view.position == null ? 'Location unavailable' : ref.read(placeResolverProvider).describe(view.position!);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.xlAll,
              boxShadow: AppShadows.floating(theme.brightness),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    DeviceAvatar(view, size: 44),
                    AppSpacing.gapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(view.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          StatusBadge(view.status, compact: true),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(Fmt.speedValue(view.speedKmh, unit), style: AppTypography.metric),
                        Text(unit.speed, style: muted),
                      ],
                    ),
                    IconButton(onPressed: onClose, icon: const Icon(AppIcons.close, size: 20)),
                  ],
                ),
                AppSpacing.gapMd,
                Row(
                  children: [
                    Icon(AppIcons.pin, size: 15, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(child: Text(place, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    BatteryIndicator(view.battery),
                    AppSpacing.gapMd,
                    TimeAgoText(view.lastUpdate, style: muted, short: true),
                    AppSpacing.gapSm,
                  ],
                ),
                AppSpacing.gapMd,
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        key: const Key('map-follow'),
                        onPressed: onFollow,
                        icon: Icon(following ? AppIcons.check : AppIcons.follow, size: 18),
                        label: Text(following ? 'Following' : 'Follow'),
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                      ),
                    ),
                    AppSpacing.gapSm,
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(Routes.deviceHistory(view.id)),
                        icon: const Icon(AppIcons.history, size: 18),
                        label: const Text('History'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                      ),
                    ),
                    AppSpacing.gapSm,
                    Expanded(
                      child: FilledButton(
                        key: const Key('map-details'),
                        onPressed: () => context.push(Routes.device(view.id)),
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                        child: const Text('Details'),
                      ),
                    ),
                    AppSpacing.gapSm,
                  ],
                ),
              ],
            ),
          ),
        ),
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
