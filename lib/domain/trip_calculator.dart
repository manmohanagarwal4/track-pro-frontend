import 'dart:math' as math;

import '../core/utils/geo_utils.dart';
import '../data/models/device_location.dart';
import '../data/models/trip.dart';

/// Computes trip statistics from raw track points using real geodesic distance.
abstract final class TripCalculator {
  /// Speed (km/h) at or below which the asset is considered stationary.
  static const stationarySpeed = 2.0;

  /// A stationary period at least this long counts as a stop.
  static const minStop = Duration(minutes: 2);

  static TripStats compute(List<TrackPoint> points) {
    if (points.length < 2) return TripStats.empty;

    var distanceM = 0.0;
    var moving = Duration.zero;
    var idle = Duration.zero;
    var maxSpeed = 0.0;
    var stops = 0;
    var stillRun = Duration.zero;

    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final dt = b.timestamp.difference(a.timestamp);
      if (dt.isNegative) continue;
      distanceM += GeoUtils.distanceMeters(a.position, b.position);
      final segSpeed = math.max(b.speedKmh, 0.0);
      maxSpeed = math.max(maxSpeed, segSpeed);
      if (segSpeed <= stationarySpeed) {
        idle += dt;
        stillRun += dt;
      } else {
        if (stillRun >= minStop) stops++;
        stillRun = Duration.zero;
        moving += dt;
      }
    }
    // A stop still in progress at the end is not counted: it is the destination.

    final duration = points.last.timestamp.difference(points.first.timestamp);
    final hours = moving.inMilliseconds / 3600000;
    final distanceKm = distanceM / 1000;
    return TripStats(
      distanceKm: distanceKm,
      duration: duration,
      movingTime: moving,
      idleTime: idle,
      avgSpeedKmh: hours > 0 ? distanceKm / hours : 0,
      maxSpeedKmh: maxSpeed,
      stops: stops,
    );
  }

  /// Splits a continuous track into trips separated by stationary gaps of at
  /// least [gap].
  static List<List<TrackPoint>> split(
    List<TrackPoint> points, {
    Duration gap = const Duration(minutes: 10),
  }) {
    final trips = <List<TrackPoint>>[];
    var current = <TrackPoint>[];
    DateTime? stillSince;
    for (final p in points) {
      final still = p.speedKmh <= stationarySpeed;
      if (still) {
        stillSince ??= p.timestamp;
      } else {
        if (stillSince != null &&
            p.timestamp.difference(stillSince) >= gap &&
            current.length > 1) {
          trips.add(_trimTail(current));
          current = [];
        }
        stillSince = null;
      }
      current.add(p);
    }
    if (current.length > 1) trips.add(_trimTail(current));
    return trips.where((t) => t.length > 1).toList();
  }

  static List<TrackPoint> _trimTail(List<TrackPoint> t) {
    var end = t.length;
    while (end > 2 && t[end - 1].speedKmh <= stationarySpeed && t[end - 2].speedKmh <= stationarySpeed) {
      end--;
    }
    return t.sublist(0, end);
  }
}
