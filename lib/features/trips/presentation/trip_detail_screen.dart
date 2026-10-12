import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/trip.dart';
import '../../devices/application/devices_controller.dart';
import '../../map/presentation/widgets/map_layers.dart';
import '../../map/presentation/widgets/tracker_map.dart';
import 'trips_screen.dart';
import 'widgets/trip_widgets.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  const TripDetailScreen({super.key, required this.deviceId, this.trip});

  final String deviceId;
  final Trip? trip;

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  final _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final view = ref.watch(deviceViewProvider(widget.deviceId));
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyView(
          icon: AppIcons.trips,
          title: 'Trip not available',
          message: 'Open it from the trips list.',
          actionLabel: 'View trips',
          onAction: () => context.pushReplacement(Routes.deviceTrips(widget.deviceId)),
        ),
      );
    }
    final points = [for (final p in trip.points) p.position];
    final stats = recompute(trip);
    return Scaffold(
      appBar: AppBar(title: Text('${Fmt.dayLabel(trip.start)} · ${Fmt.time(trip.start)}')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.huge),
        children: [
          ResponsiveCenter(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.lgAll,
                    child: SizedBox(
                      height: 300,
                      child: TrackerMap(
                        controller: _controller,
                        showUserLocation: false,
                        initialFit: CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(36)),
                        layersBelowDevices: [RouteLayers(points: points)],
                      ),
                    ),
                  ),
                  AppSpacing.gapMd,
                  if (view != null)
                    AppCard(
                      padding: AppSpacing.cardCompact,
                      onTap: () => context.push(Routes.device(view.id)),
                      child: Row(
                        children: [
                          Icon(AppIcons.asset(view.iconType), size: 20),
                          AppSpacing.gapMd,
                          Expanded(child: Text(view.name, style: Theme.of(context).textTheme.titleSmall)),
                          if (view.driver != null) Text(view.driver!.name, style: Theme.of(context).textTheme.bodySmall),
                          const Icon(AppIcons.chevronRight, size: 18),
                        ],
                      ),
                    ),
                  AppSpacing.gapMd,
                  TripTimeline(trip: trip),
                  AppSpacing.gapMd,
                  StatsGrid(items: tripStatTiles(stats, ref)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
