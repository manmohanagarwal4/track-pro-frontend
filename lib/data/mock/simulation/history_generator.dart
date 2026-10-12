import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../../core/utils/geo_utils.dart';
import '../../../domain/trip_calculator.dart';
import '../../models/device_location.dart';
import '../../models/trip.dart';
import '../geo/ncr_geo.dart';
import '../geo/route_engine.dart';
import 'sim_profile.dart';

/// Generates deterministic, realistic historical tracks for simulated devices.
///
/// The same device + day always yields the same trips, so history is stable
/// across screens and app restarts.
class HistoryGenerator {
  HistoryGenerator(this._routes, {this.placeResolver = const PlaceResolver()});

  final RouteEngine _routes;
  final PlaceResolver placeResolver;
  final Map<String, List<Trip>> _cache = {};

  static const _sample = Duration(seconds: 15);

  static const _hubs = [
    'cp', 'noida18', 'noida62', 'ghaziabad', 'cyberCity', 'airportT3', 'dwarka',
    'faridabad', 'pariChowk', 'dadri', 'rohini', 'saket', 'kashmereGate',
    'indirapuram', 'laxmiNagar', 'huda', 'noida37', 'mayurVihar',
  ];

  /// Trips that happened on [day] (local date), clipped to [until].
  List<Trip> tripsForDay(String deviceId, SimProfile profile, DateTime day, {required DateTime until}) {
    final dayStart = DateTime(day.year, day.month, day.day);
    if (dayStart.isAfter(until)) return const [];
    final key = '$deviceId|${dayStart.toIso8601String()}';
    final all = _cache.putIfAbsent(key, () => _generateDay(deviceId, profile, dayStart));
    return all.where((t) => !t.end.isAfter(until)).toList();
  }

  List<Trip> tripsBetween(String deviceId, SimProfile profile, DateTime start, DateTime end,
      {required DateTime now}) {
    final until = end.isBefore(now) ? end : now;
    final trips = <Trip>[];
    var day = DateTime(start.year, start.month, start.day);
    while (!day.isAfter(until)) {
      for (final t in tripsForDay(deviceId, profile, day, until: until)) {
        if (!t.start.isBefore(start)) trips.add(t);
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return trips;
  }

  LocationHistory history(String deviceId, SimProfile profile, DateTime start, DateTime end,
      {required DateTime now}) {
    final trips = tripsBetween(deviceId, profile, start, end, now: now);
    final points = <TrackPoint>[for (final t in trips) ...t.points];
    return LocationHistory(deviceId: deviceId, points: points, stats: combine(trips));
  }

  /// Aggregates per-trip stats (gaps between trips are not counted as idle).
  static TripStats combine(List<Trip> trips) {
    if (trips.isEmpty) return TripStats.empty;
    var dist = 0.0, maxS = 0.0, stops = 0;
    var dur = Duration.zero, moving = Duration.zero, idle = Duration.zero;
    for (final t in trips) {
      dist += t.stats.distanceKm;
      dur += t.stats.duration;
      moving += t.stats.movingTime;
      idle += t.stats.idleTime;
      maxS = math.max(maxS, t.stats.maxSpeedKmh);
      stops += t.stats.stops;
    }
    stops += trips.length - 1;
    final h = moving.inMilliseconds / 3600000;
    return TripStats(
      distanceKm: dist,
      duration: dur,
      movingTime: moving,
      idleTime: idle,
      avgSpeedKmh: h > 0 ? dist / h : 0,
      maxSpeedKmh: maxS,
      stops: stops,
    );
  }

  // ------------------------------------------------------------ generation

  List<Trip> _generateDay(String deviceId, SimProfile profile, DateTime day) {
    final seed = deviceId.codeUnits.fold<int>(17, (a, c) => a * 31 + c) ^ day.millisecondsSinceEpoch ~/ 86400000;
    final rnd = math.Random(seed & 0x7fffffff);
    if (profile.waypoints.isNotEmpty) return _roadDay(deviceId, profile, day, rnd);
    if (profile.kind == MotionKind.wander) return _wanderDay(deviceId, profile, day, rnd);
    return const [];
  }

  List<Trip> _roadDay(String deviceId, SimProfile profile, DateTime day, math.Random rnd) {
    final trips = <Trip>[];
    final count = 2 + rnd.nextInt(3);
    var node = profile.waypoints.first;
    var t = day.add(Duration(hours: 7, minutes: rnd.nextInt(80)));
    final candidates = {...profile.waypoints, ..._hubs}.toList();
    for (var i = 0; i < count; i++) {
      String dest;
      // Prefer the device's own waypoints so history matches its live route.
      if (rnd.nextDouble() < 0.7 && profile.waypoints.length > 1) {
        final idx = (profile.waypoints.indexOf(node) + 1) % profile.waypoints.length;
        dest = profile.waypoints[idx < 0 ? 0 : idx];
      } else {
        dest = candidates[rnd.nextInt(candidates.length)];
      }
      if (dest == node) dest = profile.waypoints.length > 1 ? profile.waypoints[1] : 'cp';
      if (dest == node) continue;
      final nodes = _routes.shortestPath(node, dest);
      final pts = _driveAlong(nodes, t, profile, rnd);
      if (pts.length > 1) {
        trips.add(_trip(deviceId, '${day.toIso8601String()}-$i', pts));
        t = pts.last.timestamp.add(Duration(minutes: 25 + rnd.nextInt(110)));
      }
      node = dest;
      if (t.hour >= 22) break;
    }
    return trips;
  }

  List<TrackPoint> _driveAlong(List<String> nodes, DateTime start, SimProfile profile, math.Random rnd) {
    final out = <TrackPoint>[];
    var t = start;
    var speed = 0.0;
    var target = _r(rnd, profile.minSpeed, profile.maxSpeed);
    for (var n = 1; n < nodes.length; n++) {
      final a = NcrGeo.placeById[nodes[n - 1]]!.point;
      final b = NcrGeo.placeById[nodes[n]]!.point;
      final segLen = GeoUtils.distanceMeters(a, b);
      var d = 0.0;
      if (out.isEmpty) out.add(TrackPoint(a, t, 0));
      while (d < segLen) {
        if (rnd.nextDouble() < 0.12) {
          target = profile.surgeChance > 0 && rnd.nextDouble() < profile.surgeChance * 2
              ? profile.surgeSpeed + _r(rnd, -4, 6)
              : _r(rnd, profile.minSpeed, profile.maxSpeed);
        }
        speed += (target - speed) * 0.45;
        d += speed / 3.6 * _sample.inSeconds;
        t = t.add(_sample);
        out.add(TrackPoint(GeoUtils.lerp(a, b, math.min(1, d / segLen)), t, speed + _r(rnd, -1.5, 1.5)));
      }
      // Occasional traffic stop at intersections.
      if (n < nodes.length - 1 && rnd.nextDouble() < 0.3) {
        final stopMin = 1 + rnd.nextInt(4);
        for (var k = 0; k < stopMin * 2; k++) {
          t = t.add(const Duration(seconds: 30));
          out.add(TrackPoint(b, t, 0));
        }
        speed = 0;
      }
    }
    // Arrive and stop.
    t = t.add(_sample);
    out.add(TrackPoint(out.last.position, t, 0));
    return out;
  }

  List<Trip> _wanderDay(String deviceId, SimProfile profile, DateTime day, math.Random rnd) {
    final anchor = profile.anchor;
    if (anchor == null) return const [];
    final trips = <Trip>[];
    final walks = 2 + rnd.nextInt(2);
    final startHours = [6, 12, 17, 20];
    for (var i = 0; i < walks; i++) {
      var t = day.add(Duration(hours: startHours[i], minutes: rnd.nextInt(50)));
      final loop = RouteEngine.wanderLoop(anchor,
          minRadius: profile.minRadius, maxRadius: profile.maxRadius * 1.3, seed: rnd.nextInt(1 << 30));
      final minutes = 20 + rnd.nextInt(25);
      final pts = <TrackPoint>[TrackPoint(loop.points.first, t, 0)];
      var progress = 0.0;
      final end = t.add(Duration(minutes: minutes));
      while (t.isBefore(end)) {
        final pause = rnd.nextDouble() < 0.08;
        final v = pause ? 0.0 : _r(rnd, profile.minSpeed, profile.maxSpeed);
        progress += v / 3.6 * _sample.inSeconds;
        t = t.add(_sample);
        pts.add(TrackPoint(loop.sample(progress).point, t, v));
      }
      // Head home.
      pts.add(TrackPoint(anchor, t.add(const Duration(minutes: 2)), 0));
      trips.add(_trip(deviceId, '${day.toIso8601String()}-w$i', pts));
    }
    return trips;
  }

  Trip _trip(String deviceId, String key, List<TrackPoint> pts) {
    return Trip(
      id: '$deviceId-$key',
      deviceId: deviceId,
      startName: placeResolver.shortName(pts.first.position),
      endName: placeResolver.shortName(pts.last.position),
      points: pts,
      stats: TripCalculator.compute(pts),
    );
  }

  static double _r(math.Random rnd, double a, double b) => a + rnd.nextDouble() * (b - a);

  /// Live "today" points leading to [current] are not generated here; the
  /// live trail comes from the realtime stream.
  static LatLng? lastPosition(List<Trip> trips) => trips.isEmpty ? null : trips.last.points.last.position;
}
