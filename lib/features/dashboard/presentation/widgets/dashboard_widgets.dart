import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_widgets.dart';
import '../../../../domain/device_view.dart';
import '../../../devices/application/devices_controller.dart';
import '../../../geofences/application/geofences_controller.dart';
import '../../../map/presentation/widgets/tracker_map.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../tracking/application/live_tracking_controller.dart';

class SummaryTile extends StatelessWidget {
  const SummaryTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 38),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(end: value.toDouble()),
                  duration: AppDurations.slow,
                  builder: (_, v, _) => Text('${v.round()}', style: AppTypography.metric.copyWith(fontSize: 22)),
                ),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact live map preview on the dashboard.
class LiveMapCard extends ConsumerStatefulWidget {
  const LiveMapCard({super.key, required this.devices});

  final List<DeviceView> devices;

  @override
  ConsumerState<LiveMapCard> createState() => _LiveMapCardState();
}

class _LiveMapCardState extends ConsumerState<LiveMapCard> {
  final _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fences = ref.watch(geofencesProvider).value ?? const [];
    final running = ref.watch(liveTrackingProvider.select((s) => s.running));
    return ClipRRect(
      borderRadius: AppRadius.lgAll,
      child: SizedBox(
        height: 250,
        child: Stack(
          children: [
            TrackerMap(
              controller: _controller,
              devices: widget.devices,
              geofences: fences,
              initialZoom: 9.8,
              onDeviceTap: (id) => context.push(Routes.device(id)),
            ),
            Positioned(
              left: AppSpacing.md,
              top: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.94),
                  borderRadius: AppRadius.pillAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusDot(color: running ? AppColors.moving : AppColors.offline, pulse: running, size: 7),
                    const SizedBox(width: 6),
                    Text(running ? 'LIVE' : 'PAUSED', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            ),
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: FilledButton.tonalIcon(
                onPressed: () => context.go(Routes.map),
                icon: const Icon(AppIcons.map, size: 16),
                label: const Text('Open map'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live Simulation ON/OFF toggle.
class LiveSimulationToggle extends ConsumerWidget {
  const LiveSimulationToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final on = ref.watch(settingsProvider.select((s) => s.liveSimulation));
    final speed = ref.watch(settingsProvider.select((s) => s.simulationSpeed));
    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          Icon(AppIcons.navigation, size: 20, color: on ? AppColors.moving : theme.colorScheme.onSurfaceVariant),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live Simulation', style: theme.textTheme.titleSmall),
                Text(
                  on ? 'Devices are moving · ${speed == 1 ? 'real time' : '${speed.toStringAsFixed(0)}x speed'}' : 'Paused · positions frozen',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(
            key: const Key('live-sim-toggle'),
            value: on,
            onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(liveSimulation: v)),
          ),
        ],
      ),
    );
  }
}

/// Stacked bar of fleet status distribution.
class FleetDistributionBar extends StatelessWidget {
  const FleetDistributionBar({super.key, required this.counts});

  final DashboardCounts counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segments = [
      ('Moving', counts.moving, AppColors.moving),
      ('Idle', counts.idle, AppColors.idle),
      ('Stopped', counts.stopped, AppColors.stationary),
      ('Offline', counts.offline, AppColors.offline),
    ];
    final total = counts.total == 0 ? 1 : counts.total;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Fleet utilisation',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
              ),
              Text('${(counts.moving / total * 100).round()}% active',
                  style: theme.textTheme.labelMedium?.copyWith(color: AppColors.moving)),
            ],
          ),
          AppSpacing.gapMd,
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (final s in segments)
                    if (s.$2 > 0)
                      Expanded(
                        flex: s.$2,
                        child: AnimatedContainer(duration: AppDurations.slow, color: s.$3),
                      ),
                ],
              ),
            ),
          ),
          AppSpacing.gapMd,
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              for (final s in segments)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${s.$1} ${s.$2}', style: theme.textTheme.bodySmall),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  const QuickAction({super.key, required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      child: Column(
        children: [
          IconBadge(icon: icon, color: c, size: 36),
          AppSpacing.gapSm,
          Text(label,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
