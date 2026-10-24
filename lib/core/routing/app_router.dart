import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/enums.dart';
import '../../data/models/trip.dart';
import '../../features/alerts/presentation/alerts_screen.dart';
import '../../features/assets/presentation/assets_screen.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/devices/presentation/add_device_screen.dart';
import '../../features/devices/presentation/device_details_screen.dart';
import '../../features/devices/presentation/device_settings_screen.dart';
import '../../features/devices/presentation/devices_screen.dart';
import '../../features/drivers/presentation/driver_detail_screen.dart';
import '../../features/drivers/presentation/drivers_screen.dart';
import '../../features/fleet/presentation/fleet_screen.dart';
import '../../features/geofences/presentation/geofence_editor_screen.dart';
import '../../features/geofences/presentation/geofences_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/settings/presentation/more_screen.dart';
import '../../features/settings/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/sharing/presentation/share_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/tracking/presentation/history_screen.dart';
import '../../features/trips/presentation/fleet_trips_screen.dart';
import '../../features/trips/presentation/trip_detail_screen.dart';
import '../../features/trips/presentation/trips_screen.dart';
import '../motion/page_transitions.dart';
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.listen(accountTypeProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  CustomTransitionPage<void> tab(Widget child, GoRouterState s) => fadeThroughPage(child, s);

  // Explicit MaterialPages so routes use the theme's page transitions:
  // go_router's MaterialApp auto-detection misses here and would fall back
  // to NoTransitionPage.
  MaterialPage<void> page(Widget child, GoRouterState s) => MaterialPage(key: s.pageKey, child: child);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == Routes.splash) return null;
      final session = ref.read(sessionProvider);
      if (!session.hasValue) return session.hasError ? Routes.login : Routes.splash;
      final user = session.value;
      final public = Routes.publicPaths.contains(loc);
      if (user == null) return public ? null : Routes.login;
      if (public) return Routes.home;
      if (user.accountType == AccountType.personal && (loc == Routes.fleet || loc == Routes.trips)) {
        return Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, pageBuilder: (_, s) => page(const SplashScreen(), s)),
      GoRoute(path: Routes.onboarding, pageBuilder: (_, s) => page(const OnboardingScreen(), s)),
      GoRoute(path: Routes.login, pageBuilder: (_, s) => page(const LoginScreen(), s)),
      GoRoute(path: Routes.register, pageBuilder: (_, s) => page(const RegisterScreen(), s)),
      ShellRoute(
        pageBuilder: (context, state, child) => page(AppShell(location: state.uri.path, child: child), state),
        routes: [
          GoRoute(path: Routes.home, pageBuilder: (_, s) => tab(const DashboardScreen(), s)),
          GoRoute(path: Routes.devices, pageBuilder: (_, s) => tab(const DevicesScreen(), s)),
          GoRoute(
            path: Routes.map,
            pageBuilder: (_, s) => tab(MapScreen(focusDeviceId: s.uri.queryParameters['device']), s),
          ),
          GoRoute(path: Routes.alerts, pageBuilder: (_, s) => tab(const AlertsScreen(), s)),
          GoRoute(path: Routes.more, pageBuilder: (_, s) => tab(const MoreScreen(), s)),
          GoRoute(path: Routes.fleet, pageBuilder: (_, s) => tab(const FleetScreen(), s)),
          GoRoute(path: Routes.trips, pageBuilder: (_, s) => tab(const FleetTripsScreen(), s)),
        ],
      ),
      GoRoute(path: Routes.addDevice, pageBuilder: (_, s) => page(const AddDeviceScreen(), s)),
      GoRoute(
        path: '/device/:id',
        pageBuilder: (_, s) => page(DeviceDetailsScreen(deviceId: s.pathParameters['id']!), s),
        routes: [
          GoRoute(
            path: 'history',
            pageBuilder: (_, s) => page(HistoryScreen(deviceId: s.pathParameters['id']!), s),
          ),
          GoRoute(
            path: 'trips',
            pageBuilder: (_, s) => page(TripsScreen(deviceId: s.pathParameters['id']!), s),
            routes: [
              GoRoute(
                path: ':tripId',
                pageBuilder: (_, s) => page(
                  TripDetailScreen(
                    deviceId: s.pathParameters['id']!,
                    trip: s.extra is Trip ? s.extra! as Trip : null,
                  ),
                  s,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'settings',
            pageBuilder: (_, s) => page(DeviceSettingsScreen(deviceId: s.pathParameters['id']!), s),
          ),
          GoRoute(
            path: 'share',
            pageBuilder: (_, s) => page(ShareScreen(deviceId: s.pathParameters['id']!), s),
          ),
        ],
      ),
      GoRoute(
        path: Routes.geofences,
        pageBuilder: (_, s) => page(const GeofencesScreen(), s),
        routes: [
          GoRoute(
            path: 'new',
            pageBuilder: (_, s) => page(GeofenceEditorScreen(deviceId: s.uri.queryParameters['device']), s),
          ),
          GoRoute(
            path: ':gid',
            pageBuilder: (_, s) => page(GeofenceEditorScreen(geofenceId: s.pathParameters['gid']), s),
          ),
        ],
      ),
      GoRoute(path: Routes.notifications, pageBuilder: (_, s) => page(const NotificationsScreen(), s)),
      GoRoute(
        path: Routes.drivers,
        pageBuilder: (_, s) => page(const DriversScreen(), s),
        routes: [
          GoRoute(
            path: ':did',
            pageBuilder: (_, s) => page(DriverDetailScreen(driverId: s.pathParameters['did']!), s),
          ),
        ],
      ),
      GoRoute(path: Routes.assets, pageBuilder: (_, s) => page(const AssetsScreen(), s)),
      GoRoute(path: Routes.profile, pageBuilder: (_, s) => page(const ProfileScreen(), s)),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (_, s) => page(const SettingsScreen(), s),
        routes: [
          GoRoute(
            path: ':section',
            pageBuilder: (_, s) => page(SettingsSectionScreen(section: s.pathParameters['section']!), s),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
