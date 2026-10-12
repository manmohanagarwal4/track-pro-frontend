import 'package:latlong2/latlong.dart';

import '../data/models/asset.dart';
import '../data/models/driver.dart';
import '../data/models/enums.dart';
import '../data/models/tracker_device.dart';
import 'device_status_engine.dart';

/// Read model joining a tracker with its asset, driver and computed status.
class DeviceView {
  const DeviceView({
    required this.device,
    required this.status,
    this.asset,
    this.driver,
  });

  final TrackerDevice device;
  final Asset? asset;
  final Driver? driver;
  final StatusSnapshot status;

  String get id => device.id;
  String get name => asset?.name ?? 'Tracker ${device.id}';
  AssetType get type => asset?.type ?? AssetType.generic;

  /// Icon type, honouring a user-chosen icon.
  AssetType get iconType => device.iconOverride ?? type;
  String? get registration => asset?.registration;
  bool get isAssigned => asset != null;

  LatLng? get position => device.location?.position;
  double get speedKmh => status.isOnline ? (device.location?.speedKmh ?? 0) : 0;
  double get heading => device.location?.heading ?? 0;
  int? get battery => device.location?.telemetry.battery;
  DateTime? get lastUpdate => device.lastSeen ?? device.location?.timestamp;
  AssetCategory get category => asset?.category ?? AssetCategory.business;
}
