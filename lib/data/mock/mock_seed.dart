import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/alert.dart';
import '../models/asset.dart';
import '../models/device_location.dart';
import '../models/driver.dart';
import '../models/enums.dart';
import '../models/geofence.dart';
import '../models/tracker_device.dart';
import '../models/user.dart';
import 'geo/ncr_geo.dart';
import 'simulation/sim_profile.dart';

/// Everything the mock backend starts with.
class SeedData {
  SeedData({
    required this.user,
    required this.devices,
    required this.assets,
    required this.profiles,
    required this.telemetry,
    required this.drivers,
    required this.geofences,
    required this.alerts,
    required this.notifications,
  });

  final AppUser user;
  final List<TrackerDevice> devices;
  final List<Asset> assets;
  final Map<String, SimProfile> profiles;
  final Map<String, Telemetry> telemetry;
  final List<Driver> drivers;
  final List<Geofence> geofences;
  final List<TrackerAlert> alerts;
  final List<AppNotification> notifications;
}

/// Mock data engine: generates the demo account's realistic dataset.
abstract final class MockSeed {
  static const demoUser = AppUser(
    id: 'usr-demo',
    name: 'Manmohan',
    email: 'demo@example.com',
    accountType: AccountType.business,
    phone: '+91 98110 45210',
  );

  static const fleetSize = 45;

  static SeedData build(DateTime now) {
    final b = _Builder(now);

    // ---------------------------------------------------------- personal
    b.add(
      id: 'PET-001', asset: 'Bruno', type: AssetType.pet, model: 'TP-Nano Pet',
      mode: TrackingMode.realTime, battery: 72, speedLimit: 30,
      profile: const SimProfile(
        kind: MotionKind.wander, anchor: NcrGeo.userLocation, minRadius: 140, maxRadius: 560,
        minSpeed: 5, maxSpeed: 10, signalDwell: Duration(seconds: 12),
        batteryDrainPerMin: 4.8, startFraction: 0.1, seed: 11),
    );
    b.add(
      id: 'KEY-001', asset: 'House Keys', type: AssetType.key, model: 'TP-Tag Mini',
      mode: TrackingMode.powerSaving, battery: 91,
      profile: const SimProfile(
          kind: MotionKind.stationary, anchor: LatLng(28.56935, 77.36428), batteryDrainPerMin: 0.01),
    );
    b.add(
      id: 'CAR-001', asset: 'Car 01', type: AssetType.car, registration: 'DL01AB1234',
      model: 'TP-Drive OBD', mode: TrackingMode.realTime, battery: 84, speedLimit: 90,
      profile: const SimProfile(
        kind: MotionKind.road, waypoints: ['noida50', 'noida18', 'ashram', 'cp'],
        minSpeed: 40, maxSpeed: 62, startFraction: 0.18, seed: 21),
    );
    b.add(
      id: 'PER-001', asset: 'Aarav', type: AssetType.person, model: 'TP-Kid Watch',
      mode: TrackingMode.normal, battery: 64, description: 'School route tracking',
      profile: const SimProfile(
        kind: MotionKind.wander, anchor: LatLng(28.5755, 77.3575), minRadius: 250,
        maxRadius: 700, minSpeed: 3, maxSpeed: 5.5, batteryDrainPerMin: 0.05, seed: 31),
    );
    b.add(
      id: 'BAG-001', asset: 'Office Bag', type: AssetType.item, model: 'TP-Tag Mini',
      mode: TrackingMode.powerSaving, battery: 17,
      profile: const SimProfile(
          kind: MotionKind.stationary, anchor: LatLng(28.6268, 77.3712), batteryDrainPerMin: 0.01),
    );
    b.add(
      id: 'BIKE-001', asset: 'Bullet 350', type: AssetType.bike, registration: 'UP16BK7781',
      model: 'TP-Moto 4G', mode: TrackingMode.normal, battery: 88,
      profile: const SimProfile(
          kind: MotionKind.stationary, anchor: LatLng(28.56880, 77.36365), batteryDrainPerMin: 0.01),
    );

    // ---------------------------------------------------------- business core
    b.add(
      id: 'TAXI-001', asset: 'Taxi 21', type: AssetType.taxi, registration: 'DL01TX0021',
      model: 'TP-Fleet 4G', mode: TrackingMode.realTime, battery: 93, driver: 'Rahul Sharma',
      profile: const SimProfile(
        kind: MotionKind.road, waypoints: ['noida62', 'noida18', 'aiims', 'airportT3'],
        minSpeed: 45, maxSpeed: 68, startFraction: 0.02, signalDwell: Duration(seconds: 15), seed: 41),
    );
    b.add(
      id: 'TRUCK-001', asset: 'Truck 21', type: AssetType.truck, registration: 'UP14TR4521',
      model: 'TP-Fleet Pro', mode: TrackingMode.realTime, battery: 84, driver: 'Amit Kumar',
      fuel: 64,
      profile: const SimProfile(
        kind: MotionKind.road, waypoints: ['saraiKaleKhan', 'ghaziabad', 'noida62', 'noida18'],
        minSpeed: 60, maxSpeed: 76, surgeChance: 0.18, surgeSpeed: 86, startFraction: 0.08,
        signalDwell: Duration(seconds: 15), seed: 51),
    );
    b.add(
      id: 'VAN-001', asset: 'Delivery Van 07', type: AssetType.delivery, registration: 'DL1LV0707',
      model: 'TP-Fleet 4G', mode: TrackingMode.normal, battery: 79, driver: 'Suresh Yadav', fuel: 48,
      profile: const SimProfile(
        kind: MotionKind.road, waypoints: ['noida18', 'noida37', 'noidaCityCentre'],
        minSpeed: 22, maxSpeed: 42, destinationDwell: Duration(minutes: 4),
        initialDwell: Duration(minutes: 3), ignitionWhenStopped: true, seed: 61),
      ignitionWhileStopped: true,
    );
    b.add(
      id: 'DEV-009', asset: 'Truck 09', type: AssetType.truck, registration: 'UP13TR0909',
      model: 'TP-Fleet Pro', mode: TrackingMode.normal, battery: 38, driver: 'Vikram Singh', fuel: 22,
      lastSeenAgo: const Duration(minutes: 18),
      offlineAt: const LatLng(28.4880, 77.6420),
      profile: const SimProfile(
          kind: MotionKind.offline, waypoints: ['ghaziabad', 'dadri', 'bulandshahr'], minSpeed: 45,
          maxSpeed: 65, seed: 71),
    );
    b.add(
      id: 'EQP-001', asset: 'Generator G-12', type: AssetType.equipment, model: 'TP-Asset Solar',
      mode: TrackingMode.sleep, battery: 97, description: 'Diesel generator, 125 kVA',
      profile: const SimProfile(kind: MotionKind.stationary, anchor: LatLng(28.6574, 77.4560)),
    );
    // A spare tracker not yet assigned to any asset.
    b.add(
      id: 'TRK-0042', type: AssetType.generic, model: 'TP-Fleet 4G', mode: TrackingMode.sleep,
      battery: 100,
      profile: const SimProfile(kind: MotionKind.stationary, anchor: LatLng(28.6548, 77.4528)),
    );

    // ---------------------------------------------------------- fleet
    _fleet(b);

    // ---------------------------------------------------------- drivers
    final drivers = _drivers(b);

    return SeedData(
      user: demoUser,
      devices: b.devices,
      assets: b.assets,
      profiles: b.profiles,
      telemetry: b.telemetry,
      drivers: drivers,
      geofences: _geofences(now),
      alerts: _alerts(now, b),
      notifications: _notifications(now),
    );
  }

  static const _hubs = [
    'cp', 'noida18', 'noida62', 'ghaziabad', 'cyberCity', 'airportT3', 'dwarka', 'faridabad',
    'pariChowk', 'dadri', 'hapur', 'bulandshahr', 'rohini', 'saket', 'kashmereGate', 'manesar',
    'indirapuram', 'laxmiNagar', 'huda', 'sikandrabad', 'noida37', 'mayurVihar', 'karolBagh',
  ];

  static void _fleet(_Builder b) {
    final rnd = math.Random(2024);
    const kinds = [AssetType.truck, AssetType.taxi, AssetType.delivery, AssetType.car];
    final counters = {for (final k in kinds) k: 0};
    const states = 'MHUDGKRP';
    for (var i = 0; i < fleetSize; i++) {
      final type = kinds[i % 4 == 3 && rnd.nextBool() ? 3 : rnd.nextInt(3)];
      counters[type] = counters[type]! + 1;
      final n = counters[type]!;
      final name = switch (type) {
        AssetType.truck => 'Truck ${_pad(n == 21 || n == 9 ? n + 30 : n)}',
        AssetType.taxi => 'Taxi ${_pad(n == 21 ? 51 : n)}',
        AssetType.delivery => 'Van ${_pad(n == 7 ? 57 : n)}',
        _ => 'Fleet Car ${_pad(n + 1)}',
      };
      final state = ['DL', 'UP', 'HR'][rnd.nextInt(3)];
      final reg = '$state${(1 + rnd.nextInt(16)).toString().padLeft(2, '0')}'
          '${states[rnd.nextInt(states.length)]}${String.fromCharCode(65 + rnd.nextInt(26))}'
          '${(1000 + rnd.nextInt(8999))}';
      final roll = rnd.nextDouble();
      final SimProfile profile;
      Duration? lastSeen;
      LatLng? offlineAt;
      final hubA = _hubs[rnd.nextInt(_hubs.length)];
      var hubB = _hubs[rnd.nextInt(_hubs.length)];
      if (hubB == hubA) hubB = _hubs[(_hubs.indexOf(hubA) + 3) % _hubs.length];
      final speeds = switch (type) {
        AssetType.truck => (45.0, 72.0),
        AssetType.taxi => (30.0, 65.0),
        AssetType.delivery => (20.0, 45.0),
        _ => (35.0, 70.0),
      };
      if (roll < 0.07) {
        profile = SimProfile(kind: MotionKind.offline, waypoints: [hubA, hubB], seed: 1000 + i);
        lastSeen = Duration(minutes: 20 + rnd.nextInt(300));
        offlineAt = NcrGeo.placeById[hubA]!.point;
      } else if (roll < 0.19) {
        profile = SimProfile(
            kind: MotionKind.stationary,
            anchor: NcrGeo.placeById[hubA]!.point,
            ignitionWhenStopped: false,
            waypoints: const [],
            seed: 1000 + i);
      } else if (roll < 0.27) {
        profile = SimProfile(
            kind: MotionKind.stationary,
            anchor: NcrGeo.placeById[hubA]!.point,
            ignitionWhenStopped: true,
            seed: 1000 + i);
      } else {
        profile = SimProfile(
          kind: MotionKind.road,
          waypoints: [hubA, hubB],
          minSpeed: speeds.$1,
          maxSpeed: speeds.$2,
          startFraction: rnd.nextDouble(),
          destinationDwell: Duration(seconds: 60 + rnd.nextInt(180)),
          initialDwell: rnd.nextDouble() < 0.25 ? Duration(seconds: 20 + rnd.nextInt(120)) : Duration.zero,
          ignitionWhenStopped: rnd.nextBool(),
          offlineFlapPerHour: 0.25,
          seed: 1000 + i,
        );
      }
      b.add(
        id: 'FLT-${(i + 1).toString().padLeft(3, '0')}',
        asset: name,
        type: type,
        registration: reg,
        model: type == AssetType.truck ? 'TP-Fleet Pro' : 'TP-Fleet 4G',
        mode: TrackingMode.normal,
        battery: 55 + rnd.nextInt(45),
        fuel: type.hasFuel ? 20 + rnd.nextInt(75).toDouble() : null,
        profile: profile,
        lastSeenAgo: lastSeen,
        offlineAt: offlineAt,
        ignitionWhileStopped: profile.ignitionWhenStopped,
        category: AssetCategory.business,
      );
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static const _driverNames = [
    'Pooja Verma', 'Imran Khan', 'Deepak Chauhan', 'Sanjay Gupta', 'Ravi Patel', 'Manoj Tiwari',
    'Anil Mehta', 'Karan Malhotra', 'Neha Joshi', 'Arjun Reddy', 'Farhan Ali', 'Gurpreet Singh',
    'Rakesh Pandey', 'Vijay Nair', 'Sunil Rawat', 'Mohit Saini',
  ];

  static List<Driver> _drivers(_Builder b) {
    final rnd = math.Random(77);
    final drivers = <Driver>[];
    var idx = 0;
    Driver make(String name, String? assetId) {
      idx++;
      return Driver(
        id: 'drv-${idx.toString().padLeft(3, '0')}',
        name: name,
        phone: '+91 9${(800000000 + rnd.nextInt(199999999)).toString().substring(0, 4)} '
            '${(10000 + rnd.nextInt(89999))}',
        licenseNo: 'DL-${(10 + rnd.nextInt(80))}20${(10 + rnd.nextInt(14))}${(1000000 + rnd.nextInt(8999999))}',
        joinedAt: DateTime(2021 + rnd.nextInt(4), 1 + rnd.nextInt(12), 1 + rnd.nextInt(27)),
        assetId: assetId,
        rating: 4.1 + rnd.nextInt(9) / 10,
        tripsCount: 40 + rnd.nextInt(900),
      );
    }

    for (final e in b.driverByAsset.entries) {
      drivers.add(make(e.value, e.key));
    }
    // Assign generated drivers to the first fleet vehicles, keep a few off duty.
    final fleetAssets = b.assets.where((a) => a.id.startsWith('ast-FLT')).toList();
    for (var i = 0; i < _driverNames.length; i++) {
      final assetId = i < 12 && i < fleetAssets.length ? fleetAssets[i * 2].id : null;
      drivers.add(make(_driverNames[i], assetId));
    }
    // Spec example: Rahul Sharma has 12 trips.
    drivers[0] = Driver(
      id: drivers[0].id,
      name: drivers[0].name,
      phone: drivers[0].phone,
      licenseNo: drivers[0].licenseNo,
      joinedAt: drivers[0].joinedAt,
      assetId: drivers[0].assetId,
      rating: 4.8,
      tripsCount: 12,
    );
    return drivers;
  }

  static List<Geofence> _geofences(DateTime now) => [
        Geofence(
          id: 'gf-home', name: 'Home Safe Zone', type: GeofenceType.home,
          center: NcrGeo.userLocation, radiusM: 350, createdAt: now.subtract(const Duration(days: 40)),
          deviceIds: const ['PET-001', 'PER-001'],
        ),
        Geofence(
          id: 'gf-office', name: 'Office Zone', type: GeofenceType.office,
          center: NcrGeo.placeById['noida62']!.point, radiusM: 700,
          createdAt: now.subtract(const Duration(days: 30)), deviceIds: const ['TAXI-001'],
        ),
        Geofence(
          id: 'gf-warehouse', name: 'Ghaziabad Warehouse', type: GeofenceType.warehouse,
          center: NcrGeo.placeById['ghaziabad']!.point, radiusM: 900,
          createdAt: now.subtract(const Duration(days: 60)), deviceIds: const ['TRUCK-001', 'DEV-009'],
        ),
        Geofence(
          id: 'gf-mall', name: 'Sector 18 Customer Hub', type: GeofenceType.customer,
          center: NcrGeo.placeById['noida18']!.point, radiusM: 500,
          createdAt: now.subtract(const Duration(days: 12)), deviceIds: const ['VAN-001'],
        ),
        Geofence(
          id: 'gf-cp', name: 'CP Office', type: GeofenceType.office,
          center: NcrGeo.placeById['cp']!.point, radiusM: 600,
          createdAt: now.subtract(const Duration(days: 8)), deviceIds: const ['CAR-001'],
        ),
        Geofence(
          id: 'gf-airport', name: 'Airport Cargo (Restricted)', type: GeofenceType.restricted,
          center: const LatLng(28.5530, 77.1080), radiusM: 600,
          createdAt: now.subtract(const Duration(days: 20)), deviceIds: const ['TAXI-001'],
          notifyExit: false,
        ),
      ];

  static List<TrackerAlert> _alerts(DateTime now, _Builder b) {
    TrackerAlert a(String id, AlertType type, AlertSeverity sev, String deviceId, String name,
            String title, String msg, Duration ago, {String? value, bool read = false}) =>
        TrackerAlert(
          id: 'seed-$id', type: type, severity: sev, deviceId: deviceId, deviceName: name,
          title: title, message: msg, timestamp: now.subtract(ago), value: value, read: read,
          position: b.positionOf(deviceId),
        );
    return [
      a('1', AlertType.overspeed, AlertSeverity.critical, 'TRUCK-001', 'Truck 21', 'Overspeed',
          'Truck 21 exceeded 80 km/h.', const Duration(minutes: 2), value: '94 km/h'),
      a('2', AlertType.geofenceExit, AlertSeverity.warning, 'TAXI-001', 'Taxi 21', 'Geofence Exit',
          'Taxi 21 exited Office Zone.', const Duration(minutes: 10)),
      a('3', AlertType.lowBattery, AlertSeverity.warning, 'BAG-001', 'Office Bag', 'Low Battery',
          'Office Bag battery below 20%.', const Duration(minutes: 18), value: '17%', read: true),
      a('4', AlertType.offline, AlertSeverity.warning, 'DEV-009', 'Truck 09', 'Device Offline',
          'Truck 09 has gone offline.', const Duration(minutes: 13), read: true),
      a('5', AlertType.geofenceEnter, AlertSeverity.warning, 'TRUCK-001', 'Truck 21', 'Geofence Enter',
          'Truck 21 entered Ghaziabad Warehouse.', const Duration(hours: 3, minutes: 12), read: true),
      a('6', AlertType.overspeed, AlertSeverity.critical, 'TAXI-001', 'Taxi 21', 'Overspeed',
          'Taxi 21 exceeded 80 km/h.', const Duration(hours: 5, minutes: 40), value: '86 km/h', read: true),
      a('7', AlertType.geofenceExit, AlertSeverity.warning, 'PET-001', 'Bruno', 'Geofence Exit',
          'Bruno exited Home Safe Zone.', const Duration(hours: 22), read: true),
      a('8', AlertType.emergency, AlertSeverity.critical, 'PER-001', 'Aarav', 'Emergency',
          'SOS pressed on Aarav. Resolved by Manmohan.', const Duration(days: 2, hours: 4), read: true),
    ];
  }

  static List<AppNotification> _notifications(DateTime now) => [
        AppNotification(
            id: 'n-1', category: NotificationCategory.trips, title: 'Trip completed',
            body: 'Truck 21 completed Ghaziabad → Noida · 48.6 km in 1h 42m.',
            timestamp: now.subtract(const Duration(minutes: 34)), deviceId: 'TRUCK-001'),
        AppNotification(
            id: 'n-2', category: NotificationCategory.devices, title: 'Firmware update available',
            body: 'TP-Fleet Pro v2.4.1 improves GPS cold-start time. 14 trackers eligible.',
            timestamp: now.subtract(const Duration(hours: 2))),
        AppNotification(
            id: 'n-3', category: NotificationCategory.system, title: 'Weekly fleet report ready',
            body: 'Your fleet covered 6,482 km last week, 4% more than the week before.',
            timestamp: now.subtract(const Duration(hours: 9)), read: true),
        AppNotification(
            id: 'n-4', category: NotificationCategory.devices, title: 'Tracker connected',
            body: 'TRK-0042 is online and ready to be assigned to an asset.',
            timestamp: now.subtract(const Duration(days: 1)), deviceId: 'TRK-0042', read: true),
        AppNotification(
            id: 'n-5', category: NotificationCategory.system, title: 'Welcome to TrackPro',
            body: 'Demo mode is on. All devices, locations and events are simulated locally.',
            timestamp: now.subtract(const Duration(days: 3)), read: true),
      ];
}

class _Builder {
  _Builder(this.now);

  final DateTime now;
  final devices = <TrackerDevice>[];
  final assets = <Asset>[];
  final profiles = <String, SimProfile>{};
  final telemetry = <String, Telemetry>{};
  final driverByAsset = <String, String>{};
  final _offlinePositions = <String, LatLng>{};
  final _rnd = math.Random(5);

  LatLng? positionOf(String deviceId) => _offlinePositions[deviceId] ?? profiles[deviceId]?.anchor;

  void add({
    required String id,
    required AssetType type,
    required String model,
    required TrackingMode mode,
    required int battery,
    required SimProfile profile,
    String? asset,
    String? registration,
    String? description,
    String? driver,
    double? fuel,
    double? speedLimit,
    Duration? lastSeenAgo,
    LatLng? offlineAt,
    bool ignitionWhileStopped = false,
    AssetCategory? category,
  }) {
    String? assetId;
    if (asset != null) {
      assetId = 'ast-$id';
      assets.add(Asset(
        id: assetId,
        name: asset,
        type: type,
        registration: registration,
        description: description,
        categoryOverride: category,
        createdAt: now.subtract(Duration(days: 30 + _rnd.nextInt(300))),
      ));
      if (driver != null) driverByAsset[assetId] = driver;
    }
    final tel = Telemetry(
      battery: battery,
      signal: SignalQuality.excellent,
      gpsSignal: SignalQuality.excellent,
      satellites: 10 + _rnd.nextInt(6),
      temperature: 27 + _rnd.nextInt(6).toDouble(),
      motion: false,
      ignition: type.hasIgnition ? ignitionWhileStopped : null,
      fuel: type.hasFuel ? (fuel ?? 70) : null,
    );
    telemetry[id] = tel;
    profiles[id] = profile;

    DeviceLocation? location;
    DateTime? lastSeen;
    if (lastSeenAgo != null && offlineAt != null) {
      lastSeen = now.subtract(lastSeenAgo);
      _offlinePositions[id] = offlineAt;
      location = DeviceLocation(
        deviceId: id,
        position: offlineAt,
        speedKmh: 0,
        heading: 90,
        altitude: 205,
        accuracy: 8,
        timestamp: lastSeen,
        telemetry: tel.copyWith(signal: SignalQuality.none, ignition: false),
      );
    }
    devices.add(TrackerDevice(
      id: id,
      imei: '86${(4000000000000 + _rnd.nextInt(999999999)).toString()}',
      model: model,
      firmware: model.contains('Pro') ? 'v2.3.8' : 'v1.9.4',
      addedAt: now.subtract(Duration(days: 20 + _rnd.nextInt(400))),
      assetId: assetId,
      trackingMode: mode,
      alertConfig: AlertConfig(
        speedLimit: speedLimit ?? type.defaultSpeedLimit,
        overspeed: type.isVehicle,
      ),
      connected: profile.kind != MotionKind.offline,
      location: location,
      lastSeen: lastSeen,
      tripDistanceKm: 0,
      odometerKm: type.isVehicle ? 12000 + _rnd.nextInt(140000).toDouble() : 0,
    ));
  }
}
