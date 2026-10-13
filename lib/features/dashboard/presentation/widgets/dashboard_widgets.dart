import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_shadows.dart';
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

/// Screen title for tab roots (28px, w500) with optional trailing actions.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.subtitle, this.actions = const []});

  final String title;
  final Widget? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle.merge(
                    style: TextStyle(fontSize: 13, color: context.tones.neutral500),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Small KPI tile: value above a status dot and label.
class SummaryTile extends StatelessWidget {
  const SummaryTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String label;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    return AppCard(
      onTap: onTap,
      radius: AppRadius.mdAll,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: value.toDouble()),
            duration: AppDurations.slow,
            builder: (_, v, _) =>
                Text('${v.round()}', style: AppTypography.metric.copyWith(fontSize: 19, letterSpacing: -0.2)),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: tones.tone(color), shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: tones.neutral500)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Equal-width row of [SummaryTile]s (`is.devices` business KPIs).
class KpiRow extends StatelessWidget {
  const KpiRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: children[i]),
          ],
        ],
      );
}

/// Uppercase group label with an optional count / action on the right.
class GroupLabel extends StatelessWidget {
  const GroupLabel(this.label, {super.key, this.trailing, this.action, this.onAction, this.uppercase = true});

  final String label;
  final String? trailing;
  final String? action;
  final VoidCallback? onAction;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.overline.copyWith(color: tones.neutral500),
            ),
          ),
          if (trailing != null) Text(trailing!, style: TextStyle(fontSize: 12, color: tones.neutral500)),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// One row of a grouped surface list: the first / last rows round the
/// tile's corners and rows are split by a 1px divider.
class GroupedItem extends StatelessWidget {
  const GroupedItem({
    super.key,
    required this.child,
    this.first = true,
    this.last = true,
    this.color,
    this.inset = AppSpacing.md,
  });

  final Widget child;
  final bool first;
  final bool last;
  final Color? color;
  final double inset;

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(AppRadius.lg);
    return Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.vertical(top: first ? r : Radius.zero, bottom: last ? r : Radius.zero),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(top: first ? 2 : 0, bottom: last ? 2 : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            child,
            if (!last) Divider(height: 1, thickness: 1, indent: inset, endIndent: inset, color: context.tones.divider),
          ],
        ),
      ),
    );
  }
}

/// A single surface tile holding divider-separated rows.
class GroupedTile extends StatelessWidget {
  const GroupedTile({super.key, required this.children, this.color, this.inset = AppSpacing.md});

  final List<Widget> children;
  final Color? color;
  final double inset;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++)
            GroupedItem(
              first: i == 0,
              last: i == children.length - 1,
              color: color,
              inset: inset,
              child: children[i],
            ),
        ],
      );
}

/// Facts-list row: neutral icon, muted key, value on the right.
class FactRow extends StatelessWidget {
  const FactRow({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: tones.neutral400),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: tones.neutral400))),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Outlined pill filter with a status dot and a muted count.
class DotFilterChip extends StatelessWidget {
  const DotFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    return Material(
      color: selected ? theme.colorScheme.primary.withValues(alpha: 0.08) : AppColors.transparent,
      shape: StadiumBorder(side: BorderSide(color: selected ? theme.colorScheme.primary : tones.divider)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: tones.tone(color!), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
              if (count != null) ...[
                const SizedBox(width: 5),
                Text('$count',
                    style: TextStyle(fontSize: 12, color: tones.neutral500, fontFeatures: AppTypography.tabular)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling row of [DotFilterChip]s.
class DotFilterBar<T> extends StatelessWidget {
  const DotFilterBar({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.color,
    this.count,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final Color? Function(T)? color;
  final int? Function(T)? count;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: AppSpacing.screen,
          itemCount: values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final v = values[i];
            return DotFilterChip(
              label: label(v),
              selected: v == selected,
              color: color?.call(v),
              count: count?.call(v),
              onTap: () => onSelected(v),
            );
          },
        ),
      );
}

/// Translucent control floating over a map.
class GlassPill extends StatelessWidget {
  const GlassPill({super.key, required this.child, this.onTap, this.height = 36});

  final Widget child;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: AppRadius.lgAll, boxShadow: AppShadows.hairline(theme.brightness)),
      child: Material(
        color: context.tones.glass,
        borderRadius: AppRadius.lgAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            alignment: Alignment.center,
            child: DefaultTextStyle.merge(
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
              child: IconTheme.merge(
                data: IconThemeData(size: 16, color: theme.colorScheme.onSurface),
                child: child,
              ),
            ),
          ),
        ),
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
    final tones = context.tones;
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
              child: GlassPill(
                height: 30,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusDot(color: running ? tones.ok : tones.neutral500, pulse: running, size: 7),
                    const SizedBox(width: 6),
                    Text(running ? 'LIVE' : 'PAUSED',
                        style: const TextStyle(fontSize: 11, letterSpacing: 0.9, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: GlassPill(
                onTap: () => context.go(Routes.map),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.map),
                    SizedBox(width: 6),
                    Text('Open map', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
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
    final tones = context.tones;
    final on = ref.watch(settingsProvider.select((s) => s.liveSimulation));
    final speed = ref.watch(settingsProvider.select((s) => s.simulationSpeed));
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          Icon(AppIcons.navigation, size: 19, color: on ? tones.ok : tones.neutral400),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Live Simulation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(
                  on ? 'Devices are moving · ${speed == 1 ? 'real time' : '${speed.toStringAsFixed(0)}x speed'}' : 'Paused · positions frozen',
                  style: TextStyle(fontSize: 12, color: tones.neutral500),
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
    final tones = context.tones;
    final segments = [
      ('Moving', counts.moving, tones.ok),
      ('Idle', counts.idle, AppColors.idle),
      ('Stopped', counts.stopped, AppColors.stationary),
      ('Offline', counts.offline, tones.neutral600),
    ];
    final total = counts.total == 0 ? 1 : counts.total;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Fleet utilisation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              Text('${(counts.moving / total * 100).round()}% active',
                  style: TextStyle(fontSize: 12, color: tones.ok, fontFeatures: AppTypography.tabular)),
            ],
          ),
          AppSpacing.gapMd,
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: SizedBox(
              height: 6,
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
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('${s.$1} ${s.$2}', style: TextStyle(fontSize: 11, color: tones.neutral500)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Action-grid tile: accent icon above a short label.
class QuickAction extends StatelessWidget {
  const QuickAction({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: AppRadius.mdAll,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      child: Column(
        children: [
          Icon(icon, size: 22, color: context.tones.accent300),
          const SizedBox(height: 6),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
