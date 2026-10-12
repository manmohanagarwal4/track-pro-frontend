import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../auth/application/session_controller.dart';
import '../../settings/application/settings_controller.dart';
import 'connectivity_controller.dart';

class LiveTrackingState {
  const LiveTrackingState({required this.running, this.pausedAt});

  final bool running;

  /// When updates stopped flowing; status is evaluated against this time so
  /// devices don't appear to go offline while the feed is paused.
  final DateTime? pausedAt;
}

/// Starts / pauses the realtime feed based on session, the Live Simulation
/// setting and (simulated) connectivity.
class LiveTrackingController extends Notifier<LiveTrackingState> {
  @override
  LiveTrackingState build() {
    final signedIn = ref.watch(sessionProvider.select((s) => s.value != null));
    final live = ref.watch(settingsProvider.select((s) => s.liveSimulation));
    final speed = ref.watch(settingsProvider.select((s) => s.simulationSpeed));
    final connected = ref.watch(connectivityProvider.select((c) => c.live));
    final source = ref.watch(liveLocationSourceProvider);
    ref.watch(simulationServiceProvider).setTimeScale(speed);

    final shouldRun = signedIn && live && connected;
    if (shouldRun) {
      source.resume(catchUp: true);
      return const LiveTrackingState(running: true);
    }
    final previous = stateOrNull;
    source.pause();
    return LiveTrackingState(
      running: false,
      pausedAt: previous?.pausedAt ?? clock.now(),
    );
  }
}

final liveTrackingProvider =
    NotifierProvider<LiveTrackingController, LiveTrackingState>(LiveTrackingController.new);

/// Reference time for status evaluation (frozen while the feed is paused).
final statusClockProvider = Provider<DateTime?>(
  (ref) => ref.watch(liveTrackingProvider.select((s) => s.running ? null : s.pausedAt)),
);
