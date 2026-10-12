import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../data/models/geofence.dart';
import '../../../domain/geofence_engine.dart';

/// Shared crossing-state so edits can reset it.
final geofenceEngineProvider = Provider<GeofenceEngine>((ref) => GeofenceEngine());

class GeofencesController extends AsyncNotifier<List<Geofence>> {
  @override
  Future<List<Geofence>> build() => ref.watch(geofenceRepositoryProvider).getGeofences();

  Future<Geofence> save(Geofence fence) async {
    final saved = await ref.read(geofenceRepositoryProvider).saveGeofence(fence);
    ref.read(geofenceEngineProvider).resetFence(saved.id);
    final list = [...?state.value];
    final i = list.indexWhere((g) => g.id == saved.id);
    if (i >= 0) {
      list[i] = saved;
    } else {
      list.insert(0, saved);
    }
    state = AsyncData(list);
    return saved;
  }

  Future<void> toggle(String id, bool active) async {
    final fence = state.value?.firstWhere((g) => g.id == id);
    if (fence != null) await save(fence.copyWith(active: active));
  }

  Future<void> delete(String id) async {
    await ref.read(geofenceRepositoryProvider).deleteGeofence(id);
    ref.read(geofenceEngineProvider).resetFence(id);
    state = AsyncData([...?state.value?.where((g) => g.id != id)]);
  }
}

final geofencesProvider =
    AsyncNotifierProvider<GeofencesController, List<Geofence>>(GeofencesController.new);
