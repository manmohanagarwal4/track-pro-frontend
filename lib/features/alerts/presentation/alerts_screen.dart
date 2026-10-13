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
import '../../../core/widgets/status_widgets.dart';
import '../../../data/models/alert.dart';
import '../../../data/models/enums.dart';
import '../../devices/presentation/widgets/device_card.dart';
import '../../map/presentation/widgets/tracker_map.dart';
import '../application/alerts_controller.dart';

bool matchesAlertFilter(TrackerAlert a, AlertFilter f) => switch (f) {
      AlertFilter.all => true,
      AlertFilter.unread => !a.read,
      AlertFilter.overspeed => a.type == AlertType.overspeed,
      AlertFilter.geofence => a.type == AlertType.geofenceEnter || a.type == AlertType.geofenceExit,
      AlertFilter.battery => a.type == AlertType.lowBattery,
      AlertFilter.offline => a.type == AlertType.offline || a.type == AlertType.online,
      AlertFilter.emergency => a.type == AlertType.emergency,
    };

String severityLabel(AlertSeverity s) => switch (s) {
      AlertSeverity.critical => 'Critical',
      AlertSeverity.warning => 'Warning',
      AlertSeverity.info => 'Info',
    };

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  AlertFilter _filter = AlertFilter.all;

  void _delete(TrackerAlert a) {
    ref.read(alertsProvider.notifier).delete(a.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Alert deleted'),
        action: SnackBarAction(label: 'Undo', onPressed: () => ref.read(alertsProvider.notifier).restore(a)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alerts = ref.watch(visibleAlertsProvider);
    final unread = ref.watch(unreadAlertCountProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.xs, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(child: Text('Alerts', style: theme.textTheme.headlineMedium)),
                    TextButton(
                      key: const Key('mark-all-read'),
                      onPressed: unread == 0 ? null : () => ref.read(alertsProvider.notifier).markAllRead(),
                      child: const Text('Mark all read'),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(AppIcons.more, color: context.tones.neutral400),
                      onSelected: (v) {
                        if (v == 'clear') ref.read(alertsProvider.notifier).clearRead();
                        if (v == 'notifications') context.push(Routes.notifications);
                        if (v == 'settings') context.push(Routes.settingsSection('notifications'));
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'clear', child: Text('Clear read alerts')),
                        PopupMenuItem(value: 'notifications', child: Text('Notification center')),
                        PopupMenuItem(value: 'settings', child: Text('Alert settings')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AsyncView<List<TrackerAlert>>(
                value: alerts,
                onRetry: () => ref.invalidate(alertsProvider),
                loading: const SkeletonList(message: 'Loading alerts...'),
                data: (all) {
                  final counts = {
                    for (final f in AlertFilter.values) f: all.where((a) => matchesAlertFilter(a, f)).length,
                  };
                  final list = all.where((a) => matchesAlertFilter(a, _filter)).toList();
                  return ResponsiveCenter(
                    child: Column(
                      children: [
                        ChipFilterBar<AlertFilter>(
                          values: AlertFilter.values,
                          selected: _filter,
                          label: (f) => f.label,
                          counts: counts,
                          onSelected: (f) => setState(() => _filter = f),
                        ),
                        AppSpacing.gapMd,
                        Expanded(
                          child: list.isEmpty
                              ? const EmptyView(
                                  icon: AppIcons.success,
                                  title: 'You\'re all caught up',
                                  message: 'New alerts from your devices will appear here.',
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.bottomSafe),
                                  itemCount: list.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final a = list[i];
                                    return Dismissible(
                                      key: ValueKey(a.id),
                                      direction: DismissDirection.endToStart,
                                      background: const DeleteSwipeBackground(),
                                      onDismissed: (_) => _delete(a),
                                      child: AlertCard(
                                        alert: a,
                                        onTap: () {
                                          ref.read(alertsProvider.notifier).markRead(a.id);
                                          showAlertDetail(context, a);
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Swipe-to-delete ground for alert / notification rows.
class DeleteSwipeBackground extends StatelessWidget {
  const DeleteSwipeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      decoration: BoxDecoration(color: tones.critBg, borderRadius: AppRadius.lgAll),
      child: Icon(AppIcons.delete, color: tones.critInk),
    );
  }
}

/// Severity-tinted row used by alerts and notifications: a 38px tonal icon
/// tile, title + time, a body line and a small tag. Unread rows get a 1px
/// ring in the severity color.
class AlertRowTile extends StatelessWidget {
  const AlertRowTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
    required this.body,
    required this.tag,
    this.extraTag,
    this.unread = false,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final DateTime time;
  final String body;
  final String tag;
  final String? extraTag;
  final bool unread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final sev = tones.tag(color);
    Widget smallTag(String label) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(color: sev.bg, borderRadius: BorderRadius.circular(6)),
          child: Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: sev.ink)),
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        boxShadow: unread ? [BoxShadow(color: tones.tone(color), spreadRadius: 1)] : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: sev.bg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 19, color: sev.ink),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                style: theme.textTheme.titleSmall?.copyWith(fontSize: 15, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 6),
                          TimeAgoText(time,
                              short: true,
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(body, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, color: tones.neutral300)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [smallTag(tag), if (extraTag != null) smallTag(extraTag!)],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, this.onTap});

  final TrackerAlert alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AlertRowTile(
      key: Key('alert-${alert.id}'),
      icon: AppIcons.alert(alert.type),
      color: StatusStyle.alert(alert.type, alert.severity),
      title: alert.title,
      time: alert.timestamp,
      body: alert.message,
      tag: severityLabel(alert.severity),
      extraTag: alert.value,
      unread: !alert.read,
      onTap: onTap,
    );
  }
}

Future<void> showAlertDetail(BuildContext context, TrackerAlert alert) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => _AlertDetail(alert: alert),
    );

class _AlertDetail extends ConsumerStatefulWidget {
  const _AlertDetail({required this.alert});

  final TrackerAlert alert;

  @override
  ConsumerState<_AlertDetail> createState() => _AlertDetailState();
}

class _AlertDetailState extends ConsumerState<_AlertDetail> {
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
    final a = widget.alert;
    final color = StatusStyle.alert(a.type, a.severity);
    final sev = tones.tag(color);
    final facts = <(String, String)>[
      ('Device', a.deviceName),
      ('Time', Fmt.dateTime(a.timestamp)),
      if (a.value != null) ('Reading', a.value!),
      ('Severity', severityLabel(a.severity)),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (a.position != null) ...[
              ClipRRect(
                borderRadius: AppRadius.lgAll,
                child: SizedBox(
                  height: 180,
                  child: Stack(
                    children: [
                      TrackerMap(
                        controller: _controller,
                        initialCenter: a.position,
                        initialZoom: 14,
                        showUserLocation: false,
                        layersAboveDevices: [
                          MarkerLayer(markers: [
                            Marker(
                              point: a.position!,
                              width: 36,
                              height: 36,
                              child: Icon(AppIcons.pin, color: tones.tone(color), size: 34),
                            ),
                          ]),
                        ],
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 40,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  theme.scaffoldBackgroundColor.withValues(alpha: 0),
                                  theme.scaffoldBackgroundColor,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: sev.bg, borderRadius: AppRadius.lgAll),
                  child: Icon(AppIcons.alert(a.type), size: 24, color: sev.ink),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pill(label: severityLabel(a.severity), color: color),
                      const SizedBox(height: 4),
                      Text(a.title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 21)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(a.message, style: theme.textTheme.bodyMedium?.copyWith(color: tones.neutral300)),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Column(
                children: [
                  for (var i = 0; i < facts.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: i == facts.length - 1
                          ? null
                          : BoxDecoration(border: Border(bottom: BorderSide(color: tones.divider))),
                      child: Row(
                        children: [
                          Text(facts[i].$1,
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.neutral500)),
                          AppSpacing.gapMd,
                          Expanded(
                            child: Text(facts[i].$2,
                                textAlign: TextAlign.right, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(alertsProvider.notifier).markRead(a.id, read: false);
                      Navigator.pop(context);
                    },
                    child: const Text('Mark unread'),
                  ),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(Routes.device(a.deviceId));
                    },
                    child: Text('Open ${a.deviceName}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
