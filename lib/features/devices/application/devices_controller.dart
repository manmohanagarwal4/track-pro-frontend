import 'dart:async';
import 'package:clock/clock.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../data/models/alert.dart';
import '../../../data/models/asset.dart';
import '../../../data/models/driver.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/tracker_device.dart';
import '../../../data/repositories/live_location_source.dart';
import '../../../data/repositories/repositories.dart';
import '../../../domain/alert_rules_engine.dart';
import '../../../domain/device_status_engine.dart';
import '../../../domain/device_view.dart';
import '../../alerts/application/alerts_controller.dart';
import '../../assets/application/assets_controller.dart';
import '../../auth/application/session_controller.dart';
import '../../drivers/application/drivers_controller.dart';
import '../../geofences/application/geofences_controller.dart';
import '../../tracking/application/live_tracking_controller.dart';

/// Live device state: initial load from the repository, then realtime updates
/// from the [LiveLocationSource]. Also feeds the geofence + alert engines.
class DevicesController extends AsyncNotifier<Map<String, TrackerDevice>> {
  final _rules = AlertRulesEngine();
  StreamSubscription<List<LiveUpdate>>? _sub;

  @override
  Future<Map<String, TrackerDevice>> build() async {
    final repo = ref.watch(trackingRepositoryProvider);
    final source = ref.watch(liveLocationSourceProvider);
    await _sub?.cancel();
    final devices = await repo.getDevices();
    _sub = source.updates.listen(_onUpdates);
    ref.onDispose(() => _sub?.cancel());
    return {for (final d in devices) d.id: d};
  }

  TrackingRepository get _repo => ref.read(trackingRepositoryProvider);

  void _onUpdates(List<LiveUpdate> batch) {
    final current = state.value;
    if (current == null || !ref.mounted) return;
    final next = Map.of(current);
    final changed = <String>[];
    for (final u in batch) {
      final d = next[u.deviceId];
      if (d == null) continue;
      final loc = u.location;
      var addKm = 0.0;
      final prevPos = d.location?.position;
      if (loc != null && prevPos != null && loc.speedKmh > 1) {
        final km = GeoUtils.distanceKm(prevPos, loc.position);
        if (km < 80) addKm = km;
      }
      next[u.deviceId] = d.copyWith(
        connected: u.connected,
        location: loc,
        lastSeen: loc?.timestamp,
        tripDistanceKm: d.tripDistanceKm + addKm,
        odometerKm: d.odometerKm + addKm,
      );
      changed.add(u.deviceId);
    }
    state = AsyncData(next);
    ref.read(liveTrailsProvider.notifier).append(batch);
    _processEvents(current, next, changed);
  }

  void _processEvents(
    Map<String, TrackerDevice> before,
    Map<String, TrackerDevice> after,
    List<String> changed,
  ) {
    final assets = ref.read(assetsProvider).value;
    if (assets == null) return;
    final drivers = ref.read(driversProvider).value ?? const <Driver>[];
    final fences = ref.read(geofencesProvider).value ?? const [];
    final engine = ref.read(geofenceEngineProvider);
    final assetById = {for (final a in assets) a.id: a};
    final now = clock.now();
    final alerts = <TrackerAlert>[];
    for (final id in changed) {
      final prev = before[id];
      final cur = after[id]!;
      final curView = buildDeviceView(cur, assetById, drivers, now);
      final prevView = prev == null ? null : buildDeviceView(prev, assetById, drivers, now);
      final loc = cur.location;
      final events = loc == null || !cur.connected
          ? const <Never>[]
          : engine.evaluate(
              deviceId: id, position: loc.position, timestamp: loc.timestamp, geofences: fences);
      alerts.addAll(
          _rules.evaluate(previous: prevView, current: curView, geofenceEvents: events, now: now));
    }
    if (alerts.isNotEmpty) ref.read(alertsProvider.notifier).addAll(alerts);
  }

  void _put(TrackerDevice d) {
    final map = state.value;
    if (map == null) return;
    state = AsyncData({...map, d.id: d});
  }

  // ------------------------------------------------------------- mutations

  Future<TrackerDevice> add(NewDeviceRequest request) async {
    final result = await _repo.addDevice(request);
    ref.read(assetsProvider.notifier).upsertLocal(result.asset);
    _put(result.device);
    ref.read(notificationsProvider.notifier).add(AppNotification(
          id: 'n-add-${result.device.id}-${clock.now().millisecondsSinceEpoch}',
          category: NotificationCategory.devices,
          title: 'Tracker added',
          body: '${result.asset.name} (${result.device.id}) is now being tracked.',
          timestamp: clock.now(),
          deviceId: result.device.id,
        ));
    return result.device;
  }

  Future<void> updateDevice(TrackerDevice device) async => _put(await _repo.updateDevice(device));

  Future<void> setTrackingMode(String id, TrackingMode mode) async =>
      _put(await _repo.setTrackingMode(id, mode));

  Future<void> setEmergency(String id, bool active) async {
    final before = state.value?[id];
    final updated = await _repo.setEmergency(id, active);
    _put(updated);
    if (before != null) {
      final assets = {for (final a in ref.read(assetsProvider).value ?? const <Asset>[]) a.id: a};
      final drivers = ref.read(driversProvider).value ?? const <Driver>[];
      final now = clock.now();
      ref.read(alertsProvider.notifier).addAll(_rules.evaluate(
            previous: buildDeviceView(before, assets, drivers, now),
            current: buildDeviceView(updated, assets, drivers, now),
            now: now,
          ));
    }
  }

  /// Assign, change or clear (null) the asset a tracker is attached to.
  Future<void> assignAsset(String deviceId, String? assetId) async {
    final d = state.value?[deviceId];
    if (d == null) return;
    // An asset can only carry one tracker: detach it from any other device.
    if (assetId != null) {
      for (final other in state.value!.values.where((o) => o.assetId == assetId && o.id != deviceId)) {
        _put(await _repo.updateDevice(other.copyWith(clearAsset: true)));
      }
    }
    _put(await _repo.updateDevice(
        assetId == null ? d.copyWith(clearAsset: true) : d.copyWith(assetId: assetId)));
  }

  /// Mirrors a server-side cascade after an asset was deleted.
  void detachAssetLocal(String assetId) {
    final map = state.value;
    if (map == null) return;
    state = AsyncData({
      for (final e in map.entries) e.key: e.value.assetId == assetId ? e.value.copyWith(clearAsset: true) : e.value,
    });
  }

  Future<void> remove(String id) async {
    await _repo.removeDevice(id);
    final map = state.value;
    if (map == null) return;
    state = AsyncData({...map}..remove(id));
    ref.read(geofenceEngineProvider).resetDevice(id);
  }
}

final devicesProvider =
    AsyncNotifierProvider<DevicesController, Map<String, TrackerDevice>>(DevicesController.new);

DeviceView buildDeviceView(
  TrackerDevice d,
  Map<String, Asset> assets,
  List<Driver> drivers,
  DateTime now,
) {
  final asset = assets[d.assetId];
  Driver? driver;
  if (asset != null) {
    for (final dr in drivers) {
      if (dr.assetId == asset.id) {
        driver = dr;
        break;
      }
    }
  }
  return DeviceView(
    device: d,
    asset: asset,
    driver: driver,
    status: DeviceStatusEngine.evaluate(d, asset?.type ?? AssetType.generic, now: now),
  );
}

/// All devices joined with assets/drivers and evaluated by the status engine.
final allDeviceViewsProvider = Provider<AsyncValue<List<DeviceView>>>((ref) {
  final devices = ref.watch(devicesProvider);
  final assets = ref.watch(assetsProvider);
  final drivers = ref.watch(driversProvider).value ?? const <Driver>[];
  final now = ref.watch(statusClockProvider) ?? clock.now();
  if (devices.hasError && !devices.hasValue) {
    return AsyncError(devices.error!, devices.stackTrace ?? StackTrace.current);
  }
  final map = devices.value;
  final assetList = assets.value;
  if (map == null || assetList == null) return const AsyncLoading();
  final byId = {for (final a in assetList) a.id: a};
  return AsyncData([for (final d in map.values) buildDeviceView(d, byId, drivers, now)]);
});

/// Devices visible in the current workspace (personal mode hides business assets).
final deviceViewsProvider = Provider<AsyncValue<List<DeviceView>>>((ref) {
  final all = ref.watch(allDeviceViewsProvider);
  final type = ref.watch(accountTypeProvider);
  if (type == AccountType.business) return all;
  return all.whenData((list) => list.where((v) => v.category == AssetCategory.personal).toList());
});

final deviceViewProvider = Provider.family<DeviceView?, String>((ref, id) {
  final list = ref.watch(allDeviceViewsProvider).value;
  if (list == null) return null;
  for (final v in list) {
    if (v.id == id) return v;
  }
  return null;
});

class DashboardCounts {
  const DashboardCounts({
    required this.total,
    required this.online,
    required this.moving,
    required this.idle,
    required this.stopped,
    required this.offline,
    required this.attention,
  });

  final int total, online, moving, idle, stopped, offline, attention;

  static DashboardCounts of(Iterable<DeviceView> views) {
    var online = 0, moving = 0, idle = 0, stopped = 0, offline = 0, attention = 0, total = 0;
    for (final v in views) {
      total++;
      final s = v.status;
      if (s.isOnline) {
        online++;
      } else {
        offline++;
      }
      if (s.isMoving) moving++;
      if (s.primary == DeviceStatus.idle) idle++;
      if (s.primary == DeviceStatus.stopped || s.primary == DeviceStatus.stationary) stopped++;
      if (s.needsAttention) attention++;
    }
    return DashboardCounts(
        total: total, online: online, moving: moving, idle: idle, stopped: stopped,
        offline: offline, attention: attention);
  }
}

/// Recent live positions per device (for trails on the map).
class LiveTrailsController extends Notifier<Map<String, List<LatLng>>> {
  static const maxPoints = 160;

  @override
  Map<String, List<LatLng>> build() => const {};

  void append(List<LiveUpdate> batch) {
    final next = Map<String, List<LatLng>>.of(state);
    var changed = false;
    for (final u in batch) {
      final loc = u.location;
      if (loc == null || loc.speedKmh <= 1) continue;
      final list = [...?next[u.deviceId], loc.position];
      next[u.deviceId] = list.length > maxPoints ? list.sublist(list.length - maxPoints) : list;
      changed = true;
    }
    if (changed) state = next;
  }
}

final liveTrailsProvider =
    NotifierProvider<LiveTrailsController, Map<String, List<LatLng>>>(LiveTrailsController.new);
