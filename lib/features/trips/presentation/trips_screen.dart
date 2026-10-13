import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/trip.dart';
import '../../../domain/trip_calculator.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../devices/application/devices_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../application/trips_providers.dart';
import 'widgets/trip_widgets.dart';

/// Trips of a single device.
class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  DateRangePreset _preset = DateRangePreset.last7;
  DateTimeRange? _custom;
  late RangeQuery _query = _build();

  RangeQuery _build() {
    final r = resolveRange(_preset, _custom, clock.now());
    return (deviceId: widget.deviceId, start: r.start, end: r.end);
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(deviceViewProvider(widget.deviceId));
    final trips = ref.watch(deviceTripsProvider(_query));
    final unit = ref.watch(settingsProvider.select((s) => s.unit));
    return Scaffold(
      appBar: AppBar(title: Text('${view?.name ?? 'Device'} · Trips')),
      body: Column(
        children: [
          DateRangeSelector(
            preset: _preset,
            custom: _custom,
            onChanged: (p, c) => setState(() {
              _preset = p;
              _custom = c;
              _query = _build();
            }),
          ),
          AppSpacing.gapSm,
          Expanded(
            child: AsyncView<List<Trip>>(
              value: trips,
              onRetry: () => ref.invalidate(deviceTripsProvider(_query)),
              loading: const SkeletonList(count: 4, message: 'Loading trips...'),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyView(
                    icon: AppIcons.trips,
                    title: 'No trips in this period',
                    message: 'Trips appear here once the tracker starts moving.',
                  );
                }
                final total = list.fold<double>(0, (a, t) => a + t.stats.distanceKm);
                final time = list.fold<Duration>(Duration.zero, (a, t) => a + t.stats.duration);
                final entries = groupTripsByDay(list);
                return ResponsiveCenter(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.huge),
                    itemCount: entries.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return Text(
                          '${list.length} trips · ${Fmt.distance(total, unit, decimals: 1)} · ${Fmt.duration(time)}',
                          style: TextStyle(fontSize: 12, color: context.tones.neutral500),
                        );
                      }
                      final e = entries[i - 1];
                      if (e.day != null) {
                        return Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: GroupLabel(e.day!));
                      }
                      final t = e.trip!;
                      return TripCard(
                        trip: t,
                        first: e.first,
                        last: e.last,
                        onTap: () => context.push(Routes.trip(t.deviceId, t.id), extra: t),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Re-computes stats for a trip (shows the calculation is real, not stored).
TripStats recompute(Trip t) => TripCalculator.compute(t.points);

/// Start / end of a trip as a facts-style list.
class TripTimeline extends StatelessWidget {
  const TripTimeline({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    return GroupedTile(
      inset: 14,
      children: [
        _row(context, AppIcons.play, 'Start', trip.startName, Fmt.time(trip.start), tones.ok),
        _row(context, AppIcons.flag, 'End', trip.endName, Fmt.time(trip.end), tones.crit),
      ],
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String place, String time, Color color) {
    final tones = context.tones;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: tones.neutral500)),
                Text(place, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          AppSpacing.gapSm,
          Text(time, style: TextStyle(fontSize: 13, color: tones.neutral400, fontFeatures: AppTypography.tabular)),
        ],
      ),
    );
  }
}
