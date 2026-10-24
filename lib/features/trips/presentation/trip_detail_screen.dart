import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../data/models/trip.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
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
    final tones = context.tones;
    final bg = tones.groundBase;
    final top = MediaQuery.paddingOf(context).top;
    final points = [for (final p in trip.points) p.position];
    final stats = recompute(trip);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.huge),
        children: [
          SizedBox(
            height: 300 + top,
            child: Stack(
              children: [
                Positioned.fill(
                  child: TrackerMap(
                    controller: _controller,
                    showUserLocation: false,
                    initialFit: CameraFit.coordinates(
                      coordinates: points,
                      padding: EdgeInsets.fromLTRB(36, 36 + top + 44, 36, 56),
                    ),
                    layersBelowDevices: [RouteLayers(points: points)],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: top + 70,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [bg, bg.withAlpha(0)],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 70,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [bg, bg.withAlpha(0)],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: top + AppSpacing.sm,
                  child: Row(
                    children: [
                      MapGlass(
                        child: SizedBox.square(
                          dimension: 44,
                          child: BackButton(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      const Spacer(),
                      GlassPill(height: 32, child: Text('${Fmt.dayLabel(trip.start)} · ${Fmt.time(trip.start)}')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ResponsiveCenter(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (view != null) ...[
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                      onTap: () => context.push(Routes.device(view.id)),
                      child: Row(
                        children: [
                          DeviceAvatar(view, size: 40),
                          AppSpacing.gapMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  view.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                                if (view.driver != null)
                                  Text(view.driver!.name, style: TextStyle(fontSize: 12, color: tones.neutral500)),
                              ],
                            ),
                          ),
                          Icon(AppIcons.chevronRight, size: 18, color: tones.neutral600),
                        ],
                      ),
                    ),
                    AppSpacing.gapMd,
                  ],
                  StatsGrid(items: tripStatTiles(stats, ref)),
                  AppSpacing.gapMd,
                  TripTimeline(trip: trip),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
