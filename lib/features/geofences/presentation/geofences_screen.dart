import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/status_style.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/geofence.dart';
import '../../devices/application/devices_controller.dart';
import '../../map/presentation/widgets/tracker_map.dart';
import '../application/geofences_controller.dart';

class GeofencesScreen extends ConsumerStatefulWidget {
  const GeofencesScreen({super.key});

  @override
  ConsumerState<GeofencesScreen> createState() => _GeofencesScreenState();
}

class _GeofencesScreenState extends ConsumerState<GeofencesScreen> {
  final _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fences = ref.watch(geofencesProvider);
    final views = ref.watch(deviceViewsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Geofences')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create-geofence'),
        onPressed: () => context.push(Routes.newGeofence),
        icon: const Icon(AppIcons.add),
        label: const Text('Create Geofence'),
      ),
      body: AsyncView<List<Geofence>>(
        value: fences,
        onRetry: () => ref.invalidate(geofencesProvider),
        loading: const SkeletonList(count: 4, message: 'Loading geofences...'),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: AppIcons.geofence,
              title: 'No geofences yet',
              message: 'Create zones like Home, Office or Warehouse to get enter / exit alerts.',
              actionLabel: 'Create Geofence',
              onAction: () => context.push(Routes.newGeofence),
            );
          }
          final names = {for (final v in views) v.id: v.name};
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.bottomSafe),
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
                          height: 220,
                          child: TrackerMap(
                            controller: _controller,
                            geofences: list,
                            devices: views,
                            initialFit: CameraFit.coordinates(
                              coordinates: [for (final g in list) g.center],
                              padding: const EdgeInsets.all(40),
                              maxZoom: 13,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapLg,
                      for (final g in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _GeofenceCard(fence: g, deviceNames: names),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GeofenceCard extends ConsumerWidget {
  const _GeofenceCard({required this.fence, required this.deviceNames});

  final Geofence fence;
  final Map<String, String> deviceNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = StatusStyle.geofence(fence.type);
    final devices = fence.deviceIds.isEmpty
        ? 'All devices'
        : fence.deviceIds.map((id) => deviceNames[id] ?? id).join(', ');
    final events = [if (fence.notifyEnter) 'Enter', if (fence.notifyExit) 'Exit'].join(' & ');
    return AppCard(
      onTap: () => context.push(Routes.geofence(fence.id)),
      child: Row(
        children: [
          IconBadge(icon: AppIcons.geofenceType(fence.type), color: color, size: 44),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fence.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${fence.type.label} · Circle ${Fmt.meters(fence.radiusM)} · ${events.isEmpty ? 'No alerts' : events}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(devices,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(
            value: fence.active,
            onChanged: (v) => ref.read(geofencesProvider.notifier).toggle(fence.id, v),
          ),
        ],
      ),
    );
  }
}
