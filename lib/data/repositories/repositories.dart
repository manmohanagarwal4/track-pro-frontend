/// Repository contracts. The UI and state layers depend ONLY on these.
///
/// Today they are implemented by `Mock*Repository` classes backed by local
/// dummy data. A future `Api*Repository` implementation can replace them
/// without touching presentation code.
library;

import '../models/alert.dart';
import '../models/asset.dart';
import '../models/driver.dart';
import '../models/enums.dart';
import '../models/geofence.dart';
import '../models/tracker_device.dart';
import '../models/trip.dart';
import '../models/user.dart';

/// Thrown for recoverable data-access failures (shown with a Retry action).
class DataException implements Exception {
  const DataException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  Future<AppUser?> restoreSession();
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signInWithDemo();
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required AccountType accountType,
  });
  Future<void> requestPasswordReset(String email);
  Future<AppUser> updateProfile(AppUser user);
  Future<void> signOut();
}

class NewDeviceRequest {
  const NewDeviceRequest({
    required this.deviceId,
    required this.assetType,
    required this.assetName,
    this.registration,
    this.category,
  });

  final String deviceId;
  final AssetType assetType;
  final String assetName;
  final String? registration;

  /// Workspace for the new asset (defaults from the asset type).
  final AssetCategory? category;
}

class DeviceVerification {
  const DeviceVerification({required this.valid, this.model, this.message});

  final bool valid;
  final String? model;
  final String? message;
}

abstract interface class TrackingRepository {
  Future<List<TrackerDevice>> getDevices();
  Future<TrackerDevice?> getDevice(String id);

  /// Checks a tracker ID (from QR or manual entry) before activation.
  Future<DeviceVerification> verifyDeviceId(String deviceId);
  Future<({TrackerDevice device, Asset asset})> addDevice(NewDeviceRequest request);
  Future<TrackerDevice> updateDevice(TrackerDevice device);
  Future<void> removeDevice(String id);
  Future<TrackerDevice> setTrackingMode(String id, TrackingMode mode);
  Future<TrackerDevice> setEmergency(String id, bool active);

  Future<LocationHistory> getLocationHistory(String deviceId, DateTime start, DateTime end);
  Future<List<Trip>> getTrips(String deviceId, DateTime start, DateTime end);

  /// Trips for many devices at once (fleet view), newest first.
  Future<List<Trip>> getFleetTrips(List<String> deviceIds, DateTime start, DateTime end);
}

abstract interface class AssetRepository {
  Future<List<Asset>> getAssets();
  Future<Asset> saveAsset(Asset asset);
  Future<void> deleteAsset(String id);
}

abstract interface class DriverRepository {
  Future<List<Driver>> getDrivers();

  /// Creates a driver. Throws [DataException] if the phone or licence is taken.
  Future<Driver> createDriver({
    required String name,
    required String phone,
    required String licenseNo,
  });

  /// Updates a driver. Throws [DataException] if the phone or licence is taken.
  Future<Driver> saveDriver(Driver driver);
  Future<void> deleteDriver(String id);
}

abstract interface class GeofenceRepository {
  Future<List<Geofence>> getGeofences();
  Future<Geofence> saveGeofence(Geofence geofence);
  Future<void> deleteGeofence(String id);
}

abstract interface class AlertRepository {
  Future<List<TrackerAlert>> getAlerts();
  Future<void> saveAlerts(List<TrackerAlert> alerts);
  Future<List<AppNotification>> getNotifications();
  Future<void> saveNotifications(List<AppNotification> notifications);
}

abstract interface class ShareRepository {
  Future<List<ShareLink>> getShareLinks(String deviceId);
  Future<ShareLink> createShareLink({
    required String deviceId,
    required SharePermission permission,
    required Duration duration,
  });
  Future<void> revoke(String id);
}
