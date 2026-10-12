import 'package:latlong2/latlong.dart';

import 'enums.dart';

/// Sensor readings reported alongside a position fix.
class Telemetry {
  const Telemetry({
    required this.battery,
    required this.signal,
    required this.gpsSignal,
    required this.satellites,
    required this.temperature,
    required this.motion,
    this.ignition,
    this.fuel,
  });

  final int battery; // 0..100
  final SignalQuality signal; // cellular
  final SignalQuality gpsSignal;
  final int satellites;
  final double temperature; // °C
  final bool motion;
  final bool? ignition; // vehicles only
  final double? fuel; // % for fuel-equipped vehicles

  Telemetry copyWith({
    int? battery,
    SignalQuality? signal,
    SignalQuality? gpsSignal,
    int? satellites,
    double? temperature,
    bool? motion,
    bool? ignition,
    double? fuel,
  }) =>
      Telemetry(
        battery: battery ?? this.battery,
        signal: signal ?? this.signal,
        gpsSignal: gpsSignal ?? this.gpsSignal,
        satellites: satellites ?? this.satellites,
        temperature: temperature ?? this.temperature,
        motion: motion ?? this.motion,
        ignition: ignition ?? this.ignition,
        fuel: fuel ?? this.fuel,
      );

  Map<String, dynamic> toJson() => {
        'battery': battery,
        'signal': signal.name,
        'gps': gpsSignal.name,
        'sats': satellites,
        'temp': temperature,
        'motion': motion,
        'ignition': ignition,
        'fuel': fuel,
      };

  factory Telemetry.fromJson(Map<String, dynamic> j) => Telemetry(
        battery: (j['battery'] as num).toInt(),
        signal: enumByName(SignalQuality.values, j['signal'], SignalQuality.good),
        gpsSignal: enumByName(SignalQuality.values, j['gps'], SignalQuality.good),
        satellites: (j['sats'] as num).toInt(),
        temperature: (j['temp'] as num).toDouble(),
        motion: j['motion'] as bool,
        ignition: j['ignition'] as bool?,
        fuel: (j['fuel'] as num?)?.toDouble(),
      );
}

/// A single position fix from a tracker, with its telemetry.
class DeviceLocation {
  const DeviceLocation({
    required this.deviceId,
    required this.position,
    required this.speedKmh,
    required this.heading,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
    required this.telemetry,
  });

  final String deviceId;
  final LatLng position;
  final double speedKmh;
  final double heading; // degrees, 0 = north
  final double altitude; // m
  final double accuracy; // m
  final DateTime timestamp;
  final Telemetry telemetry;

  DeviceLocation copyWith({
    LatLng? position,
    double? speedKmh,
    double? heading,
    DateTime? timestamp,
    Telemetry? telemetry,
  }) =>
      DeviceLocation(
        deviceId: deviceId,
        position: position ?? this.position,
        speedKmh: speedKmh ?? this.speedKmh,
        heading: heading ?? this.heading,
        altitude: altitude,
        accuracy: accuracy,
        timestamp: timestamp ?? this.timestamp,
        telemetry: telemetry ?? this.telemetry,
      );

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': speedKmh,
        'heading': heading,
        'alt': altitude,
        'acc': accuracy,
        'ts': timestamp.toIso8601String(),
        'tel': telemetry.toJson(),
      };

  factory DeviceLocation.fromJson(Map<String, dynamic> j) => DeviceLocation(
        deviceId: j['deviceId'] as String,
        position: LatLng((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
        speedKmh: (j['speed'] as num).toDouble(),
        heading: (j['heading'] as num).toDouble(),
        altitude: (j['alt'] as num).toDouble(),
        accuracy: (j['acc'] as num).toDouble(),
        timestamp: DateTime.parse(j['ts'] as String),
        telemetry: Telemetry.fromJson(j['tel'] as Map<String, dynamic>),
      );
}

/// A lightweight historical point used for routes and trips.
class TrackPoint {
  const TrackPoint(this.position, this.timestamp, this.speedKmh);

  final LatLng position;
  final DateTime timestamp;
  final double speedKmh;
}
