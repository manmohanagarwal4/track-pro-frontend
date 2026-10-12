// Run on a device / emulator:
//   flutter test integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/journeys.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TrackPro end-to-end (mock data)', () {
    testWidgets('Login, map, device, history, trips, geofence, alert', mainJourney);
    testWidgets('Add pet tracker and safe-zone exit alert', petJourney);
    testWidgets('Fleet, driver, overspeed alert and driver assignment', commercialJourney);
  });
}
