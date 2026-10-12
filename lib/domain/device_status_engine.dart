import '../data/models/enums.dart';
import '../data/models/tracker_device.dart';

/// Result of evaluating a device's state.
///
/// [primary] is one of: emergency, offline, moving, idle, stopped, stationary.
/// [warnings] may contain lowBattery, noGps, noNetwork.
class StatusSnapshot {
  const StatusSnapshot(this.primary, [this.warnings = const {}]);

  final DeviceStatus primary;
  final Set<DeviceStatus> warnings;

  bool get isOnline => primary != DeviceStatus.offline;
  bool get isMoving => primary == DeviceStatus.moving;
  bool get isEmergency => primary == DeviceStatus.emergency;
  bool get isResting =>
      primary == DeviceStatus.idle ||
      primary == DeviceStatus.stopped ||
      primary == DeviceStatus.stationary;
  bool get hasWarning => warnings.isNotEmpty;
  bool get needsAttention => isEmergency || hasWarning;

  /// The single most important status, used for marker color and badges.
  DeviceStatus get effective {
    if (primary == DeviceStatus.emergency || primary == DeviceStatus.offline) {
      return primary;
    }
    if (warnings.isNotEmpty) return warnings.first;
    return primary;
  }

  /// Sort weight: lower = more important.
  int get priority => switch (effective) {
        DeviceStatus.emergency => 0,
        DeviceStatus.lowBattery || DeviceStatus.noGps || DeviceStatus.noNetwork => 1,
        DeviceStatus.moving => 2,
        DeviceStatus.idle => 3,
        DeviceStatus.stopped || DeviceStatus.stationary || DeviceStatus.online => 4,
        DeviceStatus.offline => 5,
      };

  @override
  bool operator ==(Object other) =>
      other is StatusSnapshot &&
      other.primary == primary &&
      other.warnings.length == warnings.length &&
      other.warnings.containsAll(warnings);

  @override
  int get hashCode => Object.hash(primary, Object.hashAllUnordered(warnings));
}

/// Centralized status rules so every screen agrees on what a device is doing.
abstract final class DeviceStatusEngine {
  static const lowBatteryThreshold = 20;

  /// A device is considered offline after this many missed reports.
  static const missedReportsForOffline = 3;
  static const offlineGrace = Duration(seconds: 60);

  static StatusSnapshot evaluate(
    TrackerDevice device,
    AssetType type, {
    required DateTime now,
  }) {
    if (device.emergency) return const StatusSnapshot(DeviceStatus.emergency);

    final loc = device.location;
    final lastSeen = device.lastSeen ?? loc?.timestamp;
    if (!device.connected || loc == null || lastSeen == null) {
      return const StatusSnapshot(DeviceStatus.offline);
    }
    final staleAfter = device.updateInterval * missedReportsForOffline + offlineGrace;
    if (now.difference(lastSeen) > staleAfter) {
      return const StatusSnapshot(DeviceStatus.offline);
    }

    final warnings = <DeviceStatus>{};
    final t = loc.telemetry;
    if (t.battery <= lowBatteryThreshold) warnings.add(DeviceStatus.lowBattery);
    if (t.gpsSignal == SignalQuality.none) warnings.add(DeviceStatus.noGps);
    if (t.signal == SignalQuality.none) warnings.add(DeviceStatus.noNetwork);

    final DeviceStatus primary;
    if (loc.speedKmh > type.movingThreshold) {
      primary = DeviceStatus.moving;
    } else if (type.hasIgnition) {
      primary = (t.ignition ?? false) ? DeviceStatus.idle : DeviceStatus.stopped;
    } else {
      primary = DeviceStatus.stationary;
    }
    return StatusSnapshot(primary, warnings);
  }

  static bool matchesFilter(StatusSnapshot s, StatusFilter filter) => switch (filter) {
        StatusFilter.all => true,
        StatusFilter.online => s.isOnline,
        StatusFilter.offline => !s.isOnline,
        StatusFilter.moving => s.isMoving,
        StatusFilter.idle => s.isResting,
        StatusFilter.alert => s.needsAttention,
      };
}
