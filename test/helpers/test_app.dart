import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracker/app.dart';
import 'package:tracker/core/di/providers.dart';
import 'package:tracker/data/local/local_store.dart';
import 'package:tracker/data/mock/mock_backend.dart';
import 'package:tracker/data/mock/mock_seed.dart';
import 'package:tracker/data/models/app_settings.dart';
import 'package:tracker/data/models/enums.dart';

/// Boots the full app against local mock data (no latency, no random errors).
Future<void> pumpApp(
  WidgetTester tester, {
  bool onboarded = true,
  AccountType? signedInAs,
  Size size = const Size(400, 860),
  ThemeMode themeMode = ThemeMode.light,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final settings = AppSettings(onboardingDone: onboarded, simulateErrors: false, themeMode: themeMode);
  SharedPreferences.setMockInitialValues({
    'tp.settings': jsonEncode(settings.toJson()),
    if (signedInAs != null)
      'tp.session': jsonEncode(MockSeed.demoUser.copyWith(accountType: signedInAs).toJson()),
  });
  final store = await LocalStore.open();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        localStoreProvider.overrideWithValue(store),
        mockLatencyProvider.overrideWithValue(MockLatency.none()),
      ],
      child: const TrackProApp(),
    ),
  );
  // Splash animation + routing.
  await pumpFor(tester, const Duration(seconds: 2));
}

/// Advances time in small steps (the live map never fully "settles").
Future<void> pumpFor(WidgetTester tester, Duration total, {Duration step = const Duration(milliseconds: 100)}) async {
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

/// Disposes the app so simulation timers are cancelled before the test ends.
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

Future<void> tapAndWait(WidgetTester tester, Finder finder, {Duration wait = const Duration(milliseconds: 800)}) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await pumpFor(tester, wait);
}
