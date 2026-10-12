import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/status_style.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/enums.dart';
import '../../../../domain/device_view.dart';

class TelemetryItem {
  const TelemetryItem(this.label, this.value, this.icon, {this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
}

/// Telemetry relevant to the asset type.
List<TelemetryItem> telemetryFor(DeviceView v, DistanceUnit unit) {
  final loc = v.device.location;
  if (loc == null) return const [];
  final t = loc.telemetry;
  final online = v.status.isOnline;
  final type = v.type;

  final speed = TelemetryItem('Speed', Fmt.speed(v.speedKmh, unit), AppIcons.speed,
      color: v.status.isMoving ? AppColors.moving : null);
  final heading = TelemetryItem('Heading', '${GeoUtils.compass(loc.heading)} · ${loc.heading.round()}°', AppIcons.compass);
  final altitude = TelemetryItem('Altitude', '${loc.altitude.round()} m', AppIcons.altitude);
  final accuracy = TelemetryItem('GPS Accuracy', '${loc.accuracy.round()} m', AppIcons.accuracy);
  final sats = TelemetryItem('Satellites', '${t.satellites}', AppIcons.satellite);
  final gps = TelemetryItem('GPS', online ? t.gpsSignal.label : 'No fix', AppIcons.satellite,
      color: online ? null : AppColors.offline);
  final battery = TelemetryItem('Battery', '${t.battery}%', AppIcons.battery, color: StatusStyle.battery(t.battery));
  final network = TelemetryItem('Network', online ? '${t.signal.label} · 4G' : 'Disconnected', AppIcons.network,
      color: online ? null : AppColors.offline);
  final temp = TelemetryItem('Temperature', '${t.temperature.toStringAsFixed(1)}°C', AppIcons.temperature);
  final motion = TelemetryItem('Motion', t.motion && online ? 'Detected' : 'None', AppIcons.motion,
      color: t.motion && online ? AppColors.moving : null);
  final ignition = TelemetryItem('Ignition', (t.ignition ?? false) && online ? 'ON' : 'OFF', AppIcons.ignition,
      color: (t.ignition ?? false) && online ? AppColors.moving : null);
  final fuel = t.fuel == null
      ? null
      : TelemetryItem('Fuel', '${t.fuel!.round()}%', AppIcons.fuel,
          color: t.fuel! < 20 ? AppColors.warning : null);
  final odometer = TelemetryItem('Odometer', Fmt.distance(v.device.odometerKm, unit, decimals: 0), AppIcons.odometer);
  final today = TelemetryItem('Trip today', Fmt.distance(v.device.tripDistanceKm, unit, decimals: 1), AppIcons.route);

  return switch (type) {
    AssetType.pet => [motion, speed, temp, battery, gps, accuracy, network, today],
    AssetType.person => [motion, speed, battery, gps, accuracy, network, temp, today],
    AssetType.truck => [speed, heading, ignition, ?fuel, battery, gps, temp, altitude, sats, accuracy, network, odometer, today],
    AssetType.taxi || AssetType.delivery => [speed, heading, ignition, ?fuel, battery, gps, network, temp, sats, odometer, today],
    AssetType.car || AssetType.bike => [speed, heading, ignition, battery, gps, temp, altitude, sats, accuracy, network, odometer, today],
    _ => [battery, gps, network, temp, motion, accuracy, sats, altitude],
  };
}

class TelemetryGrid extends StatelessWidget {
  const TelemetryGrid({super.key, required this.items});

  final List<TelemetryItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 600 ? 4 : 2;
        final w = (c.maxWidth - (cols - 1) * AppSpacing.md) / cols;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final i in items)
              SizedBox(
                width: w,
                child: AppCard(
                  padding: AppSpacing.cardCompact,
                  child: Row(
                    children: [
                      Icon(i.icon, size: 18, color: i.color ?? theme.colorScheme.onSurfaceVariant),
                      AppSpacing.gapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i.label,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            AnimatedSwitcher(
                              duration: AppDurations.fast,
                              child: Text(
                                i.value,
                                key: ValueKey(i.value),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: i.color,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
