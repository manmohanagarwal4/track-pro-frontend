import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../data/models/app_settings.dart';

class SettingsController extends Notifier<AppSettings> {
  static const _key = 'settings';

  @override
  AppSettings build() {
    final json = ref.watch(localStoreProvider).readJson(_key);
    final settings = json is Map<String, dynamic> ? AppSettings.fromJson(json) : const AppSettings();
    ref.read(mockLatencyProvider).errorsEnabled = settings.simulateErrors;
    return settings;
  }

  void update(AppSettings Function(AppSettings s) change) {
    state = change(state);
    ref.read(localStoreProvider).writeJson(_key, state.toJson());
    ref.read(mockLatencyProvider).errorsEnabled = state.simulateErrors;
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
