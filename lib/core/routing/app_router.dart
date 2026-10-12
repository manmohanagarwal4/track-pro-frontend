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
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.listen(accountTypeProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  NoTransitionPage<void> tab(Widget child, GoRouterState s) =>
      NoTransitionPage(key: s.pageKey, child: child);

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
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
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
      GoRoute(path: Routes.addDevice, builder: (_, _) => const AddDeviceScreen()),
      GoRoute(
        path: '/device/:id',
        builder: (_, s) => DeviceDetailsScreen(deviceId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'history',
            builder: (_, s) => HistoryScreen(deviceId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'trips',
            builder: (_, s) => TripsScreen(deviceId: s.pathParameters['id']!),
            routes: [
              GoRoute(
                path: ':tripId',
                builder: (_, s) => TripDetailScreen(
                  deviceId: s.pathParameters['id']!,
                  trip: s.extra is Trip ? s.extra! as Trip : null,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'settings',
            builder: (_, s) => DeviceSettingsScreen(deviceId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'share',
            builder: (_, s) => ShareScreen(deviceId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: Routes.geofences,
        builder: (_, _) => const GeofencesScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, s) => GeofenceEditorScreen(deviceId: s.uri.queryParameters['device']),
          ),
          GoRoute(
            path: ':gid',
            builder: (_, s) => GeofenceEditorScreen(geofenceId: s.pathParameters['gid']),
          ),
        ],
      ),
      GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsScreen()),
      GoRoute(
        path: Routes.drivers,
        builder: (_, _) => const DriversScreen(),
        routes: [
          GoRoute(
            path: ':did',
            builder: (_, s) => DriverDetailScreen(driverId: s.pathParameters['did']!),
          ),
        ],
      ),
      GoRoute(path: Routes.assets, builder: (_, _) => const AssetsScreen()),
      GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: Routes.settings,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: ':section',
            builder: (_, s) => SettingsSectionScreen(section: s.pathParameters['section']!),
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
