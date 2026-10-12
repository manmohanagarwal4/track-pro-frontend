import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../data/models/alert.dart';
import '../../../data/models/enums.dart';
import '../../auth/application/session_controller.dart';
import '../../devices/application/devices_controller.dart';
import '../../settings/application/settings_controller.dart';

class AlertsController extends AsyncNotifier<List<TrackerAlert>> {
  static const maxAlerts = 300;

  @override
  Future<List<TrackerAlert>> build() async {
    final list = await ref.watch(alertRepositoryProvider).getAlerts();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  void _commit(List<TrackerAlert> list) {
    state = AsyncData(list);
    ref.read(alertRepositoryProvider).saveAlerts(list);
  }

  /// Adds alerts produced by the rules engine (newest first).
  void addAll(List<TrackerAlert> alerts) {
    if (alerts.isEmpty) return;
    final current = state.value;
    if (current == null) return;
    final settings = ref.read(settingsProvider);
    final list = [...alerts.reversed, ...current];
    _commit(list.length > maxAlerts ? list.sublist(0, maxAlerts) : list);

    final notify = alerts.where((a) => settings.allowsAlert(a.type)).toList();
    ref.read(notificationsProvider.notifier).addAll([
      for (final a in notify)
        AppNotification(
          id: 'n-${a.id}',
          category: NotificationCategory.alerts,
          title: a.title,
          body: a.value == null ? a.message : '${a.message} ${a.value}',
          timestamp: a.timestamp,
          deviceId: a.deviceId,
        ),
    ]);
    if (settings.inAppBanners) {
      final important = notify.where((a) => a.severity != AlertSeverity.info).toList();
      if (important.isNotEmpty) ref.read(alertBannerProvider.notifier).show(important.last);
    }
  }

  void markRead(String id, {bool read = true}) => _commit([
        for (final a in state.value ?? const <TrackerAlert>[]) a.id == id ? a.copyWith(read: read) : a,
      ]);

  void markAllRead() =>
      _commit([for (final a in state.value ?? const <TrackerAlert>[]) a.copyWith(read: true)]);

  void delete(String id) =>
      _commit([...?state.value?.where((a) => a.id != id)]);

  void restore(TrackerAlert alert) {
    final list = [...?state.value, alert]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _commit(list);
  }

  void clearRead() => _commit([...?state.value?.where((a) => !a.read)]);
}

final alertsProvider =
    AsyncNotifierProvider<AlertsController, List<TrackerAlert>>(AlertsController.new);

/// Alerts for devices in the current workspace (Personal hides fleet alerts).
final visibleAlertsProvider = Provider<AsyncValue<List<TrackerAlert>>>((ref) {
  final alerts = ref.watch(alertsProvider);
  if (ref.watch(accountTypeProvider) == AccountType.business) return alerts;
  final ids = ref.watch(deviceViewsProvider.select((v) => v.value?.map((d) => d.id).join(',')));
  if (ids == null) return alerts;
  final visible = ids.split(',').toSet();
  return alerts.whenData((list) => list.where((a) => visible.contains(a.deviceId)).toList());
});

final unreadAlertCountProvider = Provider<int>(
  (ref) => ref.watch(visibleAlertsProvider.select((s) => s.value?.where((a) => !a.read).length ?? 0)),
);

class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final list = await ref.watch(alertRepositoryProvider).getNotifications();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  void _commit(List<AppNotification> list) {
    state = AsyncData(list.length > 200 ? list.sublist(0, 200) : list);
    ref.read(alertRepositoryProvider).saveNotifications(state.value!);
  }

  void add(AppNotification n) => addAll([n]);

  void addAll(List<AppNotification> items) {
    final current = state.value;
    if (current == null || items.isEmpty) return;
    _commit([...items.reversed, ...current]);
  }

  void markRead(String id) => _commit([
        for (final n in state.value ?? const <AppNotification>[]) n.id == id ? n.copyWith(read: true) : n,
      ]);

  void markAllRead() =>
      _commit([for (final n in state.value ?? const <AppNotification>[]) n.copyWith(read: true)]);

  void delete(String id) => _commit([...?state.value?.where((n) => n.id != id)]);
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(NotificationsController.new);

final unreadNotificationCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider.select((s) => s.value?.where((n) => !n.read).length ?? 0)),
);

/// The latest alert to surface as an in-app banner (throttled).
class AlertBannerController extends Notifier<TrackerAlert?> {
  DateTime? _lastShown;

  @override
  TrackerAlert? build() => null;

  void show(TrackerAlert alert) {
    final now = clock.now();
    if (_lastShown != null && now.difference(_lastShown!) < const Duration(seconds: 8)) return;
    _lastShown = now;
    state = alert;
  }

  void dismiss() => state = null;
}

final alertBannerProvider =
    NotifierProvider<AlertBannerController, TrackerAlert?>(AlertBannerController.new);
