import 'package:latlong2/latlong.dart';

import '../../models/enums.dart';

enum MotionKind { road, wander, stationary, offline }

/// Describes how a simulated tracker behaves.
class SimProfile {
  const SimProfile({
    required this.kind,
    this.waypoints = const [],
    this.anchor,
    this.minRadius = 150,
    this.maxRadius = 500,
    this.minSpeed = 30,
    this.maxSpeed = 60,
    this.surgeChance = 0,
    this.surgeSpeed = 0,
    this.startFraction = 0,
    this.destinationDwell = const Duration(seconds: 90),
    this.signalDwell = const Duration(seconds: 20),
    this.ignitionWhenStopped = false,
    this.batteryDrainPerMin = 0.02,
    this.offlineFlapPerHour = 0,
    this.initialDwell = Duration.zero,
    this.seed = 1,
  });

  final MotionKind kind;

  /// Road kinds: place ids visited in a loop.
  final List<String> waypoints;

  /// Wander centre / stationary position.
  final LatLng? anchor;
  final double minRadius;
  final double maxRadius;

  /// Cruise speed range in km/h.
  final double minSpeed;
  final double maxSpeed;

  /// Chance on each re-target to push to [surgeSpeed] (overspeed demo).
  final double surgeChance;
  final double surgeSpeed;
  final double startFraction;
  final Duration destinationDwell;
  final Duration signalDwell;

  /// For stationary vehicles: idle with engine on (true) or parked (false).
  final bool ignitionWhenStopped;
  final double batteryDrainPerMin;

  /// Expected random disconnections per hour of simulated time.
  final double offlineFlapPerHour;
  final Duration initialDwell;
  final int seed;

  /// A sensible profile for a tracker the user just added.
  factory SimProfile.forNewDevice(AssetType type, LatLng anchor, int seed) {
    return switch (type) {
      AssetType.pet => SimProfile(
          kind: MotionKind.wander,
          anchor: anchor,
          minRadius: 120,
          maxRadius: 450,
          minSpeed: 3,
          maxSpeed: 9,
          signalDwell: const Duration(seconds: 25),
          batteryDrainPerMin: 0.15,
          seed: seed),
      AssetType.person => SimProfile(
          kind: MotionKind.wander,
          anchor: anchor,
          minRadius: 300,
          maxRadius: 900,
          minSpeed: 3,
          maxSpeed: 6,
          batteryDrainPerMin: 0.05,
          seed: seed),
      AssetType.key || AssetType.item || AssetType.equipment || AssetType.generic =>
        SimProfile(kind: MotionKind.stationary, anchor: anchor, batteryDrainPerMin: 0.01, seed: seed),
      AssetType.truck => SimProfile(
          kind: MotionKind.road,
          waypoints: const ['noida50', 'ghaziabad', 'noida62'],
          minSpeed: 40,
          maxSpeed: 70,
          seed: seed),
      AssetType.delivery => SimProfile(
          kind: MotionKind.road,
          waypoints: const ['noida50', 'noida18', 'noida37'],
          minSpeed: 20,
          maxSpeed: 45,
          destinationDwell: const Duration(minutes: 2),
          seed: seed),
      AssetType.taxi => SimProfile(
          kind: MotionKind.road,
          waypoints: const ['noida50', 'noida62', 'laxmiNagar', 'cp'],
          minSpeed: 30,
          maxSpeed: 65,
          seed: seed),
      AssetType.bike => SimProfile(
          kind: MotionKind.road,
          waypoints: const ['noida50', 'noidaCityCentre', 'noida62'],
          minSpeed: 25,
          maxSpeed: 50,
          seed: seed),
      AssetType.car => SimProfile(
          kind: MotionKind.road,
          waypoints: const ['noida50', 'noida18', 'ashram', 'cp'],
          minSpeed: 30,
          maxSpeed: 70,
          seed: seed),
    };
  }
}
