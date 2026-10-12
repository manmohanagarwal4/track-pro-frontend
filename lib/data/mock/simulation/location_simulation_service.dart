import 'package:clock/clock.dart' as clk;
import 'dart:async';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../../core/utils/geo_utils.dart';
import '../../models/device_location.dart';
import '../../models/enums.dart';
import '../../repositories/live_location_source.dart';
import '../geo/route_engine.dart';
import 'sim_profile.dart';

/// Local GPS simulation engine.
///
/// Every device is an "agent" that moves along a route (vehicles), a wander
/// loop (pets, people) or stays put (keys, equipment). Physics advance on a
/// fixed tick; fixes are *reported* at each device's own interval, which is
/// driven by its tracking mode — exactly like a real tracker.
class LocationSimulationService implements LiveLocationSource {
  LocationSimulationService({
    RouteEngine? routes,
    DateTime Function()? clock,
    this.tick = const Duration(milliseconds: 250),
  })  : _routes = routes ?? RouteEngine(),
        _clock = clock ?? clk.clock.now;

  final RouteEngine _routes;
  final DateTime Function() _clock;
  final Duration tick;

  final Map<String, _Agent> _agents = {};
  final _controller = StreamController<List<LiveUpdate>>.broadcast();
  Timer? _timer;
  DateTime? _lastTick;
  DateTime? _pausedAt;
  double _timeScale = 1;

  @override
  Stream<List<LiveUpdate>> get updates => _controller.stream;

  @override
  bool get isRunning => _timer != null;

  double get timeScale => _timeScale;

  /// Multiplies simulated time (1x real time by default).
  void setTimeScale(double scale) => _timeScale = scale.clamp(0.5, 20);

  Iterable<String> get deviceIds => _agents.keys;

  // ---------------------------------------------------------------- devices

  void register({
    required String deviceId,
    required AssetType type,
    required SimProfile profile,
    required Telemetry telemetry,
    required Duration interval,
  }) {
    final rnd = math.Random(profile.seed);
    RoutePath? path;
    switch (profile.kind) {
      case MotionKind.road:
        path = _routes.loopThrough(profile.waypoints, seed: profile.seed);
      case MotionKind.wander:
        path = RouteEngine.wanderLoop(profile.anchor!,
            minRadius: profile.minRadius, maxRadius: profile.maxRadius, seed: profile.seed);
      case MotionKind.stationary:
      case MotionKind.offline:
        path = null;
    }
    final agent = _Agent(
      deviceId: deviceId,
      type: type,
      profile: profile,
      path: path,
      rnd: rnd,
      telemetry: telemetry,
      interval: interval,
      now: _clock(),
    );
    _agents[deviceId] = agent;
  }

  void unregister(String deviceId) => _agents.remove(deviceId);

  bool isRegistered(String deviceId) => _agents.containsKey(deviceId);

  void setInterval(String deviceId, Duration interval) {
    final a = _agents[deviceId];
    if (a == null) return;
    a.interval = interval;
    // Report promptly so the change is visible immediately.
    a.nextEmit = _clock();
  }

  /// Current simulated fix for a device (null when it has no live link).
  DeviceLocation? current(String deviceId) {
    final a = _agents[deviceId];
    if (a == null || !a.connected) return null;
    return a.toLocation(_clock());
  }

  bool isConnected(String deviceId) => _agents[deviceId]?.connected ?? false;

  @override
  Stream<DeviceLocation> watchDevice(String deviceId) => updates
      .expand((batch) => batch)
      .where((u) => u.deviceId == deviceId && u.location != null)
      .map((u) => u.location!);

  /// Spec-named alias for [watchDevice].
  Stream<DeviceLocation> simulateDeviceMovement(String deviceId) => watchDevice(deviceId);

  // -------------------------------------------------------------- lifecycle

  @override
  void start() {
    if (_timer != null) return;
    _lastTick = _clock();
    _timer = Timer.periodic(tick, (_) => step());
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
    _pausedAt = null;
  }

  @override
  void pause() {
    if (_timer == null) return;
    _timer?.cancel();
    _timer = null;
    _pausedAt = _clock();
  }

  @override
  void resume({bool catchUp = true}) {
    if (_timer != null) return;
    final pausedAt = _pausedAt;
    if (catchUp && pausedAt != null) {
      final elapsed = _clock().difference(pausedAt);
      fastForward(elapsed > const Duration(minutes: 30) ? const Duration(minutes: 30) : elapsed);
    }
    _pausedAt = null;
    start();
  }

  /// Advances all agents by [realElapsed] (scaled) without emitting per step,
  /// then emits one batch with everyone's latest position.
  void fastForward(Duration realElapsed) {
    var remaining = realElapsed.inMilliseconds / 1000 * _timeScale;
    while (remaining > 0) {
      final dt = math.min(2.0, remaining);
      for (final a in _agents.values) {
        a.advance(dt);
      }
      remaining -= dt;
    }
    final now = _clock();
    final batch = <LiveUpdate>[];
    for (final a in _agents.values) {
      a.drainConnectionChange();
      batch.add(LiveUpdate(
        deviceId: a.deviceId,
        connected: a.connected,
        location: a.connected ? a.toLocation(now) : null,
      ));
      a.nextEmit = now.add(a.interval);
    }
    if (batch.isNotEmpty && !_controller.isClosed) _controller.add(batch);
  }

  /// One simulation tick. Public so tests can drive the engine deterministically.
  void step([Duration? forcedDt]) {
    final now = _clock();
    final realDt = forcedDt ??
        (_lastTick == null ? tick : now.difference(_lastTick!));
    _lastTick = now;
    final dt = realDt.inMilliseconds / 1000 * _timeScale;

    final batch = <LiveUpdate>[];
    for (final a in _agents.values) {
      a.advance(dt);
      final change = a.drainConnectionChange();
      if (change != null) {
        batch.add(LiveUpdate(
          deviceId: a.deviceId,
          connected: change,
          location: change ? a.toLocation(now) : null,
        ));
        a.nextEmit = now.add(a.interval);
        continue;
      }
      if (a.connected && !now.isBefore(a.nextEmit)) {
        batch.add(LiveUpdate(deviceId: a.deviceId, connected: true, location: a.toLocation(now)));
        a.nextEmit = now.add(a.interval);
      }
    }
    if (batch.isNotEmpty && !_controller.isClosed) _controller.add(batch);
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

class _Agent {
  _Agent({
    required this.deviceId,
    required this.type,
    required this.profile,
    required this.path,
    required this.rnd,
    required Telemetry telemetry,
    required this.interval,
    required DateTime now,
  })  : battery = telemetry.battery.toDouble(),
        temperature = telemetry.temperature,
        fuel = telemetry.fuel,
        satellites = telemetry.satellites,
        signal = telemetry.signal,
        connected = profile.kind != MotionKind.offline,
        nextEmit = now {
    final p = path;
    if (p != null) {
      progress = p.length * profile.startFraction;
      final s = p.sample(progress);
      position = s.point;
      heading = s.heading;
    } else {
      position = profile.anchor ?? const LatLng(28.6, 77.3);
      heading = rnd.nextDouble() * 360;
    }
    dwellLeft = profile.initialDwell.inMilliseconds / 1000;
    final moving = dwellLeft <= 0 && p != null;
    speed = moving ? (profile.minSpeed + profile.maxSpeed) / 2 : 0;
    target = speed;
    ignition = type.hasIgnition && (moving || profile.ignitionWhenStopped);
    altitude = 205 + rnd.nextDouble() * 25;
  }

  final String deviceId;
  final AssetType type;
  final SimProfile profile;
  final RoutePath? path;
  final math.Random rnd;
  Duration interval;
  DateTime nextEmit;

  late LatLng position;
  late double heading;
  double progress = 0;
  late double speed;
  late double target;
  double retargetIn = 0;
  double dwellLeft = 0;
  late bool ignition;
  late double altitude;

  double battery;
  double temperature;
  double? fuel;
  int satellites;
  SignalQuality signal;

  bool connected;
  double offlineLeft = 0;
  bool? _pendingConnectionChange;

  bool? drainConnectionChange() {
    final c = _pendingConnectionChange;
    _pendingConnectionChange = null;
    return c;
  }

  double _range(double a, double b) => a + rnd.nextDouble() * (b - a);

  void advance(double dt) {
    if (dt <= 0) return;
    if (profile.kind == MotionKind.offline) return;

    if (!connected) {
      offlineLeft -= dt;
      if (offlineLeft <= 0) {
        connected = true;
        _pendingConnectionChange = true;
      }
      return;
    }

    // Random disconnections.
    if (profile.offlineFlapPerHour > 0 &&
        rnd.nextDouble() < profile.offlineFlapPerHour * dt / 3600) {
      connected = false;
      offlineLeft = _range(60, 180);
      speed = 0;
      _pendingConnectionChange = false;
      return;
    }

    battery = math.max(4, battery - profile.batteryDrainPerMin * dt / 60);
    temperature += (rnd.nextDouble() - 0.5) * 0.05 * dt;
    temperature = temperature.clamp(18, 42);
    if (rnd.nextDouble() < 0.05 * dt) {
      satellites = (satellites + rnd.nextInt(3) - 1).clamp(7, 16);
    }
    if (rnd.nextDouble() < 0.01 * dt) {
      const options = [SignalQuality.excellent, SignalQuality.good, SignalQuality.good, SignalQuality.fair];
      signal = options[rnd.nextInt(options.length)];
    }

    final p = path;
    if (p == null) {
      speed = 0;
      ignition = type.hasIgnition && profile.ignitionWhenStopped;
      return;
    }

    if (dwellLeft > 0) {
      dwellLeft -= dt;
      speed = 0;
      if (dwellLeft <= 0) ignition = type.hasIgnition;
      return;
    }

    retargetIn -= dt;
    if (retargetIn <= 0) {
      retargetIn = _range(8, 20);
      target = profile.surgeChance > 0 && rnd.nextDouble() < profile.surgeChance
          ? profile.surgeSpeed + _range(0, 10)
          : _range(profile.minSpeed, profile.maxSpeed);
    }
    speed += (target - speed) * math.min(1, dt / 4);
    final move = speed / 3.6 * dt;
    final next = progress + move;

    final stop = _firstStopBetween(p, progress, next);
    if (stop != null) {
      final travelled = (stop.distance - progress + p.length) % p.length;
      progress = stop.distance % p.length;
      _consumeFuel(travelled);
      speed = 0;
      final base = stop.isDestination ? profile.destinationDwell : profile.signalDwell;
      dwellLeft = base.inMilliseconds / 1000 * _range(0.5, 1.3);
      // Engines are often switched off at destinations, never at signals.
      if (type.hasIgnition) ignition = stop.isDestination ? rnd.nextBool() : true;
    } else {
      progress = next % p.length;
      _consumeFuel(move);
      if (type.hasIgnition) ignition = true;
    }
    final s = p.sample(progress);
    if (GeoUtils.distanceMeters(position, s.point) > 0.5) heading = s.heading;
    position = s.point;
    altitude += (rnd.nextDouble() - 0.5) * 0.4;
  }

  void _consumeFuel(double meters) {
    final f = fuel;
    if (f == null) return;
    var nf = f - meters / 1000 * 0.05;
    if (nf < 12) nf = 96; // refuelled
    fuel = nf;
  }

  RouteStop? _firstStopBetween(RoutePath p, double a, double b) {
    if (p.stops.isEmpty) return null;
    final len = p.length;
    if (b < len) {
      for (final s in p.stops) {
        if (s.distance > a && s.distance <= b) return s;
      }
      return null;
    }
    for (final s in p.stops) {
      if (s.distance > a) return s;
    }
    final wrapped = b - len;
    for (final s in p.stops) {
      if (s.distance <= wrapped) return s;
    }
    return null;
  }

  DeviceLocation toLocation(DateTime now) {
    final moving = speed > 0.5;
    var pos = position;
    final accuracy = moving ? _range(3, 6) : _range(4, 9);
    if (!moving) {
      // GPS jitter of a few meters when stationary.
      pos = GeoUtils.destination(position, rnd.nextDouble() * 360, rnd.nextDouble() * 3);
    }
    final reported = moving ? math.max(0.0, speed + (rnd.nextDouble() - 0.5) * 3) : 0.0;
    final gps = satellites >= 12
        ? SignalQuality.excellent
        : satellites >= 9
            ? SignalQuality.good
            : SignalQuality.fair;
    return DeviceLocation(
      deviceId: deviceId,
      position: pos,
      speedKmh: reported,
      heading: heading,
      altitude: altitude,
      accuracy: accuracy,
      timestamp: now,
      telemetry: Telemetry(
        battery: battery.round(),
        signal: signal,
        gpsSignal: gps,
        satellites: satellites,
        temperature: double.parse(temperature.toStringAsFixed(1)),
        motion: moving,
        ignition: type.hasIgnition ? ignition : null,
        fuel: fuel == null ? null : double.parse(fuel!.toStringAsFixed(1)),
      ),
    );
  }
}
