import 'device_location.dart';
import 'enums.dart';

/// Per-device alert configuration.
class AlertConfig {
  const AlertConfig({
    this.overspeed = true,
    this.speedLimit = 80,
    this.geofence = true,
    this.lowBattery = true,
    this.offline = true,
    this.sos = true,
  });

  final bool overspeed;
  final double speedLimit;
  final bool geofence;
  final bool lowBattery;
  final bool offline;
  final bool sos;

  AlertConfig copyWith({
    bool? overspeed,
    double? speedLimit,
    bool? geofence,
    bool? lowBattery,
    bool? offline,
    bool? sos,
  }) =>
      AlertConfig(
        overspeed: overspeed ?? this.overspeed,
        speedLimit: speedLimit ?? this.speedLimit,
        geofence: geofence ?? this.geofence,
        lowBattery: lowBattery ?? this.lowBattery,
        offline: offline ?? this.offline,
        sos: sos ?? this.sos,
      );

  Map<String, dynamic> toJson() => {
        'overspeed': overspeed,
        'speedLimit': speedLimit,
        'geofence': geofence,
        'lowBattery': lowBattery,
        'offline': offline,
        'sos': sos,
      };

  factory AlertConfig.fromJson(Map<String, dynamic> j) => AlertConfig(
        overspeed: j['overspeed'] as bool? ?? true,
        speedLimit: (j['speedLimit'] as num?)?.toDouble() ?? 80,
        geofence: j['geofence'] as bool? ?? true,
        lowBattery: j['lowBattery'] as bool? ?? true,
        offline: j['offline'] as bool? ?? true,
        sos: j['sos'] as bool? ?? true,
      );
}

/// The physical GPS tracker. It may or may not be assigned to an [Asset].
class TrackerDevice {
  const TrackerDevice({
    required this.id,
    required this.imei,
    required this.model,
    required this.firmware,
    required this.addedAt,
    this.assetId,
    this.iconOverride,
    this.trackingMode = TrackingMode.normal,
    this.alertConfig = const AlertConfig(),
    this.emergency = false,
    this.connected = true,
    this.location,
    this.lastSeen,
    this.tripDistanceKm = 0,
    this.odometerKm = 0,
  });

  final String id;
  final String imei;
  final String model;
  final String firmware;
  final DateTime addedAt;
  final String? assetId;
  final AssetType? iconOverride;
  final TrackingMode trackingMode;
  final AlertConfig alertConfig;
  final bool emergency;

  /// Whether the tracker currently has a live link.
  final bool connected;
  final DeviceLocation? location;
  final DateTime? lastSeen;
  final double tripDistanceKm;
  final double odometerKm;

  /// Effective reporting interval, accounting for emergency mode.
  Duration get updateInterval =>
      emergency ? TrackingMode.emergency.interval : trackingMode.interval;

  TrackerDevice copyWith({
    String? assetId,
    bool clearAsset = false,
    AssetType? iconOverride,
    bool clearIcon = false,
    TrackingMode? trackingMode,
    AlertConfig? alertConfig,
    bool? emergency,
    bool? connected,
    DeviceLocation? location,
    DateTime? lastSeen,
    double? tripDistanceKm,
    double? odometerKm,
  }) =>
      TrackerDevice(
        id: id,
        imei: imei,
        model: model,
        firmware: firmware,
        addedAt: addedAt,
        assetId: clearAsset ? null : (assetId ?? this.assetId),
        iconOverride: clearIcon ? null : (iconOverride ?? this.iconOverride),
        trackingMode: trackingMode ?? this.trackingMode,
        alertConfig: alertConfig ?? this.alertConfig,
        emergency: emergency ?? this.emergency,
        connected: connected ?? this.connected,
        location: location ?? this.location,
        lastSeen: lastSeen ?? this.lastSeen,
        tripDistanceKm: tripDistanceKm ?? this.tripDistanceKm,
        odometerKm: odometerKm ?? this.odometerKm,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'imei': imei,
        'model': model,
        'firmware': firmware,
        'addedAt': addedAt.toIso8601String(),
        'assetId': assetId,
        'icon': iconOverride?.name,
        'mode': trackingMode.name,
        'alerts': alertConfig.toJson(),
        'emergency': emergency,
        'connected': connected,
        'location': location?.toJson(),
        'lastSeen': lastSeen?.toIso8601String(),
        'trip': tripDistanceKm,
        'odo': odometerKm,
      };

  factory TrackerDevice.fromJson(Map<String, dynamic> j) => TrackerDevice(
        id: j['id'] as String,
        imei: j['imei'] as String,
        model: j['model'] as String,
        firmware: j['firmware'] as String,
        addedAt: DateTime.parse(j['addedAt'] as String),
        assetId: j['assetId'] as String?,
        iconOverride:
            j['icon'] == null ? null : enumByName(AssetType.values, j['icon'], AssetType.generic),
        trackingMode: enumByName(TrackingMode.values, j['mode'], TrackingMode.normal),
        alertConfig: AlertConfig.fromJson(j['alerts'] as Map<String, dynamic>),
        emergency: j['emergency'] as bool? ?? false,
        connected: j['connected'] as bool? ?? true,
        location: j['location'] == null
            ? null
            : DeviceLocation.fromJson(j['location'] as Map<String, dynamic>),
        lastSeen: j['lastSeen'] == null ? null : DateTime.parse(j['lastSeen'] as String),
        tripDistanceKm: (j['trip'] as num?)?.toDouble() ?? 0,
        odometerKm: (j['odo'] as num?)?.toDouble() ?? 0,
      );
}
