import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../data/models/trip.dart';

enum DateRangePreset {
  today('Today'),
  yesterday('Yesterday'),
  last7('Last 7 Days'),
  custom('Custom');

  const DateRangePreset(this.label);
  final String label;

  ({DateTime start, DateTime end}) range(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      DateRangePreset.today => (start: today, end: now),
      DateRangePreset.yesterday => (start: today.subtract(const Duration(days: 1)), end: today),
      DateRangePreset.last7 => (start: today.subtract(const Duration(days: 6)), end: now),
      DateRangePreset.custom => (start: today, end: now),
    };
  }
}

typedef RangeQuery = ({String deviceId, DateTime start, DateTime end});

final historyProvider = FutureProvider.autoDispose.family<LocationHistory, RangeQuery>(
  (ref, q) => ref.watch(trackingRepositoryProvider).getLocationHistory(q.deviceId, q.start, q.end),
);

final deviceTripsProvider = FutureProvider.autoDispose.family<List<Trip>, RangeQuery>(
  (ref, q) => ref.watch(trackingRepositoryProvider).getTrips(q.deviceId, q.start, q.end),
);

typedef FleetRangeQuery = ({String ids, DateTime start, DateTime end});

/// `ids` is a comma-joined device id list (keeps the family key value-comparable).
final fleetTripsProvider = FutureProvider.autoDispose.family<List<Trip>, FleetRangeQuery>(
  (ref, q) => ref
      .watch(trackingRepositoryProvider)
      .getFleetTrips(q.ids.isEmpty ? const [] : q.ids.split(','), q.start, q.end),
);
