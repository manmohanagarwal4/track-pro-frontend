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
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/trips_providers.dart';

/// Trip row (`is.history`): time | route | distance, inside a grouped tile.
class TripCard extends ConsumerWidget {
  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    this.deviceName,
    this.first = true,
    this.last = true,
  });

  final Trip trip;
  final VoidCallback onTap;
  final String? deviceName;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tones = context.tones;
    final unit = ref.watch(settingsProvider.select((s) => s.unit));
    final meta = [?deviceName, Fmt.duration(trip.stats.duration)].join(' · ');
    return GroupedItem(
      first: first,
      last: last,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 74,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Fmt.time(trip.start),
                        style: TextStyle(fontSize: 13, color: tones.neutral500, fontFeatures: AppTypography.tabular)),
                    const SizedBox(height: 2),
                    Text(Fmt.time(trip.end),
                        style: TextStyle(fontSize: 11, color: tones.neutral400, fontFeatures: AppTypography.tabular)),
                  ],
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${trip.startName} → ${trip.endName}',
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: tones.neutral500)),
                  ],
                ),
              ),
              AppSpacing.gapMd,
              Text(Fmt.distance(trip.stats.distanceKm, unit, decimals: 1),
                  style: TextStyle(fontSize: 13, color: tones.neutral400, fontFeatures: AppTypography.tabular)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A day header or a trip row, for day-grouped trip lists.
typedef TripEntry = ({String? day, Trip? trip, bool first, bool last});

/// Splits [trips] into runs of the same day, each preceded by a header entry.
List<TripEntry> groupTripsByDay(List<Trip> trips) {
  String day(Trip t) => Fmt.dayLabel(t.start);
  final out = <TripEntry>[];
  for (var i = 0; i < trips.length; i++) {
    final d = day(trips[i]);
    final first = i == 0 || day(trips[i - 1]) != d;
    final last = i == trips.length - 1 || day(trips[i + 1]) != d;
    if (first) out.add((day: d, trip: null, first: false, last: false));
    out.add((day: null, trip: trips[i], first: first, last: last));
  }
  return out;
}

class StatTile {
  const StatTile(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

/// Grid of small stat tiles: value above an 11px muted label.
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.items});

  final List<StatTile> items;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    return LayoutBuilder(builder: (context, c) {
      final max = c.maxWidth > 560 ? 6 : 3;
      final cols = items.length < max ? items.length : max;
      const gap = AppSpacing.sm;
      final w = (c.maxWidth - (cols - 1) * gap) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final i in items)
            SizedBox(
              width: w,
              child: AppCard(
                radius: AppRadius.mdAll,
                padding: AppSpacing.cardCompact,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.metricSmall.copyWith(fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(i.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: tones.neutral500)),
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
              avatar: p == DateRangePreset.custom
                  ? Icon(AppIcons.calendar, size: 14, color: context.tones.neutral400)
                  : null,
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
            const SizedBox(width: 6),
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
