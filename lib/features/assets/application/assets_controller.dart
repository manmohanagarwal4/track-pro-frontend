import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../data/models/asset.dart';

class AssetsController extends AsyncNotifier<List<Asset>> {
  @override
  Future<List<Asset>> build() => ref.watch(assetRepositoryProvider).getAssets();

  Future<Asset> save(Asset asset) async {
    final saved = await ref.read(assetRepositoryProvider).saveAsset(asset);
    final list = [...?state.value];
    final i = list.indexWhere((a) => a.id == saved.id);
    if (i >= 0) {
      list[i] = saved;
    } else {
      list.add(saved);
    }
    state = AsyncData(list);
    return saved;
  }

  Future<void> delete(String id) async {
    await ref.read(assetRepositoryProvider).deleteAsset(id);
    state = AsyncData([...?state.value?.where((a) => a.id != id)]);
  }

  /// Local insert after the tracking repository created an asset.
  void upsertLocal(Asset asset) {
    final list = [...?state.value];
    final i = list.indexWhere((a) => a.id == asset.id);
    if (i >= 0) {
      list[i] = asset;
    } else {
      list.add(asset);
    }
    state = AsyncData(list);
  }
}

final assetsProvider = AsyncNotifierProvider<AssetsController, List<Asset>>(AssetsController.new);
