import 'dart:collection';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../../core/utils/geo_utils.dart';
import 'ncr_geo.dart';

/// A drivable path with the cumulative distance of every vertex, plus the
/// distances at which the vehicle should pause (signals, destinations).
class RoutePath {
  RoutePath(this.points, {List<RouteStop> stops = const []})
      : cumulative = _cumulative(points),
        stops = List.unmodifiable(stops);

  final List<LatLng> points;
  final List<double> cumulative;
  final List<RouteStop> stops;

  double get length => cumulative.isEmpty ? 0 : cumulative.last;

  static List<double> _cumulative(List<LatLng> pts) {
    final out = List<double>.filled(pts.length, 0);
    for (var i = 1; i < pts.length; i++) {
      out[i] = out[i - 1] + GeoUtils.distanceMeters(pts[i - 1], pts[i]);
    }
    return out;
  }

  /// Position and heading at [distance] meters along the path (wraps around).
  ({LatLng point, double heading}) sample(double distance) {
    if (points.length < 2 || length == 0) {
      return (point: points.first, heading: 0);
    }
    final d = distance % length;
    var lo = 0, hi = cumulative.length - 1;
    while (lo < hi - 1) {
      final mid = (lo + hi) >> 1;
      if (cumulative[mid] <= d) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final segLen = cumulative[hi] - cumulative[lo];
    final t = segLen == 0 ? 0.0 : (d - cumulative[lo]) / segLen;
    return (
      point: GeoUtils.lerp(points[lo], points[hi], t),
      heading: GeoUtils.bearing(points[lo], points[hi]),
    );
  }
}

class RouteStop {
  const RouteStop(this.distance, this.isDestination, this.placeId);

  final double distance;
  final bool isDestination;
  final String? placeId;
}

/// Road graph over [NcrGeo] with shortest-path routing.
class RouteEngine {
  RouteEngine() {
    for (final road in NcrGeo.roads) {
      for (var i = 1; i < road.nodes.length; i++) {
        final a = road.nodes[i - 1];
        final b = road.nodes[i];
        final w = GeoUtils.distanceMeters(
            NcrGeo.placeById[a]!.point, NcrGeo.placeById[b]!.point);
        _adj.putIfAbsent(a, () => {})[b] = w;
        _adj.putIfAbsent(b, () => {})[a] = w;
      }
    }
  }

  final Map<String, Map<String, double>> _adj = {};

  Iterable<String> get nodeIds => _adj.keys;

  /// Dijkstra shortest path between two place ids.
  List<String> shortestPath(String from, String to) {
    if (from == to) return [from];
    final dist = <String, double>{from: 0};
    final prev = <String, String>{};
    final queue = SplayTreeSet<(double, String)>((a, b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0 ? c : a.$2.compareTo(b.$2);
    })
      ..add((0, from));
    while (queue.isNotEmpty) {
      final (d, u) = queue.first;
      queue.remove(queue.first);
      if (u == to) break;
      for (final e in (_adj[u] ?? const <String, double>{}).entries) {
        final nd = d + e.value;
        if (nd < (dist[e.key] ?? double.infinity)) {
          if (dist.containsKey(e.key)) queue.remove((dist[e.key]!, e.key));
          dist[e.key] = nd;
          prev[e.key] = u;
          queue.add((nd, e.key));
        }
      }
    }
    if (!prev.containsKey(to)) return [from];
    final path = <String>[to];
    var cur = to;
    while (prev.containsKey(cur)) {
      cur = prev[cur]!;
      path.add(cur);
    }
    return path.reversed.toList();
  }

  String nearestNode(LatLng p) {
    String best = _adj.keys.first;
    var bestD = double.infinity;
    for (final id in _adj.keys) {
      final d = GeoUtils.distanceMeters(p, NcrGeo.placeById[id]!.point);
      if (d < bestD) {
        bestD = d;
        best = id;
      }
    }
    return best;
  }

  /// Builds a closed driving loop visiting [waypoints] in order and returning
  /// to the first. Intermediate graph nodes become short "signal" stops.
  RoutePath loopThrough(List<String> waypoints, {double signalChance = 0.35, int seed = 1}) {
    final rnd = math.Random(seed);
    final nodes = <String>[];
    for (var i = 0; i < waypoints.length; i++) {
      final a = waypoints[i];
      final b = waypoints[(i + 1) % waypoints.length];
      final seg = shortestPath(a, b);
      if (nodes.isNotEmpty) seg.removeAt(0);
      nodes.addAll(seg);
    }
    return _toPath(nodes, waypoints.toSet(), signalChance, rnd);
  }

  RoutePath _toPath(List<String> nodes, Set<String> destinations, double signalChance, math.Random rnd) {
    final points = <LatLng>[];
    final stops = <RouteStop>[];
    var acc = 0.0;
    for (var i = 0; i < nodes.length; i++) {
      final p = NcrGeo.placeById[nodes[i]]!.point;
      if (points.isNotEmpty) {
        final seg = GeoUtils.densify([points.last, p], 250).skip(1).toList();
        for (final s in seg) {
          acc += GeoUtils.distanceMeters(points.last, s);
          points.add(s);
        }
      } else {
        points.add(p);
      }
      if (i == 0) continue;
      if (destinations.contains(nodes[i])) {
        stops.add(RouteStop(acc, true, nodes[i]));
      } else if (rnd.nextDouble() < signalChance) {
        stops.add(RouteStop(acc, false, nodes[i]));
      }
    }
    return RoutePath(points, stops: stops);
  }

  /// A meandering closed loop around [center] (pets, people walking).
  static RoutePath wanderLoop(
    LatLng center, {
    required double minRadius,
    required double maxRadius,
    int seed = 7,
    int vertices = 28,
  }) {
    final rnd = math.Random(seed);
    final pts = <LatLng>[];
    final phase = rnd.nextDouble() * math.pi * 2;
    for (var i = 0; i < vertices; i++) {
      final angle = i / vertices * 360;
      final wobble = (math.sin(i / vertices * math.pi * 2 * 2 + phase) + 1) / 2;
      final r = minRadius + (maxRadius - minRadius) * (0.6 * wobble + 0.4 * rnd.nextDouble());
      pts.add(GeoUtils.destination(center, angle, r));
    }
    pts.add(pts.first);
    final dense = GeoUtils.densify(pts, 40);
    final path = RoutePath(dense);
    final stops = <RouteStop>[
      for (var k = 1; k <= 3; k++) RouteStop(path.length * k / 3.2, false, null),
    ];
    return RoutePath(dense, stops: stops);
  }
}

/// Mock reverse geocoder using the nearest known place.
class PlaceResolver {
  const PlaceResolver();

  Place nearestPlace(LatLng p) {
    Place best = NcrGeo.places.first;
    var bestD = double.infinity;
    for (final place in NcrGeo.places) {
      final d = GeoUtils.distanceMeters(p, place.point);
      if (d < bestD) {
        bestD = d;
        best = place;
      }
    }
    return best;
  }

  /// e.g. "Sector 18, Noida".
  String shortName(LatLng p) {
    final place = nearestPlace(p);
    if (place.name == place.city) return place.city;
    return '${place.name}, ${place.city}';
  }

  /// e.g. "Near Sector 18, Noida, Uttar Pradesh".
  String describe(LatLng p) {
    final place = nearestPlace(p);
    final d = GeoUtils.distanceMeters(p, place.point);
    final state = NcrGeo.stateByCity[place.city] ?? 'India';
    final base = place.name == place.city ? place.city : '${place.name}, ${place.city}';
    return d < 400 ? '$base, $state' : 'Near $base, $state';
  }

  String city(LatLng p) => nearestPlace(p).city;
}
