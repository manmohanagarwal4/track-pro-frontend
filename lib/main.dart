import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'data/local/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.open();
  runApp(
    ProviderScope(
      // Failures are surfaced to the user with an explicit Retry instead.
      retry: (_, _) => null,
      overrides: [localStoreProvider.overrideWithValue(store)],
      child: const TrackProApp(),
    ),
  );
}
