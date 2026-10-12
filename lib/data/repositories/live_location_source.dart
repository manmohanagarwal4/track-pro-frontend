import '../models/device_location.dart';

/// A realtime update for one device: a new fix and/or a connection change.
class LiveUpdate {
  const LiveUpdate({required this.deviceId, required this.connected, this.location});

  final String deviceId;
  final bool connected;
  final DeviceLocation? location;
}

/// Source of realtime device positions.
///
/// Implemented today by the local GPS simulation. Later this can be backed by
/// a WebSocket / MQTT stream from the tracking backend without touching the UI.
abstract interface class LiveLocationSource {
  /// Batched updates (one list per delivery).
  Stream<List<LiveUpdate>> get updates;

  bool get isRunning;

  void start();
  void stop();
  void pause();

  /// Resumes delivery. When [catchUp] is true the source fast-forwards to
  /// the present, as a backend would deliver queued positions after a reconnect.
  void resume({bool catchUp = true});

  /// Positions of one device only.
  Stream<DeviceLocation> watchDevice(String deviceId);
}
