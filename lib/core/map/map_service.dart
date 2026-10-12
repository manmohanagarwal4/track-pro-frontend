import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

/// Abstraction over the base-map provider.
///
/// All map *content* (markers, routes, geofences) is drawn by TrackPro's own
/// layers; only the base map comes from a [MapService]. To switch to a real
/// provider (OpenStreetMap, Mapbox, Google...), implement this interface and
/// register it in `mapServiceProvider`.
abstract interface class MapService {
  String get name;

  /// Whether the base map needs network access.
  bool get requiresNetwork;

  double get minZoom;
  double get maxZoom;
  LatLng get defaultCenter;
  double get defaultZoom;

  /// Base layers drawn underneath TrackPro content.
  List<Widget> buildBaseLayers(BuildContext context, {required bool showLabels});

  /// Background colour shown before / outside the base layers.
  Color backgroundColor(BuildContext context);
}

/// Build-time configuration. Pass with `--dart-define=MAP_PROVIDER=...`.
abstract final class MapConfig {
  static const provider = String.fromEnvironment('MAP_PROVIDER', defaultValue: 'simulated');
  static const apiKey = String.fromEnvironment('MAP_API_KEY');
}
