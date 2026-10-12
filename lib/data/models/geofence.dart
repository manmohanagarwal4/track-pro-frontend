import 'package:latlong2/latlong.dart';

import 'enums.dart';

/// Circular geofence.
class Geofence {
  const Geofence({
    required this.id,
    required this.name,
    required this.type,
    required this.center,
    required this.radiusM,
    required this.createdAt,
    this.notifyEnter = true,
    this.notifyExit = true,
    this.deviceIds = const [],
    this.active = true,
  });

  final String id;
  final String name;
  final GeofenceType type;
  final LatLng center;
  final double radiusM;
  final DateTime createdAt;
  final bool notifyEnter;
  final bool notifyExit;

  /// Devices monitored by this fence. Empty = all devices.
  final List<String> deviceIds;
  final bool active;

  bool appliesTo(String deviceId) => deviceIds.isEmpty || deviceIds.contains(deviceId);

  Geofence copyWith({
    String? name,
    GeofenceType? type,
    LatLng? center,
    double? radiusM,
    bool? notifyEnter,
    bool? notifyExit,
    List<String>? deviceIds,
    bool? active,
  }) =>
      Geofence(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        center: center ?? this.center,
        radiusM: radiusM ?? this.radiusM,
        createdAt: createdAt,
        notifyEnter: notifyEnter ?? this.notifyEnter,
        notifyExit: notifyExit ?? this.notifyExit,
        deviceIds: deviceIds ?? this.deviceIds,
        active: active ?? this.active,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'lat': center.latitude,
        'lng': center.longitude,
        'radius': radiusM,
        'createdAt': createdAt.toIso8601String(),
        'enter': notifyEnter,
        'exit': notifyExit,
        'devices': deviceIds,
        'active': active,
      };

  factory Geofence.fromJson(Map<String, dynamic> j) => Geofence(
        id: j['id'] as String,
        name: j['name'] as String,
        type: enumByName(GeofenceType.values, j['type'], GeofenceType.home),
        center: LatLng((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
        radiusM: (j['radius'] as num).toDouble(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        notifyEnter: j['enter'] as bool? ?? true,
        notifyExit: j['exit'] as bool? ?? true,
        deviceIds: (j['devices'] as List?)?.cast<String>() ?? const [],
        active: j['active'] as bool? ?? true,
      );
}

/// Emitted by the geofence engine when a device crosses a fence boundary.
class GeofenceEvent {
  const GeofenceEvent({
    required this.deviceId,
    required this.geofence,
    required this.type,
    required this.position,
    required this.timestamp,
  });

  final String deviceId;
  final Geofence geofence;
  final GeofenceEventType type;
  final LatLng position;
  final DateTime timestamp;
}
