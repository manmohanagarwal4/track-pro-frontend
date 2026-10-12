import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Pure geographic calculations (no external services).
abstract final class GeoUtils {
  static const double earthRadiusM = 6371008.8;

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;

  /// Great-circle distance in meters (Haversine).
  static double distanceMeters(LatLng a, LatLng b) {
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * earthRadiusM * math.asin(math.min(1, math.sqrt(h)));
  }

  static double distanceKm(LatLng a, LatLng b) => distanceMeters(a, b) / 1000;

  /// Total length of a polyline in meters.
  static double pathLengthMeters(List<LatLng> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += distanceMeters(points[i - 1], points[i]);
    }
    return total;
  }

  /// Initial bearing from [a] to [b], degrees clockwise from north (0..360).
  static double bearing(LatLng a, LatLng b) {
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (_deg(math.atan2(y, x)) + 360) % 360;
  }

  /// Point at [distanceM] along [bearingDeg] from [origin].
  static LatLng destination(LatLng origin, double bearingDeg, double distanceM) {
    final d = distanceM / earthRadiusM;
    final brng = _rad(bearingDeg);
    final lat1 = _rad(origin.latitude);
    final lng1 = _rad(origin.longitude);
    final lat2 = math.asin(
        math.sin(lat1) * math.cos(d) + math.cos(lat1) * math.sin(d) * math.cos(brng));
    final lng2 = lng1 +
        math.atan2(math.sin(brng) * math.sin(d) * math.cos(lat1),
            math.cos(d) - math.sin(lat1) * math.sin(lat2));
    return LatLng(_deg(lat2), (_deg(lng2) + 540) % 360 - 180);
  }

  /// Linear interpolation between two nearby points (fine for < few km).
  static LatLng lerp(LatLng a, LatLng b, double t) => LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

  /// Shortest signed difference between two headings (-180..180).
  static double headingDelta(double from, double to) => ((to - from + 540) % 360) - 180;

  /// Interpolates headings along the shortest arc.
  static double lerpHeading(double a, double b, double t) =>
      (a + headingDelta(a, b) * t + 360) % 360;

  static bool isInsideCircle(LatLng point, LatLng center, double radiusM) =>
      distanceMeters(point, center) <= radiusM;

  /// Speed in km/h between two timed points.
  static double speedKmh(LatLng a, DateTime ta, LatLng b, DateTime tb) {
    final seconds = tb.difference(ta).inMilliseconds / 1000;
    if (seconds <= 0) return 0;
    return distanceMeters(a, b) / seconds * 3.6;
  }

  static const _compass = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

  static String compass(double heading) =>
      _compass[(((heading % 360) + 22.5) ~/ 45) % 8];

  /// Inserts points so that no segment is longer than [maxSegmentM].
  static List<LatLng> densify(List<LatLng> points, double maxSegmentM) {
    if (points.length < 2) return List.of(points);
    final out = <LatLng>[points.first];
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final d = distanceMeters(a, b);
      final steps = (d / maxSegmentM).ceil();
      for (var s = 1; s <= steps; s++) {
        out.add(lerp(a, b, s / steps));
      }
    }
    return out;
  }

  static LatLng centroid(List<LatLng> points) {
    var lat = 0.0, lng = 0.0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }
}
