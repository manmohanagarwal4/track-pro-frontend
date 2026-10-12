import '../data/models/alert.dart';
import '../data/models/enums.dart';
import '../data/models/geofence.dart';
import 'device_status_engine.dart';
import 'device_view.dart';

/// Turns device state transitions and geofence events into alerts.
class AlertRulesEngine {
  AlertRulesEngine({this.overspeedCooldown = const Duration(minutes: 3)});

  final Duration overspeedCooldown;
  final Map<String, DateTime> _lastOverspeed = {};
  int _seq = 0;

  String _id(DateTime now) => 'al-${now.microsecondsSinceEpoch}-${_seq++}';

  List<TrackerAlert> evaluate({
    required DeviceView? previous,
    required DeviceView current,
    List<GeofenceEvent> geofenceEvents = const [],
    required DateTime now,
  }) {
    final out = <TrackerAlert>[];
    final cfg = current.device.alertConfig;
    final name = current.name;
    final pos = current.position;

    TrackerAlert make(AlertType type, AlertSeverity sev, String title, String msg,
            {String? value}) =>
        TrackerAlert(
          id: _id(now),
          type: type,
          severity: sev,
          deviceId: current.id,
          deviceName: name,
          title: title,
          message: msg,
          timestamp: now,
          value: value,
          position: pos,
        );

    // Emergency
    if (cfg.sos && current.status.isEmergency && !(previous?.status.isEmergency ?? false)) {
      out.add(make(AlertType.emergency, AlertSeverity.critical, 'Emergency',
          'Emergency mode activated on $name. Tracking frequency increased.'));
    }

    // Offline / back online (needs a previous state to detect a transition)
    if (previous != null && cfg.offline) {
      if (previous.status.isOnline && !current.status.isOnline) {
        out.add(make(AlertType.offline, AlertSeverity.warning, 'Device Offline',
            '$name has gone offline.'));
      } else if (!previous.status.isOnline && current.status.isOnline) {
        out.add(make(AlertType.online, AlertSeverity.info, 'Back Online',
            '$name is reporting again.'));
      }
    }

    // Overspeed
    final speed = current.speedKmh;
    if (cfg.overspeed && current.type.isVehicle && speed > cfg.speedLimit) {
      final last = _lastOverspeed[current.id];
      if (last == null || now.difference(last) >= overspeedCooldown) {
        _lastOverspeed[current.id] = now;
        out.add(make(AlertType.overspeed, AlertSeverity.critical, 'Overspeed',
            '$name exceeded ${cfg.speedLimit.round()} km/h.',
            value: '${speed.round()} km/h'));
      }
    }

    // Low battery (on crossing the threshold)
    final prevBat = previous?.battery;
    final bat = current.battery;
    if (cfg.lowBattery &&
        prevBat != null &&
        bat != null &&
        prevBat > DeviceStatusEngine.lowBatteryThreshold &&
        bat <= DeviceStatusEngine.lowBatteryThreshold) {
      out.add(make(AlertType.lowBattery, AlertSeverity.warning, 'Low Battery',
          '$name battery below ${DeviceStatusEngine.lowBatteryThreshold}%.',
          value: '$bat%'));
    }

    // Geofences
    if (cfg.geofence) {
      for (final e in geofenceEvents) {
        final enter = e.type == GeofenceEventType.enter;
        if (enter && !e.geofence.notifyEnter) continue;
        if (!enter && !e.geofence.notifyExit) continue;
        final restricted = e.geofence.type == GeofenceType.restricted;
        out.add(TrackerAlert(
          id: _id(now),
          type: enter ? AlertType.geofenceEnter : AlertType.geofenceExit,
          severity: restricted && enter ? AlertSeverity.critical : AlertSeverity.warning,
          deviceId: current.id,
          deviceName: name,
          title: enter ? 'Geofence Enter' : 'Geofence Exit',
          message: '$name ${enter ? 'entered' : 'exited'} ${e.geofence.name}.',
          timestamp: now,
          position: e.position,
        ));
      }
    }
    return out;
  }
}
