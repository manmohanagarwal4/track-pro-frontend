import 'package:clock/clock.dart' as clk;
import 'dart:async';
import 'dart:math' as math;

import '../local/local_store.dart';
import '../models/alert.dart';
import '../models/asset.dart';
import '../models/device_location.dart';
import '../models/driver.dart';
import '../models/enums.dart';
import '../models/geofence.dart';
import '../models/tracker_device.dart';
import '../models/user.dart';
import '../repositories/repositories.dart';
import 'geo/ncr_geo.dart';
import 'geo/route_engine.dart';
import 'mock_seed.dart';
import 'simulation/history_generator.dart';
import 'simulation/location_simulation_service.dart';
import 'simulation/sim_profile.dart';

/// Simulated network latency and failures for mock repositories.
class MockLatency {
  MockLatency({
    this.min = const Duration(milliseconds: 250),
    this.max = const Duration(milliseconds: 750),
    this.errorsEnabled = true,
    this.errorRate = 0.08,
    int seed = 3,
  }) : _rnd = math.Random(seed);

  final Duration min;
  final Duration max;
  bool errorsEnabled;
  final double errorRate;
  final math.Random _rnd;

  static MockLatency none() =>
      MockLatency(min: Duration.zero, max: Duration.zero, errorsEnabled: false);

  Future<T> run<T>(FutureOr<T> Function() body,
      {bool canFail = false, String error = 'Unable to load data. Please try again.'}) async {
    final span = max.inMilliseconds - min.inMilliseconds;
    final ms = min.inMilliseconds + (span > 0 ? _rnd.nextInt(span) : 0);
    if (ms > 0) await Future<void>.delayed(Duration(milliseconds: ms));
    if (canFail && errorsEnabled && _rnd.nextDouble() < errorRate) {
      throw DataException(error);
    }
    return body();
  }
}

/// In-process stand-in for the tracking backend: owns all mock data,
/// persists it locally and drives the GPS simulation.
class MockBackend {
  MockBackend({
    required this.store,
    MockLatency? latency,
    DateTime Function()? clock,
    LocationSimulationService? simulation,
    RouteEngine? routes,
  })  : latency = latency ?? MockLatency(),
        clock = clock ?? clk.clock.now,
        routes = routes ?? RouteEngine() {
    this.simulation = simulation ?? LocationSimulationService(routes: this.routes, clock: this.clock);
    history = HistoryGenerator(this.routes);
  }

  static const _seedVersion = 5;

  final LocalStore store;
  final MockLatency latency;
  final DateTime Function() clock;
  final RouteEngine routes;
  late final LocationSimulationService simulation;
  late final HistoryGenerator history;

  final Map<String, TrackerDevice> devices = {};
  final Map<String, Asset> assets = {};
  final Map<String, Driver> drivers = {};
  final Map<String, Geofence> geofences = {};
  final Map<String, SimProfile> profiles = {};
  final Map<String, ShareLink> shares = {};
  List<TrackerAlert> alerts = [];
  List<AppNotification> notifications = [];
  AppUser? session;

  StreamSubscription<List<dynamic>>? _sub;
  Timer? _persistTimer;
  bool _initialized = false;
  int _idSeq = 0;

  String newId(String prefix) =>
      '$prefix-${clock().millisecondsSinceEpoch.toRadixString(36)}${(_idSeq++).toRadixString(36)}';

  void init() {
    if (_initialized) return;
    _initialized = true;
    final now = clock();
    final seed = MockSeed.build(now);
    profiles.addAll(seed.profiles);

    final stored = store.readJson('seedVersion') == _seedVersion;
    if (stored && store.readJson('devices') is List) {
      _loadFromStore();
    } else {
      _loadSeed(seed);
      persistAll();
    }
    final s = store.readJson('session');
    if (s is Map<String, dynamic>) session = AppUser.fromJson(s);

    // Register every device with the simulation.
    for (final d in devices.values.toList()) {
      _registerAgent(d, seed.telemetry[d.id]);
    }
    _seedTodayDistance();

    _sub = simulation.updates.listen((batch) {
      for (final u in batch) {
        final d = devices[u.deviceId];
        if (d == null) continue;
        devices[u.deviceId] = d.copyWith(
          connected: u.connected,
          location: u.location,
          lastSeen: u.location?.timestamp,
        );
      }
    });
    _persistTimer = Timer.periodic(const Duration(seconds: 30), (_) => _persistDevices());
  }

  void _registerAgent(TrackerDevice d, Telemetry? seedTelemetry) {
    final type = assets[d.assetId]?.type ?? AssetType.generic;
    final profile = profiles[d.id] ??
        SimProfile.forNewDevice(type, d.location?.position ?? NcrGeo.userLocation, d.id.hashCode & 0xffff);
    profiles[d.id] = profile;
    final telemetry = seedTelemetry ??
        d.location?.telemetry ??
        Telemetry(
          battery: 100,
          signal: SignalQuality.excellent,
          gpsSignal: SignalQuality.excellent,
          satellites: 12,
          temperature: 29,
          motion: false,
          ignition: type.hasIgnition ? false : null,
          fuel: type.hasFuel ? 80 : null,
        );
    simulation.register(
      deviceId: d.id,
      type: type,
      profile: profile,
      telemetry: telemetry,
      interval: d.updateInterval,
    );
    final loc = simulation.current(d.id);
    if (loc != null) {
      devices[d.id] = d.copyWith(location: loc, lastSeen: loc.timestamp, connected: true);
    } else {
      devices[d.id] = d.copyWith(connected: false);
    }
  }

  /// "Distance today" starts from today's recorded trips so it matches History.
  void _seedTodayDistance() {
    final now = clock();
    for (final d in devices.values.toList()) {
      if (d.tripDistanceKm > 0) continue;
      final profile = profiles[d.id];
      if (profile == null) continue;
      final trips = history.tripsForDay(d.id, profile, now, until: now);
      final km = trips.fold<double>(0, (a, t) => a + t.stats.distanceKm);
      if (km > 0) devices[d.id] = d.copyWith(tripDistanceKm: km);
    }
  }

  void registerNewDevice(TrackerDevice d) {
    devices[d.id] = d;
    _registerAgent(d, null);
  }

  void unregisterDevice(String id) {
    simulation.unregister(id);
    devices.remove(id);
    profiles.remove(id);
  }

  void _loadSeed(SeedData seed) {
    devices
      ..clear()
      ..addEntries(seed.devices.map((d) => MapEntry(d.id, d)));
    assets
      ..clear()
      ..addEntries(seed.assets.map((a) => MapEntry(a.id, a)));
    drivers
      ..clear()
      ..addEntries(seed.drivers.map((d) => MapEntry(d.id, d)));
    geofences
      ..clear()
      ..addEntries(seed.geofences.map((g) => MapEntry(g.id, g)));
    alerts = List.of(seed.alerts);
    notifications = List.of(seed.notifications);
    shares.clear();
  }

  void _loadFromStore() {
    List<Map<String, dynamic>> list(String key) =>
        ((store.readJson(key) as List?) ?? const []).cast<Map<String, dynamic>>();
    for (final j in list('devices')) {
      final d = TrackerDevice.fromJson(j);
      devices[d.id] = d;
    }
    for (final j in list('assets')) {
      final a = Asset.fromJson(j);
      assets[a.id] = a;
    }
    for (final j in list('drivers')) {
      final d = Driver.fromJson(j);
      drivers[d.id] = d;
    }
    for (final j in list('geofences')) {
      final g = Geofence.fromJson(j);
      geofences[g.id] = g;
    }
    for (final j in list('shares')) {
      final s = ShareLink.fromJson(j);
      shares[s.id] = s;
    }
    alerts = list('alerts').map(TrackerAlert.fromJson).toList();
    notifications = list('notifications').map(AppNotification.fromJson).toList();
  }

  void _persistDevices() =>
      store.writeJson('devices', devices.values.map((d) => d.toJson()).toList());

  void persistAll() {
    store.writeJson('seedVersion', _seedVersion);
    _persistDevices();
    persistAssets();
    persistDrivers();
    persistGeofences();
    persistAlerts();
    persistNotifications();
    persistShares();
  }

  void persistDevices() => _persistDevices();
  void persistAssets() => store.writeJson('assets', assets.values.map((a) => a.toJson()).toList());
  void persistDrivers() => store.writeJson('drivers', drivers.values.map((d) => d.toJson()).toList());
  void persistGeofences() =>
      store.writeJson('geofences', geofences.values.map((g) => g.toJson()).toList());
  void persistAlerts() => store.writeJson('alerts', alerts.map((a) => a.toJson()).toList());
  void persistNotifications() =>
      store.writeJson('notifications', notifications.map((n) => n.toJson()).toList());
  void persistShares() => store.writeJson('shares', shares.values.map((s) => s.toJson()).toList());
  void persistSession() =>
      session == null ? store.remove('session') : store.writeJson('session', session!.toJson());

  /// Wipes local data and re-seeds (Settings → Reset demo data).
  Future<void> reset() async {
    simulation.stop();
    for (final id in simulation.deviceIds.toList()) {
      simulation.unregister(id);
    }
    await store.clear(keep: {'settings', 'session'});
    final now = clock();
    final seed = MockSeed.build(now);
    profiles
      ..clear()
      ..addAll(seed.profiles);
    _loadSeed(seed);
    for (final d in devices.values.toList()) {
      _registerAgent(d, seed.telemetry[d.id]);
    }
    _seedTodayDistance();
    persistAll();
  }

  void dispose() {
    _persistDevices();
    _sub?.cancel();
    _persistTimer?.cancel();
    simulation.dispose();
  }
}
