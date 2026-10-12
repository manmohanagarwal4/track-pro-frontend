import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tracker/core/utils/geo_utils.dart';
import 'package:tracker/data/models/asset.dart';
import 'package:tracker/data/models/device_location.dart';
import 'package:tracker/data/models/driver.dart';
import 'package:tracker/data/models/enums.dart';
import 'package:tracker/data/models/geofence.dart';
import 'package:tracker/data/models/tracker_device.dart';
import 'package:tracker/domain/alert_rules_engine.dart';
import 'package:tracker/domain/device_query.dart';
import 'package:tracker/domain/device_status_engine.dart';
import 'package:tracker/domain/device_view.dart';
import 'package:tracker/domain/geofence_engine.dart';
import 'package:tracker/domain/trip_calculator.dart';

const cp = LatLng(28.6315, 77.2167); // Connaught Place
const noida18 = LatLng(28.5708, 77.3261);

Telemetry tel({int battery = 80, bool ignition = true, SignalQuality gps = SignalQuality.good}) => Telemetry(
      battery: battery,
      signal: SignalQuality.good,
      gpsSignal: gps,
      satellites: 12,
      temperature: 30,
      motion: true,
      ignition: ignition,
    );

TrackerDevice device({
  String id = 'TRK-1',
  double speed = 0,
  int battery = 80,
  bool ignition = true,
  bool connected = true,
  bool emergency = false,
  LatLng pos = cp,
  DateTime? at,
  String? assetId = 'a1',
}) {
  final now = at ?? DateTime(2026, 1, 1, 12);
  return TrackerDevice(
    id: id,
    imei: '1',
    model: 'm',
    firmware: 'f',
    addedAt: DateTime(2025),
    assetId: assetId,
    connected: connected,
    emergency: emergency,
    lastSeen: now,
    location: DeviceLocation(
      deviceId: id,
      position: pos,
      speedKmh: speed,
      heading: 0,
      altitude: 200,
      accuracy: 5,
      timestamp: now,
      telemetry: tel(battery: battery, ignition: ignition),
    ),
  );
}

DeviceView view(TrackerDevice d, {AssetType type = AssetType.truck, String name = 'Truck 21', Driver? driver}) =>
    DeviceView(
      device: d,
      asset: Asset(id: 'a1', name: name, type: type, createdAt: DateTime(2025), registration: 'UP14TR4521'),
      driver: driver,
      status: DeviceStatusEngine.evaluate(d, type, now: d.lastSeen!),
    );

void main() {
  group('GeoUtils', () {
    test('haversine distance CP → Noida Sector 18 is ~13 km', () {
      final km = GeoUtils.distanceKm(cp, noida18);
      expect(km, closeTo(13.5, 1.0));
    });

    test('distance is symmetric and zero for same point', () {
      expect(GeoUtils.distanceMeters(cp, noida18), closeTo(GeoUtils.distanceMeters(noida18, cp), 1e-6));
      expect(GeoUtils.distanceMeters(cp, cp), 0);
    });

    test('1 degree of latitude is ~111.2 km', () {
      expect(GeoUtils.distanceKm(const LatLng(28, 77), const LatLng(29, 77)), closeTo(111.2, 0.3));
    });

    test('bearing and compass', () {
      expect(GeoUtils.bearing(const LatLng(28, 77), const LatLng(29, 77)), closeTo(0, 0.01));
      expect(GeoUtils.bearing(const LatLng(28, 77), const LatLng(28, 78)), closeTo(90, 0.5));
      expect(GeoUtils.compass(45), 'NE');
      expect(GeoUtils.compass(350), 'N');
      expect(GeoUtils.compass(200), 'S');
    });

    test('destination round-trips distance and bearing', () {
      final p = GeoUtils.destination(cp, 60, 2500);
      expect(GeoUtils.distanceMeters(cp, p), closeTo(2500, 1));
      expect(GeoUtils.bearing(cp, p), closeTo(60, 0.5));
    });

    test('speed calculation from two timed points', () {
      final a = DateTime(2026, 1, 1, 10);
      final b = a.add(const Duration(hours: 1));
      final p2 = GeoUtils.destination(cp, 90, 60000);
      expect(GeoUtils.speedKmh(cp, a, p2, b), closeTo(60, 0.1));
    });

    test('densify keeps the path length and limits segment size', () {
      final pts = GeoUtils.densify([cp, noida18], 500);
      expect(GeoUtils.pathLengthMeters(pts), closeTo(GeoUtils.distanceMeters(cp, noida18), 5));
      for (var i = 1; i < pts.length; i++) {
        expect(GeoUtils.distanceMeters(pts[i - 1], pts[i]), lessThanOrEqualTo(501));
      }
    });
  });

  group('DeviceStatusEngine', () {
    final now = DateTime(2026, 1, 1, 12);

    test('moving vehicle', () {
      final s = DeviceStatusEngine.evaluate(device(speed: 60), AssetType.truck, now: now);
      expect(s.primary, DeviceStatus.moving);
      expect(s.isOnline, isTrue);
    });

    test('vehicle with ignition on is idle, off is stopped', () {
      expect(DeviceStatusEngine.evaluate(device(ignition: true), AssetType.truck, now: now).primary, DeviceStatus.idle);
      expect(DeviceStatusEngine.evaluate(device(ignition: false), AssetType.truck, now: now).primary, DeviceStatus.stopped);
    });

    test('non-vehicle at rest is stationary', () {
      expect(DeviceStatusEngine.evaluate(device(), AssetType.key, now: now).primary, DeviceStatus.stationary);
    });

    test('disconnected or stale device is offline', () {
      expect(DeviceStatusEngine.evaluate(device(connected: false), AssetType.truck, now: now).primary,
          DeviceStatus.offline);
      final stale = now.add(const Duration(minutes: 10));
      expect(DeviceStatusEngine.evaluate(device(), AssetType.truck, now: stale).primary, DeviceStatus.offline);
    });

    test('emergency wins over everything', () {
      final s = DeviceStatusEngine.evaluate(device(emergency: true, connected: false), AssetType.pet, now: now);
      expect(s.primary, DeviceStatus.emergency);
      expect(s.effective, DeviceStatus.emergency);
    });

    test('low battery is a warning on top of the primary status', () {
      final s = DeviceStatusEngine.evaluate(device(speed: 40, battery: 12), AssetType.car, now: now);
      expect(s.primary, DeviceStatus.moving);
      expect(s.warnings, contains(DeviceStatus.lowBattery));
      expect(s.effective, DeviceStatus.lowBattery);
      expect(DeviceStatusEngine.matchesFilter(s, StatusFilter.alert), isTrue);
      expect(DeviceStatusEngine.matchesFilter(s, StatusFilter.moving), isTrue);
    });
  });

  group('GeofenceEngine', () {
    final fence = Geofence(
      id: 'g1',
      name: 'Home',
      type: GeofenceType.home,
      center: cp,
      radiusM: 500,
      createdAt: DateTime(2025),
    );

    test('first observation is silent, crossings produce ENTER / EXIT', () {
      final e = GeofenceEngine();
      final t = DateTime(2026);
      final outside = GeoUtils.destination(cp, 0, 900);
      final inside = GeoUtils.destination(cp, 0, 200);
      expect(e.evaluate(deviceId: 'd', position: outside, timestamp: t, geofences: [fence]), isEmpty);
      final enter = e.evaluate(deviceId: 'd', position: inside, timestamp: t, geofences: [fence]);
      expect(enter.single.type, GeofenceEventType.enter);
      expect(e.evaluate(deviceId: 'd', position: inside, timestamp: t, geofences: [fence]), isEmpty);
      final exit = e.evaluate(deviceId: 'd', position: outside, timestamp: t, geofences: [fence]);
      expect(exit.single.type, GeofenceEventType.exit);
    });

    test('respects device assignment and active flag', () {
      final e = GeofenceEngine();
      final only = fence.copyWith(deviceIds: ['other']);
      final off = fence.copyWith(active: false);
      final t = DateTime(2026);
      for (final p in [GeoUtils.destination(cp, 0, 900), cp]) {
        expect(e.evaluate(deviceId: 'd', position: p, timestamp: t, geofences: [only, off]), isEmpty);
      }
    });
  });

  group('TripCalculator', () {
    test('computes distance, duration, speeds and stops from points', () {
      final start = DateTime(2026, 1, 1, 8);
      final pts = <TrackPoint>[];
      var pos = cp;
      var t = start;
      // 10 minutes at 60 km/h (1 km per minute)
      for (var i = 0; i <= 10; i++) {
        pts.add(TrackPoint(pos, t, i == 0 ? 0 : 60));
        pos = GeoUtils.destination(pos, 90, 1000);
        t = t.add(const Duration(minutes: 1));
      }
      pos = pts.last.position;
      t = pts.last.timestamp;
      // 3-minute stop
      for (var i = 0; i < 3; i++) {
        t = t.add(const Duration(minutes: 1));
        pts.add(TrackPoint(pos, t, 0));
      }
      // 5 more minutes at 72 km/h (1.2 km per minute)
      for (var i = 0; i < 5; i++) {
        pos = GeoUtils.destination(pos, 90, 1200);
        t = t.add(const Duration(minutes: 1));
        pts.add(TrackPoint(pos, t, 72));
      }

      final s = TripCalculator.compute(pts);
      expect(s.distanceKm, closeTo(16, 0.1));
      expect(s.duration, const Duration(minutes: 18));
      expect(s.maxSpeedKmh, 72);
      expect(s.stops, 1);
      expect(s.idleTime, const Duration(minutes: 3));
      expect(s.avgSpeedKmh, closeTo(16 / (15 / 60), 1)); // over moving time
    });

    test('empty / single point trips are zero', () {
      expect(TripCalculator.compute(const []).distanceKm, 0);
      expect(TripCalculator.compute([TrackPoint(cp, DateTime(2026), 0)]).duration, Duration.zero);
    });
  });

  group('DeviceQuery (search / filter / sort)', () {
    final now = DateTime(2026, 1, 1, 12);
    final truck = view(device(id: 'TRUCK-001', speed: 68, at: now),
        driver: Driver(id: 'd', name: 'Amit Kumar', phone: '', licenseNo: '', joinedAt: DateTime(2020), assetId: 'a1'));
    final pet = DeviceView(
      device: device(id: 'PET-001', speed: 0, at: now, assetId: 'p'),
      asset: Asset(id: 'p', name: 'Bruno', type: AssetType.pet, createdAt: DateTime(2025)),
      status: const StatusSnapshot(DeviceStatus.stationary),
    );
    final offline = DeviceView(
      device: device(id: 'DEV-009', connected: false, at: now, assetId: 'o'),
      asset: Asset(id: 'o', name: 'Truck 09', type: AssetType.truck, createdAt: DateTime(2025)),
      status: const StatusSnapshot(DeviceStatus.offline),
    );
    final all = [pet, offline, truck];

    test('search matches name, id, plate, driver and pet name', () {
      expect(const DeviceQuery(text: 'truck 21').apply(all).single.id, 'TRUCK-001');
      expect(const DeviceQuery(text: 'truck-001').apply(all).single.id, 'TRUCK-001');
      expect(const DeviceQuery(text: 'up14tr').apply(all).single.id, 'TRUCK-001');
      expect(const DeviceQuery(text: 'amit').apply(all).single.id, 'TRUCK-001');
      expect(const DeviceQuery(text: 'bruno').apply(all).single.id, 'PET-001');
      expect(const DeviceQuery(text: 'zzz').apply(all), isEmpty);
    });

    test('status and asset filters', () {
      expect(const DeviceQuery(status: StatusFilter.offline).apply(all).single.id, 'DEV-009');
      expect(const DeviceQuery(status: StatusFilter.moving).apply(all).single.id, 'TRUCK-001');
      expect(const DeviceQuery(asset: AssetFilter.pet).apply(all).single.id, 'PET-001');
      expect(const DeviceQuery(asset: AssetFilter.truck).apply(all).length, 2);
    });

    test('sorting', () {
      expect(const DeviceQuery(sort: DeviceSort.name).apply(all).map((v) => v.name).toList(),
          ['Bruno', 'Truck 09', 'Truck 21']);
      expect(const DeviceQuery(sort: DeviceSort.speed).apply(all).first.id, 'TRUCK-001');
      expect(const DeviceQuery(sort: DeviceSort.status).apply(all).last.id, 'DEV-009');
    });
  });

  group('AlertRulesEngine', () {
    final now = DateTime(2026, 1, 1, 12);

    test('overspeed fires once per cooldown', () {
      final rules = AlertRulesEngine();
      final prev = view(device(speed: 70, at: now));
      final fast = view(device(speed: 94, at: now));
      final a = rules.evaluate(previous: prev, current: fast, now: now);
      expect(a.single.type, AlertType.overspeed);
      expect(a.single.message, 'Truck 21 exceeded 80 km/h.');
      expect(a.single.value, '94 km/h');
      expect(rules.evaluate(previous: fast, current: fast, now: now.add(const Duration(seconds: 30))), isEmpty);
      expect(rules.evaluate(previous: fast, current: fast, now: now.add(const Duration(minutes: 4))), hasLength(1));
    });

    test('low battery fires on crossing 20%', () {
      final rules = AlertRulesEngine();
      final a = rules.evaluate(
        previous: view(device(battery: 21, at: now), type: AssetType.pet, name: 'Bruno'),
        current: view(device(battery: 20, at: now), type: AssetType.pet, name: 'Bruno'),
        now: now,
      );
      expect(a.single.type, AlertType.lowBattery);
      expect(a.single.message, 'Bruno battery below 20%.');
    });

    test('offline transition and geofence events produce alerts', () {
      final rules = AlertRulesEngine();
      final off = rules.evaluate(
        previous: view(device(at: now)),
        current: view(device(connected: false, at: now)),
        now: now,
      );
      expect(off.single.type, AlertType.offline);

      final fence = Geofence(
          id: 'g', name: 'Office Zone', type: GeofenceType.office, center: cp, radiusM: 100, createdAt: now);
      final geo = rules.evaluate(
        previous: view(device(at: now)),
        current: view(device(at: now)),
        geofenceEvents: [
          GeofenceEvent(deviceId: 'TRK-1', geofence: fence, type: GeofenceEventType.exit, position: cp, timestamp: now),
        ],
        now: now,
      );
      expect(geo.single.type, AlertType.geofenceExit);
      expect(geo.single.message, 'Truck 21 exited Office Zone.');
    });
  });
}
