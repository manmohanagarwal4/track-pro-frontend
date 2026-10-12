import 'dart:math' as math;

import '../models/alert.dart';
import '../models/asset.dart';
import '../models/driver.dart';
import '../models/enums.dart';
import '../models/geofence.dart';
import '../models/tracker_device.dart';
import '../models/trip.dart';
import '../models/user.dart';
import '../repositories/repositories.dart';
import 'mock_backend.dart';
import 'mock_seed.dart';
import 'simulation/sim_profile.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._b);

  final MockBackend _b;

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Future<AppUser?> restoreSession() => _b.latency.run(() => _b.session);

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      _b.latency.run(() {
        final e = email.trim().toLowerCase();
        if (!_email.hasMatch(e) || password.length < 4) {
          throw const DataException('Incorrect email or password.');
        }
        final user = e == MockSeed.demoUser.email
            ? MockSeed.demoUser
            : AppUser(
                id: 'usr-${e.hashCode.abs()}',
                name: _nameFromEmail(e),
                email: e,
                accountType: AccountType.business,
              );
        _b.session = user;
        _b.persistSession();
        return user;
      });

  @override
  Future<AppUser> signInWithDemo() => _b.latency.run(() {
        _b.session = MockSeed.demoUser;
        _b.persistSession();
        return MockSeed.demoUser;
      });

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required AccountType accountType,
  }) =>
      _b.latency.run(() {
        final user = AppUser(
          id: 'usr-${email.hashCode.abs()}',
          name: name.trim(),
          email: email.trim().toLowerCase(),
          accountType: accountType,
        );
        _b.session = user;
        _b.persistSession();
        return user;
      });

  @override
  Future<void> requestPasswordReset(String email) => _b.latency.run(() {});

  @override
  Future<AppUser> updateProfile(AppUser user) => _b.latency.run(() {
        _b.session = user;
        _b.persistSession();
        return user;
      });

  @override
  Future<void> signOut() => _b.latency.run(() {
        _b.session = null;
        _b.persistSession();
      });

  static String _nameFromEmail(String e) {
    final local = e.split('@').first.split(RegExp(r'[._-]')).where((s) => s.isNotEmpty);
    return local.map((s) => s[0].toUpperCase() + s.substring(1)).join(' ');
  }
}

class MockTrackingRepository implements TrackingRepository {
  MockTrackingRepository(this._b);

  final MockBackend _b;

  static final _idPattern = RegExp(r'^[A-Z0-9][A-Z0-9-]{3,19}$');

  @override
  Future<List<TrackerDevice>> getDevices() => _b.latency.run(
        () => _b.devices.values.toList(),
        canFail: true,
        error: 'Unable to load device data.',
      );

  @override
  Future<TrackerDevice?> getDevice(String id) =>
      _b.latency.run(() => _b.devices[id], canFail: true, error: 'Unable to load device data.');

  @override
  Future<DeviceVerification> verifyDeviceId(String deviceId) => _b.latency.run(() {
        final id = deviceId.trim().toUpperCase();
        if (!_idPattern.hasMatch(id)) {
          return const DeviceVerification(
              valid: false, message: 'Device IDs are 4–20 letters, numbers or dashes.');
        }
        if (_b.devices.containsKey(id)) {
          return const DeviceVerification(
              valid: false, message: 'This tracker is already registered to your account.');
        }
        final model = id.startsWith('PET')
            ? 'TP-Nano Pet'
            : id.startsWith('KEY') || id.startsWith('TAG')
                ? 'TP-Tag Mini'
                : 'TP-Fleet 4G';
        return DeviceVerification(valid: true, model: model);
      });

  @override
  Future<({TrackerDevice device, Asset asset})> addDevice(NewDeviceRequest r) =>
      _b.latency.run(() {
        final id = r.deviceId.trim().toUpperCase();
        if (_b.devices.containsKey(id)) {
          throw const DataException('This tracker is already registered.');
        }
        final now = _b.clock();
        final asset = Asset(
          id: _b.newId('ast'),
          name: r.assetName.trim(),
          type: r.assetType,
          categoryOverride: r.category,
          registration: r.registration?.trim().isEmpty ?? true ? null : r.registration!.trim(),
          createdAt: now,
        );
        _b.assets[asset.id] = asset;
        final rnd = math.Random(id.hashCode);
        final device = TrackerDevice(
          id: id,
          imei: '86${4000000000000 + rnd.nextInt(999999999)}',
          model: r.assetType == AssetType.pet
              ? 'TP-Nano Pet'
              : r.assetType == AssetType.key
                  ? 'TP-Tag Mini'
                  : 'TP-Fleet 4G',
          firmware: 'v2.4.1',
          addedAt: now,
          assetId: asset.id,
          trackingMode: r.assetType.isVehicle || r.assetType == AssetType.pet
              ? TrackingMode.realTime
              : TrackingMode.normal,
          alertConfig: AlertConfig(
            overspeed: r.assetType.isVehicle,
            speedLimit: r.assetType.defaultSpeedLimit,
          ),
        );
        _b.registerNewDevice(device);
        _b.persistDevices();
        _b.persistAssets();
        return (device: _b.devices[id]!, asset: asset);
      });

  @override
  Future<TrackerDevice> updateDevice(TrackerDevice device) => _b.latency.run(() {
        final existing = _b.devices[device.id];
        if (existing == null) throw const DataException('Device not found.');
        // Keep the server's latest location; clients only change configuration.
        final merged = device.copyWith(
          location: existing.location,
          lastSeen: existing.lastSeen,
          connected: existing.connected,
        );
        _b.devices[device.id] = merged;
        final typeChanged = _b.simulation.isRegistered(device.id) &&
            existing.assetId != device.assetId;
        if (typeChanged) {
          _b.profiles.remove(device.id);
          _b.simulation.unregister(device.id);
          _b.registerNewDevice(merged);
        }
        _b.simulation.setInterval(device.id, merged.updateInterval);
        _b.persistDevices();
        return _b.devices[device.id]!;
      });

  @override
  Future<void> removeDevice(String id) => _b.latency.run(() {
        _b.unregisterDevice(id);
        _b.shares.removeWhere((_, s) => s.deviceId == id);
        _b.persistDevices();
        _b.persistShares();
      });

  @override
  Future<TrackerDevice> setTrackingMode(String id, TrackingMode mode) => _b.latency.run(() {
        final d = _b.devices[id]!.copyWith(trackingMode: mode);
        _b.devices[id] = d;
        _b.simulation.setInterval(id, d.updateInterval);
        _b.persistDevices();
        return d;
      });

  @override
  Future<TrackerDevice> setEmergency(String id, bool active) =>
      _b.latency.run(() {
        final d = _b.devices[id]!.copyWith(emergency: active);
        _b.devices[id] = d;
        _b.simulation.setInterval(id, d.updateInterval);
        _b.persistDevices();
        return d;
      });

  SimProfile _profile(String deviceId) =>
      _b.profiles[deviceId] ?? const SimProfile(kind: MotionKind.stationary);

  @override
  Future<LocationHistory> getLocationHistory(String deviceId, DateTime start, DateTime end) =>
      _b.latency.run(
        () => _b.history.history(deviceId, _profile(deviceId), start, end, now: _b.clock()),
        canFail: true,
        error: 'Unable to load location history.',
      );

  @override
  Future<List<Trip>> getTrips(String deviceId, DateTime start, DateTime end) => _b.latency.run(
        () => _b.history
            .tripsBetween(deviceId, _profile(deviceId), start, end, now: _b.clock())
            .reversed
            .toList(),
        canFail: true,
        error: 'Unable to load trips.',
      );

  @override
  Future<List<Trip>> getFleetTrips(List<String> deviceIds, DateTime start, DateTime end) =>
      _b.latency.run(
        () {
          final now = _b.clock();
          final trips = [
            for (final id in deviceIds) ..._b.history.tripsBetween(id, _profile(id), start, end, now: now),
          ]..sort((a, b) => b.start.compareTo(a.start));
          return trips;
        },
        canFail: true,
        error: 'Unable to load trips.',
      );
}

class MockAssetRepository implements AssetRepository {
  MockAssetRepository(this._b);

  final MockBackend _b;

  @override
  Future<List<Asset>> getAssets() => _b.latency.run(() => _b.assets.values.toList());

  @override
  Future<Asset> saveAsset(Asset asset) => _b.latency.run(() {
        final a = asset.id.isEmpty
            ? Asset(
                id: _b.newId('ast'),
                name: asset.name,
                type: asset.type,
                registration: asset.registration,
                description: asset.description,
                createdAt: _b.clock(),
              )
            : asset;
        _b.assets[a.id] = a;
        _b.persistAssets();
        return a;
      });

  @override
  Future<void> deleteAsset(String id) => _b.latency.run(() {
        _b.assets.remove(id);
        for (final d in _b.devices.values.toList()) {
          if (d.assetId == id) _b.devices[d.id] = d.copyWith(clearAsset: true);
        }
        for (final d in _b.drivers.values.toList()) {
          if (d.assetId == id) _b.drivers[d.id] = d.copyWith(clearAsset: true);
        }
        _b.persistAssets();
        _b.persistDevices();
        _b.persistDrivers();
      });
}

class MockDriverRepository implements DriverRepository {
  MockDriverRepository(this._b);

  final MockBackend _b;

  @override
  Future<List<Driver>> getDrivers() =>
      _b.latency.run(() => _b.drivers.values.toList(), canFail: true, error: 'Unable to load drivers.');

  /// Compares Indian mobile numbers with or without the +91 prefix.
  static String _digits(String s) {
    final d = s.replaceAll(RegExp(r'\D'), '');
    return d.length > 10 ? d.substring(d.length - 10) : d;
  }
  static String _licence(String s) => s.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

  void _checkUnique(Driver d) {
    for (final other in _b.drivers.values) {
      if (other.id == d.id) continue;
      if (_digits(other.phone) == _digits(d.phone)) {
        throw DataException('${other.name} already uses this phone number.');
      }
      if (_licence(other.licenseNo) == _licence(d.licenseNo)) {
        throw DataException('${other.name} already has this licence number.');
      }
    }
  }

  @override
  Future<Driver> createDriver({
    required String name,
    required String phone,
    required String licenseNo,
  }) =>
      _b.latency.run(() {
        final driver = Driver(
          id: _b.newId('drv'),
          name: name.trim(),
          phone: phone.trim(),
          licenseNo: licenseNo.trim().toUpperCase(),
          joinedAt: _b.clock(),
          rating: 5.0,
        );
        _checkUnique(driver);
        _b.drivers[driver.id] = driver;
        _b.persistDrivers();
        return driver;
      });

  @override
  Future<Driver> saveDriver(Driver driver) => _b.latency.run(() {
        _checkUnique(driver);
        _b.drivers[driver.id] = driver;
        _b.persistDrivers();
        return driver;
      });

  @override
  Future<void> deleteDriver(String id) => _b.latency.run(() {
        _b.drivers.remove(id);
        _b.persistDrivers();
      });
}

class MockGeofenceRepository implements GeofenceRepository {
  MockGeofenceRepository(this._b);

  final MockBackend _b;

  @override
  Future<List<Geofence>> getGeofences() => _b.latency.run(() => _b.geofences.values.toList());

  @override
  Future<Geofence> saveGeofence(Geofence g) => _b.latency.run(() {
        final fence = g.id.isEmpty
            ? Geofence(
                id: _b.newId('gf'),
                name: g.name,
                type: g.type,
                center: g.center,
                radiusM: g.radiusM,
                createdAt: _b.clock(),
                notifyEnter: g.notifyEnter,
                notifyExit: g.notifyExit,
                deviceIds: g.deviceIds,
                active: g.active,
              )
            : g;
        _b.geofences[fence.id] = fence;
        _b.persistGeofences();
        return fence;
      });

  @override
  Future<void> deleteGeofence(String id) => _b.latency.run(() {
        _b.geofences.remove(id);
        _b.persistGeofences();
      });
}

class MockAlertRepository implements AlertRepository {
  MockAlertRepository(this._b);

  final MockBackend _b;

  @override
  Future<List<TrackerAlert>> getAlerts() => _b.latency.run(() => List.of(_b.alerts));

  @override
  Future<void> saveAlerts(List<TrackerAlert> alerts) async {
    _b.alerts = List.of(alerts);
    _b.persistAlerts();
  }

  @override
  Future<List<AppNotification>> getNotifications() =>
      _b.latency.run(() => List.of(_b.notifications));

  @override
  Future<void> saveNotifications(List<AppNotification> notifications) async {
    _b.notifications = List.of(notifications);
    _b.persistNotifications();
  }
}

class MockShareRepository implements ShareRepository {
  MockShareRepository(this._b);

  final MockBackend _b;
  final _rnd = math.Random();

  @override
  Future<List<ShareLink>> getShareLinks(String deviceId) => _b.latency.run(
      () => _b.shares.values.where((s) => s.deviceId == deviceId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  @override
  Future<ShareLink> createShareLink({
    required String deviceId,
    required SharePermission permission,
    required Duration duration,
  }) =>
      _b.latency.run(() {
        const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
        final token = List.generate(10, (_) => chars[_rnd.nextInt(chars.length)]).join();
        final now = _b.clock();
        final link = ShareLink(
          id: _b.newId('sh'),
          deviceId: deviceId,
          url: 'https://share.trackpro.app/t/$token',
          permission: permission,
          createdAt: now,
          expiresAt: now.add(duration),
        );
        _b.shares[link.id] = link;
        _b.persistShares();
        return link;
      });

  @override
  Future<void> revoke(String id) => _b.latency.run(() {
        _b.shares.remove(id);
        _b.persistShares();
      });
}
