import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/mock/geo/ncr_geo.dart';
import '../../../../data/models/geofence.dart';
import '../../../../domain/device_view.dart';
import '../../../settings/application/settings_controller.dart';
import 'animated_devices_layer.dart';
import 'device_marker.dart';
import 'map_layers.dart';

/// The app's map widget. Base map comes from [MapService]; TrackPro content
/// (devices, geofences, routes) is layered on top.
class TrackerMap extends ConsumerWidget {
  const TrackerMap({
    super.key,
    required this.controller,
    this.devices = const [],
    this.selectedId,
    this.onDeviceTap,
    this.geofences = const [],
    this.highlightGeofenceId,
    this.route,
    this.routeColor,
    this.layersBelowDevices = const [],
    this.layersAboveDevices = const [],
    this.initialCenter,
    this.initialZoom,
    this.initialFit,
    this.onTap,
    this.onSelectedPosition,
    this.onPositionChanged,
    this.onMapReady,
    this.interactive = true,
    this.showUserLocation = true,
    this.clustering,
  });

  final MapController controller;
  final List<DeviceView> devices;
  final String? selectedId;
  final ValueChanged<String>? onDeviceTap;
  final List<Geofence> geofences;
  final String? highlightGeofenceId;
  final List<LatLng>? route;
  final Color? routeColor;
  final List<Widget> layersBelowDevices;
  final List<Widget> layersAboveDevices;
  final LatLng? initialCenter;
  final double? initialZoom;
  final CameraFit? initialFit;
  final TapCallback? onTap;
  final ValueChanged<LatLng>? onSelectedPosition;
  final PositionCallback? onPositionChanged;
  final VoidCallback? onMapReady;
  final bool interactive;
  final bool showUserLocation;
  final bool? clustering;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(mapServiceProvider);
    final settings = ref.watch(settingsProvider);
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter ?? service.defaultCenter,
        initialZoom: initialZoom ?? service.defaultZoom,
        initialCameraFit: initialFit,
        minZoom: service.minZoom,
        maxZoom: service.maxZoom,
        backgroundColor: service.backgroundColor(context),
        onTap: onTap,
        onPositionChanged: onPositionChanged,
        onMapReady: onMapReady,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
      ),
      children: [
        ...service.buildBaseLayers(context, showLabels: settings.showMapLabels),
        if (geofences.isNotEmpty)
          GeofenceLayers(geofences: geofences, highlightId: highlightGeofenceId),
        if (route != null && route!.length > 1)
          RouteLayers(points: route!, color: routeColor, showEndpoints: false, width: 4),
        ...layersBelowDevices,
        if (showUserLocation)
          const MarkerLayer(markers: [
            Marker(point: NcrGeo.userLocation, width: 36, height: 36, child: UserLocationDot()),
          ]),
        if (devices.isNotEmpty)
          AnimatedDevicesLayer(
            devices: devices,
            selectedId: selectedId,
            onTap: onDeviceTap,
            clustering: clustering ?? settings.clustering,
            onSelectedPosition: onSelectedPosition,
            mapController: controller,
          ),
        ...layersAboveDevices,
      ],
    );
  }
}

/// Round floating map button.
class MapButton extends StatelessWidget {
  const MapButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? scheme.primary : scheme.surface,
          borderRadius: AppRadius.mdAll,
          boxShadow: AppShadows.floating(theme.brightness),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadius.mdAll,
            onTap: onPressed,
            child: Icon(icon, size: 20, color: active ? scheme.onPrimary : scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// Smooth camera transitions for a [MapController].
mixin AnimatedMapMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  MapController get mapController;
  AnimationController? _cameraAnim;

  void animateCamera(LatLng dest, double destZoom, {Duration duration = const Duration(milliseconds: 650)}) {
    final camera = mapController.camera;
    final latTween = Tween(begin: camera.center.latitude, end: dest.latitude);
    final lngTween = Tween(begin: camera.center.longitude, end: dest.longitude);
    final zoomTween = Tween(begin: camera.zoom, end: destZoom);
    _cameraAnim?.dispose();
    final c = AnimationController(vsync: this, duration: duration);
    _cameraAnim = c;
    final curve = CurvedAnimation(parent: c, curve: Curves.easeInOutCubic);
    c.addListener(() {
      mapController.move(
        LatLng(latTween.evaluate(curve), lngTween.evaluate(curve)),
        zoomTween.evaluate(curve),
      );
    });
    c.forward();
  }

  void zoomBy(double delta) {
    final camera = mapController.camera;
    animateCamera(camera.center, (camera.zoom + delta).clamp(8.5, 18), duration: const Duration(milliseconds: 280));
  }

  @override
  void dispose() {
    _cameraAnim?.dispose();
    super.dispose();
  }
}
