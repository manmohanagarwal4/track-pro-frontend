import 'dart:async';
import 'package:clock/clock.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityState {
  const ConnectivityState({this.offline = false, this.syncing = false, this.lastSyncedAt});

  final bool offline;
  final bool syncing;
  final DateTime? lastSyncedAt;

  bool get live => !offline && !syncing;
}

/// Demo toggle that simulates losing connectivity to the tracking backend.
class ConnectivityController extends Notifier<ConnectivityState> {
  Timer? _syncTimer;

  @override
  ConnectivityState build() {
    ref.onDispose(() => _syncTimer?.cancel());
    return ConnectivityState(lastSyncedAt: clock.now());
  }

  void setOffline(bool offline) {
    if (offline == state.offline) return;
    _syncTimer?.cancel();
    if (offline) {
      state = ConnectivityState(offline: true, lastSyncedAt: clock.now());
    } else {
      state = ConnectivityState(syncing: true, lastSyncedAt: state.lastSyncedAt);
      _syncTimer = Timer(const Duration(milliseconds: 1600), () {
        state = ConnectivityState(lastSyncedAt: clock.now());
      });
    }
  }
}

final connectivityProvider =
    NotifierProvider<ConnectivityController, ConnectivityState>(ConnectivityController.new);
