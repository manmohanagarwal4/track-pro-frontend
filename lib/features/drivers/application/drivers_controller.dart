import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../data/models/driver.dart';

class DriversController extends AsyncNotifier<List<Driver>> {
  @override
  Future<List<Driver>> build() => ref.watch(driverRepositoryProvider).getDrivers();

  Future<void> _save(Driver driver) async {
    final saved = await ref.read(driverRepositoryProvider).saveDriver(driver);
    state = AsyncData([
      for (final d in state.value ?? const <Driver>[]) d.id == saved.id ? saved : d,
    ]);
  }

  /// Assigns [driverId] to [assetId]; any driver already on that vehicle is
  /// unassigned first (one driver per vehicle).
  Future<void> assign(String driverId, String assetId) async {
    final drivers = state.value ?? const <Driver>[];
    for (final d in drivers) {
      if (d.assetId == assetId && d.id != driverId) {
        await _save(d.copyWith(clearAsset: true));
      }
    }
    final driver = (state.value ?? drivers).firstWhere((d) => d.id == driverId);
    await _save(driver.copyWith(assetId: assetId));
  }

  /// Mirrors a server-side cascade after an asset was deleted.
  void detachAssetLocal(String assetId) {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([for (final d in list) d.assetId == assetId ? d.copyWith(clearAsset: true) : d]);
  }

  Future<void> unassign(String driverId) async {
    final driver = (state.value ?? const <Driver>[]).firstWhere((d) => d.id == driverId);
    await _save(driver.copyWith(clearAsset: true));
  }

  /// Errors (e.g. duplicate phone / licence) are rethrown for the form.
  Future<Driver> create({required String name, required String phone, required String licenseNo}) async {
    final driver = await ref
        .read(driverRepositoryProvider)
        .createDriver(name: name, phone: phone, licenseNo: licenseNo);
    state = AsyncData([...?state.value, driver]);
    return driver;
  }

  Future<void> edit(Driver driver) => _save(driver);

  /// Deleting a driver frees their vehicle.
  Future<void> delete(String driverId) async {
    await ref.read(driverRepositoryProvider).deleteDriver(driverId);
    state = AsyncData([...?state.value?.where((d) => d.id != driverId)]);
  }

  /// Restores a deleted driver (Undo). Keeps id and history; vehicle stays free.
  Future<void> restore(Driver driver) async {
    final saved = await ref.read(driverRepositoryProvider).saveDriver(driver.copyWith(clearAsset: true));
    state = AsyncData([...?state.value, saved]);
  }
}

final driversProvider =
    AsyncNotifierProvider<DriversController, List<Driver>>(DriversController.new);
