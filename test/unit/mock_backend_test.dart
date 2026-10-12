import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracker/core/utils/geo_utils.dart';
import 'package:tracker/data/local/local_store.dart';
import 'package:tracker/data/mock/geo/route_engine.dart';
import 'package:tracker/data/mock/mock_backend.dart';
import 'package:tracker/data/mock/mock_repositories.dart';
import 'package:tracker/data/mock/mock_seed.dart';
import 'package:tracker/data/mock/simulation/location_simulation_service.dart';
import 'package:tracker/data/mock/simulation/sim_profile.dart';
import 'package:tracker/data/models/device_location.dart';
import 'package:tracker/data/models/enums.dart';
import 'package:tracker/data/repositories/live_location_source.dart';
import 'package:tracker/data/repositories/repositories.dart';

Future<MockBackend> backend() async {
  SharedPreferences.setMockInitialValues({});
  final store = await LocalStore.open();
  return MockBackend(store: store, latency: MockLatency.none())..init();
}

const _tel = Telemetry(
  battery: 80,
  signal: SignalQuality.good,
  gpsSignal: SignalQuality.good,
  satellites: 12,
  temperature: 30,
  motion: false,
  ignition: true,
);

void main() {
  group('Mock seed', () {
    test('has the required demo devices and at least 20 devices', () {
      final seed = MockSeed.build(DateTime(2026, 1, 1, 10));
      final ids = seed.devices.map((d) => d.id).toSet();
      expect(ids, containsAll(['PET-001', 'KEY-001', 'CAR-001', 'TAXI-001', 'TRUCK-001', 'VAN-001', 'DEV-009']));
      expect(seed.devices.length, greaterThanOrEqualTo(20));
      final names = seed.assets.map((a) => a.name).toSet();
      expect(names, containsAll(['Bruno', 'House Keys', 'Car 01', 'Taxi 21', 'Truck 21', 'Delivery Van 07', 'Truck 09']));
      expect(seed.drivers.any((d) => d.name == 'Rahul Sharma'), isTrue);
      expect(seed.geofences, isNotEmpty);
      expect(seed.alerts, isNotEmpty);
    });
  });

  group('MockTrackingRepository', () {
    test('lists devices with live positions', () async {
      final b = await backend();
      final repo = MockTrackingRepository(b);
      final devices = await repo.getDevices();
      final truck = devices.firstWhere((d) => d.id == 'TRUCK-001');
      expect(truck.location, isNotNull);
      expect(truck.connected, isTrue);
      final offline = devices.firstWhere((d) => d.id == 'DEV-009');
      expect(offline.connected, isFalse);
      b.dispose();
    });

    test('verify, add, update and remove a device', () async {
      final b = await backend();
      final repo = MockTrackingRepository(b);
      expect((await repo.verifyDeviceId('TRUCK-001')).valid, isFalse);
      expect((await repo.verifyDeviceId('x')).valid, isFalse);
      expect((await repo.verifyDeviceId('demo-001')).valid, isTrue);

      final added = await repo.addDevice(const NewDeviceRequest(
          deviceId: 'DEMO-001', assetType: AssetType.pet, assetName: 'Max'));
      expect(added.device.id, 'DEMO-001');
      expect(added.asset.name, 'Max');
      expect(b.simulation.isRegistered('DEMO-001'), isTrue);
      expect((await repo.getDevice('DEMO-001'))!.location, isNotNull);

      final updated = await repo.setTrackingMode('DEMO-001', TrackingMode.powerSaving);
      expect(updated.updateInterval, const Duration(seconds: 15));
      final sos = await repo.setEmergency('DEMO-001', true);
      expect(sos.updateInterval, const Duration(seconds: 1));

      await repo.removeDevice('DEMO-001');
      expect(await repo.getDevice('DEMO-001'), isNull);
      expect(b.simulation.isRegistered('DEMO-001'), isFalse);
      b.dispose();
    });

    test('history and trips are realistic and computed from points', () async {
      final b = await backend();
      final repo = MockTrackingRepository(b);
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      final trips = await repo.getTrips('TRUCK-001', start, now);
      expect(trips, isNotEmpty);
      for (final t in trips) {
        final measured = GeoUtils.pathLengthMeters([for (final p in t.points) p.position]) / 1000;
        expect(t.stats.distanceKm, closeTo(measured, 0.01));
        expect(t.stats.maxSpeedKmh, greaterThan(t.stats.avgSpeedKmh * 0.5));
        expect(t.end.isAfter(t.start), isTrue);
      }
      final history = await repo.getLocationHistory('TRUCK-001', start, now);
      expect(history.points.length, greaterThan(10));
      expect(history.stats.distanceKm, greaterThan(5));
      // Stationary keys have no trips.
      expect(await repo.getTrips('KEY-001', start, now), isEmpty);
      b.dispose();
    });

    test('changes persist across backend restarts', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.open();
      final b1 = MockBackend(store: store, latency: MockLatency.none())..init();
      await MockTrackingRepository(b1)
          .addDevice(const NewDeviceRequest(deviceId: 'KEY-777', assetType: AssetType.key, assetName: 'Spare keys'));
      b1.dispose();
      final b2 = MockBackend(store: store, latency: MockLatency.none())..init();
      expect(b2.devices.containsKey('KEY-777'), isTrue);
      expect(b2.assets.values.any((a) => a.name == 'Spare keys'), isTrue);
      b2.dispose();
    });

    test('simulated errors surface as DataException', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.open();
      final b = MockBackend(
        store: store,
        latency: MockLatency(min: Duration.zero, max: Duration.zero, errorRate: 1),
      )..init();
      expect(MockTrackingRepository(b).getDevices(), throwsA(isA<DataException>()));
      b.dispose();
    });
  });

  group('MockDriverRepository', () {
    test('create, reject duplicates, edit and delete', () async {
      final b = await backend();
      final repo = MockDriverRepository(b);
      final before = (await repo.getDrivers()).length;
      final d = await repo.createDriver(name: 'Vikas Yadav', phone: '+91 99999 11111', licenseNo: 'dl-0420230001');
      expect(d.licenseNo, 'DL-0420230001');
      expect((await repo.getDrivers()).length, before + 1);

      // Same phone (different formatting) or same licence → rejected.
      expect(repo.createDriver(name: 'X', phone: '9999911111', licenseNo: 'NEW-123456'), throwsA(isA<DataException>()));
      expect(repo.createDriver(name: 'X', phone: '+91 88888 22222', licenseNo: 'DL 0420230001'),
          throwsA(isA<DataException>()));

      // Editing yourself is not a duplicate.
      await repo.saveDriver(d.copyWith(name: 'Vikas Kumar Yadav'));
      expect(b.drivers[d.id]!.name, 'Vikas Kumar Yadav');

      await repo.deleteDriver(d.id);
      expect((await repo.getDrivers()).length, before);
      b.dispose();
    });
  });

  group('LocationSimulationService', () {
    test('vehicles move along their route and report speed / heading', () async {
      var now = DateTime(2026, 1, 1, 9);
      final sim = LocationSimulationService(clock: () => now);
      sim.register(
        deviceId: 'T',
        type: AssetType.truck,
        profile: const SimProfile(kind: MotionKind.road, waypoints: ['cp', 'noida18'], minSpeed: 60, maxSpeed: 60),
        telemetry: _tel,
        interval: const Duration(seconds: 2),
      );
      final first = sim.current('T')!;
      final updates = <LiveUpdate>[];
      final sub = sim.updates.listen(updates.addAll);
      for (var i = 0; i < 40; i++) {
        now = now.add(const Duration(milliseconds: 500));
        sim.step(const Duration(milliseconds: 500));
      }
      await Future<void>.delayed(Duration.zero);
      final last = sim.current('T')!;
      expect(GeoUtils.distanceMeters(first.position, last.position), greaterThan(50));
      expect(updates.where((u) => u.location != null).length, inInclusiveRange(9, 11)); // every 2s over 20s
      expect(updates.last.location!.speedKmh, greaterThan(10));
      await sub.cancel();
      sim.dispose();
    });

    test('tracking interval controls report frequency', () async {
      var now = DateTime(2026, 1, 1, 9);
      final sim = LocationSimulationService(clock: () => now);
      sim.register(
        deviceId: 'K',
        type: AssetType.key,
        profile: const SimProfile(kind: MotionKind.stationary, anchor: LatLng(28.6315, 77.2167)),
        telemetry: _tel,
        interval: const Duration(seconds: 15),
      );
      var count = 0;
      final sub = sim.updates.listen((b) => count += b.length);
      for (var i = 0; i < 60; i++) {
        now = now.add(const Duration(seconds: 1));
        sim.step(const Duration(seconds: 1));
      }
      await Future<void>.delayed(Duration.zero);
      expect(count, inInclusiveRange(4, 5)); // 60s / 15s
      await sub.cancel();
      sim.dispose();
    });

    test('route engine finds a road path between hubs', () {
      final r = RouteEngine();
      final path = r.shortestPath('cp', 'ghaziabad');
      expect(path.first, 'cp');
      expect(path.last, 'ghaziabad');
      expect(path.length, greaterThan(2));
    });
  });
}
