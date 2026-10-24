# TrackPro — GPS Tracking Platform (Phase 1: Flutter prototype)

A general-purpose GPS tracking app for personal users (pets, keys, family, personal vehicles) and
businesses (taxis, trucks, delivery vans, fleets, equipment). **Everything runs locally on mock data**:
no backend, API key or network connection is needed.

- Package / bundle ID: `com.trackpro.track` · Display name: **TrackPro**
- Platforms: Android, iOS, Web
- Stack: Flutter 3.47, Riverpod 3, go_router, flutter_map (offline simulated base map), SharedPreferences, mobile_scanner

## Run

```bash
flutter pub get
flutter run -d chrome          # web
flutter run                    # connected Android / iOS device
flutter build web --release    # output: build/web
flutter build apk --release    # output: build/app/outputs/flutter-apk/app-release.apk (needs Android SDK)
```

Sign in with **Continue with Demo Account**, or any email + a password of 4+ characters.

## Demo tips

| What | Where |
|---|---|
| Live Simulation ON/OFF | Dashboard card, or Settings → Tracking |
| Speed up simulated time (2x/5x/10x) | Settings → Tracking Settings |
| Personal ⇄ Business navigation | More → Workspace, or Profile |
| Simulate Offline Mode | More, or Settings → Demo & Developer |
| Simulated load errors (Retry) | Settings → Demo & Developer (on by default, ~8% of loads) |
| Reset everything | Settings → Demo & Developer → Reset demo data |
| Trigger an alert quickly | Device → Geofence (creates a zone around the moving vehicle; it exits within ~30 s) or Device → Activate emergency mode |
| Bruno's battery | Drains in real time; a Low Battery alert fires after about 11 minutes |

## Architecture

```
UI (features/*/presentation)
  ↓
State (Riverpod controllers, features/*/application)
  ↓
Repository interfaces (data/repositories)        ← UI depends only on these
  ↓
Mock repositories + MockBackend (data/mock)       ← swap for Api* implementations later
  ↓
Seed data + GPS simulation engine + history generator
```

- **`lib/core/di/providers.dart`** is the single place where implementations are wired. To connect
  the real backend, implement `TrackingRepository`, `AuthRepository`, etc. as `Api*Repository`, and
  implement `LiveLocationSource` over WebSocket/MQTT. Then change the providers. No UI changes.
- **`LocationSimulationService`** (`data/mock/simulation`) moves every tracker along real routes on a
  Delhi NCR road graph (Dijkstra routing), wander loops (pets/people) or keeps it stationary. It reports
  at each device's tracking-mode interval (Real Time 2s, Normal 5s, Power Saving 15s, Sleep 60s,
  Emergency 1s) and exposes `Stream<List<LiveUpdate>>` / `simulateDeviceMovement(id)`.
- **Domain engines** (`lib/domain`), all pure and unit-tested:
  - `DeviceStatusEngine`: one status model (online/offline/moving/idle/stopped/low battery/no GPS/no network/emergency)
  - `GeofenceEngine`: Haversine point-in-circle with enter/exit transitions
  - `TripCalculator`: distance, duration, average/max speed, stops and idle time from track points
  - `AlertRulesEngine`: overspeed (with cooldown), geofence, low battery, offline/online, emergency
  - `DeviceQuery`: search, filter and sort
- **Map**: `MapService` abstraction (`core/map`). `SimulatedMapService` draws the base map from local
  vector data. Markers glide between fixes (`AnimatedDevicesLayer`) and cluster at low zoom.
- **Persistence**: `LocalStore` (SharedPreferences JSON). Devices, assets, geofences, alerts,
  settings and session survive restarts.
- **Design system**: `core/theme` (`AppColors`, `AppTypography`, `AppSpacing`/`AppRadius`,
  `AppShadows`, `AppIcons` (Lucide), `AppTheme` with Material 3 light and dark).

## Tests

```bash
flutter test                                   # unit + widget + full user-journey tests
flutter test integration_test/app_test.dart    # same journeys on a device/emulator
flutter test tool/generate_icons_test.dart     # regenerate launcher icons from the logo painter
flutter test tool/screenshots_test.dart        # screenshots of key screens -> build/screenshots
```

## Configuration

See `.env.example`. Nothing is required for Phase 1. Values are passed with `--dart-define`.
