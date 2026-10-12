import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/trip.dart';
import '../../../domain/device_query.dart';
import '../../devices/application/devices_controller.dart';
import '../../devices/presentation/widgets/device_card.dart';
import '../../settings/application/settings_controller.dart';
import '../application/trips_providers.dart';
import 'widgets/trip_widgets.dart';

/// Business "Trips" tab: trips across all vehicles.
class FleetTripsScreen extends ConsumerStatefulWidget {
  const FleetTripsScreen({super.key});

  @override
  ConsumerState<FleetTripsScreen> createState() => _FleetTripsScreenState();
}

class _FleetTripsScreenState extends ConsumerState<FleetTripsScreen> {
  DateRangePreset _preset = DateRangePreset.today;
  DateTimeRange? _custom;
  String _text = '';
  int _visible = 20;

  @override
  Widget build(BuildContext context) {
    final views = ref.watch(deviceViewsProvider).value ?? const [];
    final vehicles = views.where((v) => v.type.isVehicle).toList()..sort((a, b) => a.id.compareTo(b.id));
    final byId = {for (final v in vehicles) v.id: v};
    final range = resolveRange(_preset, _custom, clock.now());
    // Round the end to the minute so the provider key is stable between rebuilds.
    final end = DateTime(range.end.year, range.end.month, range.end.day, range.end.hour, range.end.minute);
    final query = (ids: vehicles.map((v) => v.id).join(','), start: range.start, end: end);
    final trips = ref.watch(fleetTripsProvider(query));
    final unit = ref.watch(settingsProvider.select((s) => s.unit));

    return Scaffold(
      appBar: AppBar(title: const Text('Trips')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: SearchField(
              hint: 'Filter by vehicle, plate or driver',
              onChanged: (t) => setState(() {
                _text = t;
                _visible = 20;
              }),
            ),
          ),
          DateRangeSelector(
            preset: _preset,
            custom: _custom,
            onChanged: (p, c) => setState(() {
              _preset = p;
              _custom = c;
              _visible = 20;
            }),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: AsyncView<List<Trip>>(
              value: trips,
              onRetry: () => ref.invalidate(fleetTripsProvider(query)),
              loading: const SkeletonList(count: 5, message: 'Loading fleet trips...'),
              data: (all) {
                final list = all.where((t) {
                  final v = byId[t.deviceId];
                  return v != null && DeviceQuery.matchesText(v, _text);
                }).toList();
                if (list.isEmpty) {
                  return const EmptyView(
                    icon: AppIcons.trips,
                    title: 'No trips found',
                    message: 'Try another date range or vehicle.',
                  );
                }
                final total = list.fold<double>(0, (a, t) => a + t.stats.distanceKm);
                final shown = list.take(_visible).toList();
                return ResponsiveCenter(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.extentAfter < 400 && _visible < list.length) {
                        setState(() => _visible += 20);
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.bottomSafe),
                      itemCount: shown.length + 2,
                      separatorBuilder: (_, _) => AppSpacing.gapMd,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return AppCard(
                            padding: AppSpacing.cardCompact,
                            child: Row(
                              children: [
                                const Icon(AppIcons.route, size: 18),
                                AppSpacing.gapMd,
                                Expanded(
                                  child: Text(
                                    '${list.length} trips · ${Fmt.distance(total, unit, decimals: 0)} driven',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        if (i == shown.length + 1) {
                          return _visible < list.length
                              ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                              : Center(
                                  child: Text('All ${list.length} trips loaded',
                                      style: Theme.of(context).textTheme.bodySmall),
                                );
                        }
                        final t = shown[i - 1];
                        return TripCard(
                          trip: t,
                          deviceName: byId[t.deviceId]?.name,
                          onTap: () => context.push(Routes.trip(t.deviceId, t.id), extra: t),
                        );
                      },
                    ),
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
