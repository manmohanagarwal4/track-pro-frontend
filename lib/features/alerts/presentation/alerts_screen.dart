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
    final alerts = ref.watch(visibleAlertsProvider);
    final unread = ref.watch(unreadAlertCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          TextButton(
            key: const Key('mark-all-read'),
            onPressed: unread == 0 ? null : () => ref.read(alertsProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          ),
          PopupMenuButton<String>(
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
      body: AsyncView<List<TrackerAlert>>(
        value: alerts,
        onRetry: () => ref.invalidate(alertsProvider),
        loading: const SkeletonList(message: 'Loading alerts...'),
        data: (all) {
          final counts = {for (final f in AlertFilter.values) f: all.where((a) => matchesAlertFilter(a, f)).length};
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
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.bottomSafe),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => AppSpacing.gapMd,
                          itemBuilder: (_, i) {
                            final a = list[i];
                            return Dismissible(
                              key: ValueKey(a.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: AppSpacing.xl),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  borderRadius: AppRadius.lgAll,
                                ),
                                child: const Icon(AppIcons.delete, color: Colors.white),
                              ),
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
    );
  }
}

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, this.onTap});

  final TrackerAlert alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = StatusStyle.alert(alert.type, alert.severity);
    return AppCard(
      key: Key('alert-${alert.id}'),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: AppIcons.alert(alert.type), color: color, size: 42),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(alert.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: alert.read ? FontWeight.w500 : FontWeight.w700,
                          )),
                    ),
                    TimeAgoText(alert.timestamp,
                        short: true,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    if (!alert.read) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(alert.message, style: theme.textTheme.bodyMedium),
                if (alert.value != null) ...[
                  const SizedBox(height: 4),
                  Pill(label: alert.value!, color: color),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showAlertDetail(BuildContext context, TrackerAlert alert) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
    final a = widget.alert;
    final color = StatusStyle.alert(a.type, a.severity);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconBadge(icon: AppIcons.alert(a.type), color: color, size: 48),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: theme.textTheme.titleLarge?.copyWith(color: color)),
                      Text(Fmt.dateTime(a.timestamp), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (a.value != null) Text(a.value!, style: theme.textTheme.titleLarge),
              ],
            ),
            AppSpacing.gapLg,
            Text(a.message, style: theme.textTheme.bodyLarge),
            if (a.position != null) ...[
              AppSpacing.gapLg,
              ClipRRect(
                borderRadius: AppRadius.lgAll,
                child: SizedBox(
                  height: 180,
                  child: TrackerMap(
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
                          child: Icon(AppIcons.pin, color: color, size: 34),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
            AppSpacing.gapLg,
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
                AppSpacing.gapMd,
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
