import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../domain/device_status_engine.dart';
import 'app_colors.dart';

/// Visual language for device status — used by markers, badges and lists.
abstract final class StatusStyle {
  static Color color(DeviceStatus s) => switch (s) {
        DeviceStatus.moving || DeviceStatus.online => AppColors.moving,
        DeviceStatus.idle => AppColors.idle,
        DeviceStatus.stopped || DeviceStatus.stationary => AppColors.stationary,
        DeviceStatus.offline => AppColors.offline,
        DeviceStatus.lowBattery || DeviceStatus.noGps || DeviceStatus.noNetwork => AppColors.warning,
        DeviceStatus.emergency => AppColors.emergency,
      };

  static Color of(StatusSnapshot s) => color(s.effective);

  /// "Moving", "Stationary", "Offline", optionally with the warning.
  static String label(StatusSnapshot s) {
    final base = s.primary.label;
    if (s.warnings.isEmpty || !s.isOnline || s.isEmergency) return base;
    return '$base · ${s.warnings.first.label}';
  }

  static Color severity(AlertSeverity s) => switch (s) {
        AlertSeverity.critical => AppColors.emergency,
        AlertSeverity.warning => AppColors.warning,
        AlertSeverity.info => AppColors.stationary,
      };

  static Color alert(AlertType t, AlertSeverity s) => switch (t) {
        AlertType.offline => AppColors.offline,
        AlertType.online => AppColors.moving,
        _ => severity(s),
      };

  static Color geofence(GeofenceType t) => switch (t) {
        GeofenceType.home || GeofenceType.safeZone => AppColors.moving,
        GeofenceType.office => AppColors.iris,
        GeofenceType.warehouse => AppColors.signal,
        GeofenceType.restricted => AppColors.emergency,
        GeofenceType.customer => AppColors.warning,
      };

  static Color battery(int? level) {
    if (level == null) return AppColors.offline;
    if (level <= 20) return AppColors.emergency;
    if (level <= 40) return AppColors.warning;
    return AppColors.moving;
  }
}
