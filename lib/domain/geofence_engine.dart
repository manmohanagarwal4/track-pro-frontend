import 'package:latlong2/latlong.dart';

import '../core/utils/geo_utils.dart';
import '../data/models/enums.dart';
import '../data/models/geofence.dart';

/// Detects geofence boundary crossings from a stream of positions.
///
/// The first time a device is seen for a fence its state is recorded silently,
/// so a device that starts inside a fence does not produce a spurious ENTER.
class GeofenceEngine {
  final Map<String, Map<String, bool>> _inside = {};

  List<GeofenceEvent> evaluate({
    required String deviceId,
    required LatLng position,
    required DateTime timestamp,
    required List<Geofence> geofences,
  }) {
    final states = _inside.putIfAbsent(deviceId, () => {});
    final events = <GeofenceEvent>[];
    for (final fence in geofences) {
      if (!fence.active || !fence.appliesTo(deviceId)) continue;
      final nowInside = GeoUtils.isInsideCircle(position, fence.center, fence.radiusM);
      final wasInside = states[fence.id];
      states[fence.id] = nowInside;
      if (wasInside == null || wasInside == nowInside) continue;
      events.add(GeofenceEvent(
        deviceId: deviceId,
        geofence: fence,
        type: nowInside ? GeofenceEventType.enter : GeofenceEventType.exit,
        position: position,
        timestamp: timestamp,
      ));
    }
    return events;
  }

  bool? isInside(String deviceId, String geofenceId) => _inside[deviceId]?[geofenceId];

  /// Forget state for a fence (e.g. after it was edited or deleted).
  void resetFence(String geofenceId) {
    for (final m in _inside.values) {
      m.remove(geofenceId);
    }
  }

  void resetDevice(String deviceId) => _inside.remove(deviceId);
}
