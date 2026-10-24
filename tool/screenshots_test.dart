// Captures screenshots of key screens with real fonts for design review.
// Run:  flutter test tool/screenshots_test.dart  (writes PNGs to build/screenshots)
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracker/app.dart';
import 'package:tracker/core/di/providers.dart';
import 'package:tracker/core/routing/app_router.dart';
import 'package:tracker/data/local/local_store.dart';
import 'package:tracker/data/mock/mock_backend.dart';
import 'package:tracker/data/mock/mock_seed.dart';
import 'package:tracker/data/models/app_settings.dart';
import 'package:tracker/data/models/enums.dart';

const _out = 'build/screenshots';

Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final dir = '$flutterRoot/bin/cache/artifacts/material_fonts';
  // Also register Roboto as the test fallback family so every text renders.
  for (final family in ['Roboto', 'FlutterTest']) {
    final loader = FontLoader(family);
    for (final w in ['regular', 'medium', 'bold', 'light', 'black']) {
      final f = File('$dir/roboto-$w.ttf');
      if (f.existsSync()) loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
    await loader.load();
  }
  final barlow = FontLoader('Barlow');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    barlow.addFont(rootBundle.load('assets/fonts/Barlow-$w.ttf'));
  }
  await barlow.load();
  final lucide = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'));
  await lucide.load();
}

Future<void> _shot(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _pump(WidgetTester tester, Duration d) async {
  for (var t = Duration.zero; t < d; t += const Duration(milliseconds: 100)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<(GlobalKey, ProviderContainer)> _boot(WidgetTester tester,
    {AccountType type = AccountType.business,
    ThemeMode mode = ThemeMode.light,
    Size size = const Size(400, 860),
    bool signedIn = true,
    bool onboarded = true,
    Duration settle = const Duration(seconds: 3)}) async {
  await tester.runAsync(_loadFonts);
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'tp.settings': jsonEncode(AppSettings(onboardingDone: onboarded, simulateErrors: false, themeMode: mode).toJson()),
    if (signedIn) 'tp.session': jsonEncode(MockSeed.demoUser.copyWith(accountType: type).toJson()),
  });
  final store = await LocalStore.open();
  final key = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(
    key: key,
    child: ProviderScope(
      retry: (_, _) => null,
      overrides: [
        localStoreProvider.overrideWithValue(store),
        mockLatencyProvider.overrideWithValue(MockLatency.none()),
      ],
      child: const TrackProApp(),
    ),
  ));
  await _pump(tester, settle);
  final c = ProviderScope.containerOf(tester.element(find.byType(TrackProApp)));
  return (key, c);
}

void main() {
  testWidgets('business screens (light)', (tester) async {
    final (key, c) = await _boot(tester);
    final router = c.read(routerProvider);
    await _shot(tester, key, '01_dashboard');
    Future<void> go(String path, String name, {bool push = false, Duration wait = const Duration(seconds: 2)}) async {
      push ? router.push(path) : router.go(path);
      await _pump(tester, wait);
      await _shot(tester, key, name);
    }

    await go('/map', '02_map');
    await go('/map?device=TRUCK-001', '03_map_selected', wait: const Duration(seconds: 4));
    await go('/fleet', '04_fleet');
    await go('/trips', '05_trips');
    await go('/alerts', '06_alerts');
    await go('/more', '07_more');
    await go('/device/TRUCK-001', '08_device_details', push: true);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await _pump(tester, const Duration(milliseconds: 600));
    await _shot(tester, key, '09_device_telemetry');
    await go('/device/TRUCK-001/history', '10_history', push: true);
    await go('/device/TRUCK-001/settings', '11_device_settings', push: true);
    await go('/device/TRUCK-001/share', '12_share', push: true);
    await go('/geofences', '13_geofences', push: true);
    await go('/geofences/new?device=TRUCK-001', '14_geofence_editor', push: true);
    await go('/add-device', '15_add_device', push: true);
    await go('/drivers', '16_drivers', push: true);
    await go('/notifications', '17_notifications', push: true);
    await go('/settings', '18_settings', push: true);
    await go('/profile', '19_profile', push: true);
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, const Duration(seconds: 1));
  });

  testWidgets('personal + dark + login', (tester) async {
    final (key, c) = await _boot(tester, type: AccountType.personal, mode: ThemeMode.dark);
    final router = c.read(routerProvider);
    await _shot(tester, key, '20_dark_personal_dashboard');
    router.go('/map');
    await _pump(tester, const Duration(seconds: 2));
    await _shot(tester, key, '21_dark_map');
    router.go('/devices');
    await _pump(tester, const Duration(seconds: 1));
    await _shot(tester, key, '22_dark_devices');
    router.push('/device/PET-001');
    await _pump(tester, const Duration(seconds: 2));
    await _shot(tester, key, '23_dark_pet_details');
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, const Duration(seconds: 1));
  });

  testWidgets('auth screens (dark)', (tester) async {
    final (key, c) = await _boot(tester, mode: ThemeMode.dark, signedIn: false, onboarded: false, settle: const Duration(milliseconds: 900));
    await _shot(tester, key, '25_dark_splash');
    await _pump(tester, const Duration(seconds: 3));
    await _shot(tester, key, '26_dark_onboarding');
    c.read(routerProvider).go('/login');
    await _pump(tester, const Duration(seconds: 2));
    await _shot(tester, key, '27_dark_login');
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, const Duration(seconds: 1));
  });

  testWidgets('tablet dashboard', (tester) async {
    final (key, _) = await _boot(tester, size: const Size(1180, 820));
    await _shot(tester, key, '24_tablet_dashboard');
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, const Duration(seconds: 1));
  });
}
