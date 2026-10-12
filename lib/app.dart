import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/global_banners.dart';
import 'features/settings/application/settings_controller.dart';
import 'features/tracking/application/live_tracking_controller.dart';

class TrackProApp extends ConsumerWidget {
  const TrackProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    // Keeps the realtime feed in sync with session / settings / connectivity.
    ref.watch(liveTrackingProvider);

    return MaterialApp.router(
      title: 'TrackPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => GlobalBanners(child: child ?? const SizedBox.shrink()),
    );
  }
}
