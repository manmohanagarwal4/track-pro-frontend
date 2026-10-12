import 'package:latlong2/latlong.dart';

import 'enums.dart';

class TrackerAlert {
  const TrackerAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.deviceId,
    required this.deviceName,
    required this.title,
    required this.message,
    required this.timestamp,
    this.value,
    this.position,
    this.read = false,
  });

  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String deviceId;
  final String deviceName;
  final String title;
  final String message;
  final DateTime timestamp;

  /// Optional headline value, e.g. "94 km/h".
  final String? value;
  final LatLng? position;
  final bool read;

  TrackerAlert copyWith({bool? read}) => TrackerAlert(
        id: id,
        type: type,
        severity: severity,
        deviceId: deviceId,
        deviceName: deviceName,
        title: title,
        message: message,
        timestamp: timestamp,
        value: value,
        position: position,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'severity': severity.name,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'title': title,
        'message': message,
        'ts': timestamp.toIso8601String(),
        'value': value,
        'lat': position?.latitude,
        'lng': position?.longitude,
        'read': read,
      };

  factory TrackerAlert.fromJson(Map<String, dynamic> j) => TrackerAlert(
        id: j['id'] as String,
        type: enumByName(AlertType.values, j['type'], AlertType.overspeed),
        severity: enumByName(AlertSeverity.values, j['severity'], AlertSeverity.info),
        deviceId: j['deviceId'] as String,
        deviceName: j['deviceName'] as String,
        title: j['title'] as String,
        message: j['message'] as String,
        timestamp: DateTime.parse(j['ts'] as String),
        value: j['value'] as String?,
        position: j['lat'] == null
            ? null
            : LatLng((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
        read: j['read'] as bool? ?? false,
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.timestamp,
    this.deviceId,
    this.read = false,
  });

  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? deviceId;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        category: category,
        title: title,
        body: body,
        timestamp: timestamp,
        deviceId: deviceId,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'title': title,
        'body': body,
        'ts': timestamp.toIso8601String(),
        'deviceId': deviceId,
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        category: enumByName(
            NotificationCategory.values, j['category'], NotificationCategory.system),
        title: j['title'] as String,
        body: j['body'] as String,
        timestamp: DateTime.parse(j['ts'] as String),
        deviceId: j['deviceId'] as String?,
        read: j['read'] as bool? ?? false,
      );
}
