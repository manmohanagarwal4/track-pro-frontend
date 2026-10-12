import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/trip.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/trips_providers.dart';

class TripCard extends ConsumerWidget {
  const TripCard({super.key, required this.trip, required this.onTap, this.deviceName});

  final Trip trip;
  final VoidCallback onTap;
  final String? deviceName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(settingsProvider.select((s) => s.unit));
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(Fmt.dayLabel(trip.start), style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${Fmt.time(trip.start)} → ${Fmt.time(trip.end)}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
              ),
              if (deviceName != null)
                Flexible(
                  child: Text(deviceName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelMedium),
                ),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              Column(
                children: [
                  const Icon(AppIcons.circle, size: 12, color: AppColors.moving),
                  Container(width: 2, height: 18, color: theme.colorScheme.outline),
                  const Icon(AppIcons.pin, size: 14, color: AppColors.emergency),
                ],
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.startName, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Text(trip.endName, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Fmt.distance(trip.stats.distanceKm, unit, decimals: 1), style: AppTypography.metricSmall),
                  Text(Fmt.duration(trip.stats.duration), style: muted),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatTile {
  const StatTile(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.items});

  final List<StatTile> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 560 ? 4 : 2;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(i.icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(i.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(i.value, style: AppTypography.metricSmall),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

List<StatTile> tripStatTiles(TripStats s, WidgetRef ref) {
  final unit = ref.watch(settingsProvider.select((x) => x.unit));
  return [
    StatTile('Distance', Fmt.distance(s.distanceKm, unit, decimals: 1), AppIcons.route),
    StatTile('Duration', Fmt.duration(s.duration), AppIcons.clock),
    StatTile('Average Speed', Fmt.speed(s.avgSpeedKmh, unit), AppIcons.speed),
    StatTile('Maximum Speed', Fmt.speed(s.maxSpeedKmh, unit), AppIcons.overspeed),
    StatTile('Stops', '${s.stops}', AppIcons.stops),
    StatTile('Idle Time', Fmt.duration(s.idleTime), AppIcons.timer),
  ];
}

/// Today / Yesterday / Last 7 Days / Custom selector.
class DateRangeSelector extends StatelessWidget {
  const DateRangeSelector({
    super.key,
    required this.preset,
    required this.onChanged,
    this.custom,
    this.presets = DateRangePreset.values,
  });

  final DateRangePreset preset;
  final DateTimeRange? custom;
  final List<DateRangePreset> presets;
  final void Function(DateRangePreset preset, DateTimeRange? custom) onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        children: [
          for (final p in presets) ...[
            ChoiceChip(
              label: Text(p == DateRangePreset.custom && preset == p && custom != null
                  ? '${Fmt.dateShort(custom!.start)} – ${Fmt.dateShort(custom!.end)}'
                  : p.label),
              avatar: p == DateRangePreset.custom ? const Icon(AppIcons.calendar, size: 16) : null,
              selected: p == preset,
              onSelected: (_) async {
                if (p != DateRangePreset.custom) {
                  onChanged(p, null);
                  return;
                }
                final now = clock.now();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: now.subtract(const Duration(days: 60)),
                  lastDate: now,
                  initialDateRange: custom ??
                      DateTimeRange(start: now.subtract(const Duration(days: 2)), end: now),
                );
                if (picked != null) onChanged(p, picked);
              },
            ),
            AppSpacing.gapSm,
          ],
        ],
      ),
    );
  }
}

({DateTime start, DateTime end}) resolveRange(DateRangePreset preset, DateTimeRange? custom, DateTime now) {
  if (preset == DateRangePreset.custom && custom != null) {
    final end = DateTime(custom.end.year, custom.end.month, custom.end.day, 23, 59, 59);
    return (start: DateTime(custom.start.year, custom.start.month, custom.start.day), end: end.isAfter(now) ? now : end);
  }
  return preset.range(now);
}
