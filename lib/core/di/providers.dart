import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_store.dart';
import '../../data/mock/geo/route_engine.dart';
import '../../data/mock/mock_backend.dart';
import '../../data/mock/mock_repositories.dart';
import '../../data/mock/simulation/location_simulation_service.dart';
import '../../data/repositories/live_location_source.dart';
import '../../data/repositories/repositories.dart';
import '../map/map_service.dart';
import '../map/simulated_map_service.dart';

/// Dependency wiring. Swap the Mock* implementations for Api* ones here when
/// the backend is ready; nothing in the UI needs to change.

final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider must be overridden in main()'),
);

final mockLatencyProvider = Provider<MockLatency>((ref) => MockLatency());

final mockBackendProvider = Provider<MockBackend>((ref) {
  final backend = MockBackend(
    store: ref.watch(localStoreProvider),
    latency: ref.watch(mockLatencyProvider),
  )..init();
  ref.onDispose(backend.dispose);
  return backend;
});

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => MockAuthRepository(ref.watch(mockBackendProvider)));

final trackingRepositoryProvider =
    Provider<TrackingRepository>((ref) => MockTrackingRepository(ref.watch(mockBackendProvider)));

final assetRepositoryProvider =
    Provider<AssetRepository>((ref) => MockAssetRepository(ref.watch(mockBackendProvider)));

final driverRepositoryProvider =
    Provider<DriverRepository>((ref) => MockDriverRepository(ref.watch(mockBackendProvider)));

final geofenceRepositoryProvider =
    Provider<GeofenceRepository>((ref) => MockGeofenceRepository(ref.watch(mockBackendProvider)));

final alertRepositoryProvider =
    Provider<AlertRepository>((ref) => MockAlertRepository(ref.watch(mockBackendProvider)));

final shareRepositoryProvider =
    Provider<ShareRepository>((ref) => MockShareRepository(ref.watch(mockBackendProvider)));

/// Realtime positions. Later: a WebSocket/MQTT-backed implementation.
final liveLocationSourceProvider =
    Provider<LiveLocationSource>((ref) => ref.watch(mockBackendProvider).simulation);

/// Demo-only controls for the local simulation (speed multiplier).
final simulationServiceProvider =
    Provider<LocationSimulationService>((ref) => ref.watch(mockBackendProvider).simulation);

final mapServiceProvider = Provider<MapService>((ref) => const SimulatedMapService());

/// Reverse geocoding (place names). Mock: nearest known place in NCR.
final placeResolverProvider = Provider<PlaceResolver>((ref) => const PlaceResolver());
