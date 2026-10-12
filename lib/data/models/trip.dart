import 'device_location.dart';

/// Aggregate statistics computed from a series of [TrackPoint]s.
class TripStats {
  const TripStats({
    required this.distanceKm,
    required this.duration,
    required this.movingTime,
    required this.idleTime,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.stops,
  });

  static const empty = TripStats(
    distanceKm: 0,
    duration: Duration.zero,
    movingTime: Duration.zero,
    idleTime: Duration.zero,
    avgSpeedKmh: 0,
    maxSpeedKmh: 0,
    stops: 0,
  );

  final double distanceKm;
  final Duration duration;
  final Duration movingTime;
  final Duration idleTime;

  /// Average over moving time.
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int stops;
}

class Trip {
  const Trip({
    required this.id,
    required this.deviceId,
    required this.startName,
    required this.endName,
    required this.points,
    required this.stats,
  });

  final String id;
  final String deviceId;
  final String startName;
  final String endName;
  final List<TrackPoint> points;
  final TripStats stats;

  DateTime get start => points.first.timestamp;
  DateTime get end => points.last.timestamp;
}

/// Route history for a period (several trips concatenated).
class LocationHistory {
  const LocationHistory({required this.deviceId, required this.points, required this.stats});

  final String deviceId;
  final List<TrackPoint> points;
  final TripStats stats;

  bool get isEmpty => points.length < 2;
}
