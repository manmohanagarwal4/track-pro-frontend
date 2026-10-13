import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
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
    final theme = Theme.of(context);
    final tones = context.tones;
    final fences = ref.watch(geofencesProvider);
    final views = ref.watch(deviceViewsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofences'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: FilledButton.icon(
              key: const Key('create-geofence'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
              onPressed: () => context.push(Routes.newGeofence),
              icon: const Icon(AppIcons.add, size: 18),
              label: const Text('New'),
            ),
          ),
        ],
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
          final active = list.where((g) => g.active).length;
          return ListView(
            padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.bottomSafe),
            children: [
              ResponsiveCenter(
                child: Padding(
                  padding: AppSpacing.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        radius: AppRadius.mdAll,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Icon(AppIcons.geofence, size: 20, color: tones.accent300),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$active of ${list.length} zones active',
                                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                                  Text('Enter / exit alerts fire as devices cross a boundary',
                                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapMd,
                      ClipRRect(
                        borderRadius: AppRadius.lgAll,
                        child: SizedBox(
                          height: 200,
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
                      AppSpacing.gapMd,
                      for (final g in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
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
    final tones = context.tones;
    final color = tones.tone(StatusStyle.geofence(fence.type));
    final devices = fence.deviceIds.isEmpty
        ? 'All devices'
        : fence.deviceIds.map((id) => deviceNames[id] ?? id).join(', ');
    final events = [if (fence.notifyEnter) 'Enter', if (fence.notifyExit) 'Exit'].join(' & ');
    final meta = theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500);
    return AppCard(
      onTap: () => context.push(Routes.geofence(fence.id)),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.xs, AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.08),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(AppIcons.geofenceType(fence.type), size: 18, color: color),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(fence.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15)),
                    ),
                    const SizedBox(width: 6),
                    Pill(
                      label: fence.active ? 'Active' : 'Paused',
                      color: fence.active ? AppColors.moving : AppColors.offline,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${fence.type.label} · Circle ${Fmt.meters(fence.radiusM)} · ${events.isEmpty ? 'No alerts' : events}',
                  style: meta,
                ),
                Text(devices, maxLines: 1, overflow: TextOverflow.ellipsis, style: meta),
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
