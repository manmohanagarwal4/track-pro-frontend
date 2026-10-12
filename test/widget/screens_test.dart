import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/data/models/enums.dart';

import 'package:tracker/features/devices/presentation/widgets/device_card.dart';
import 'package:tracker/features/drivers/presentation/drivers_screen.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('Login: onboarding → demo login → dashboard', (tester) async {
    await pumpApp(tester, onboarded: false);
    expect(find.text('Track anything that matters'), findsOneWidget);
    await tapAndWait(tester, find.text('Skip'));
    expect(find.text('Welcome back'), findsOneWidget);

    // Validation
    await tapAndWait(tester, find.byKey(const Key('login-submit')));
    expect(find.text('Password must be at least 4 characters'), findsOneWidget);

    await tapAndWait(tester, find.byKey(const Key('login-demo')), wait: const Duration(seconds: 2));
    expect(find.textContaining('Manmohan'), findsWidgets);
    expect(find.text('Total Devices'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('Login with email and password', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byKey(const Key('login-password')), 'secret');
    await tapAndWait(tester, find.byKey(const Key('login-submit')), wait: const Duration(seconds: 2));
    expect(find.text('LIVE TRACKING MAP'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('Dashboard shows summary, live map and active devices', (tester) async {
    await pumpApp(tester, signedInAs: AccountType.business);
    for (final label in ['Total Devices', 'Online', 'Moving', 'Alerts', 'LIVE TRACKING MAP', 'Live Simulation']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    await tester.scrollUntilVisible(find.text('Active Devices'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Active Devices'), findsOneWidget);

    // Toggle live simulation off and on.
    await tapAndWait(tester, find.byKey(const Key('live-sim-toggle')));
    expect(find.textContaining('Paused'), findsWidgets);
    await tapAndWait(tester, find.byKey(const Key('live-sim-toggle')));
    await disposeApp(tester);
  });

  testWidgets('Device list: search and filters change results', (tester) async {
    await pumpApp(tester, signedInAs: AccountType.personal);
    await tapAndWait(tester, find.text('Devices').last);
    expect(find.text('Fleet Car 04'), findsNothing, reason: 'business assets are hidden in Personal');
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('House Keys'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('device-search')), 'bruno');
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('House Keys'), findsNothing);

    await tester.enterText(find.byKey(const Key('device-search')), '');
    await pumpFor(tester, const Duration(milliseconds: 300));
    await tapAndWait(tester, find.widgetWithText(ChoiceChip, 'Pet'));
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('House Keys'), findsNothing);
    expect(find.text('Car 01'), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('Device details shows telemetry and actions', (tester) async {
    await pumpApp(tester, signedInAs: AccountType.business);
    await tapAndWait(tester, find.text('Fleet').last);
    await tester.enterText(find.byKey(const Key('fleet-search')), 'Truck 21');
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tapAndWait(tester, find.descendant(of: find.byType(DeviceCard), matching: find.text('Truck 21')).first,
        wait: const Duration(seconds: 1));

    expect(find.text('Current Location'), findsOneWidget);
    for (final a in ['Track Live', 'History', 'Trips', 'Geofence', 'Settings', 'Share']) {
      expect(find.text(a), findsWidgets, reason: a);
    }
    await tester.scrollUntilVisible(find.text('Ignition'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Amit Kumar'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('Alerts: mark all read and filter', (tester) async {
    await pumpApp(tester, signedInAs: AccountType.business);
    await tapAndWait(tester, find.text('Alerts').last);
    expect(find.text('Truck 21 exceeded 80 km/h.'), findsOneWidget);
    expect(find.byKey(const Key('mark-all-read')), findsOneWidget);
    await tapAndWait(tester, find.byKey(const Key('mark-all-read')));
    final button = tester.widget<TextButton>(find.byKey(const Key('mark-all-read')));
    expect(button.onPressed, isNull, reason: 'nothing left unread');

    await tapAndWait(tester, find.ancestor(of: find.textContaining('Overspeed'), matching: find.byType(ChoiceChip)));
    expect(find.text('Truck 21 exceeded 80 km/h.'), findsOneWidget);
    expect(find.text('Office Bag battery below 20%.'), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('Add device: ID → type → name → appears in list', (tester) async {
    await pumpApp(tester, signedInAs: AccountType.personal);
    await tester.scrollUntilVisible(find.text('Add tracker'), 300, scrollable: find.byType(Scrollable).first);
    await tapAndWait(tester, find.text('Add tracker').first);
    expect(find.text('Scan QR'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('add-device-id')), 'DEMO-001');
    await tapAndWait(tester, find.byKey(const Key('add-device-continue')));
    await tapAndWait(tester, find.byKey(const Key('asset-type-pet')));
    await tester.enterText(find.byKey(const Key('add-device-name')), 'Max');
    await tapAndWait(tester, find.byKey(const Key('add-device-submit')), wait: const Duration(seconds: 1));
    expect(find.text('Device Added Successfully'), findsOneWidget);

    await tapAndWait(tester, find.byKey(const Key('add-device-view')), wait: const Duration(seconds: 1));
    expect(find.text('Max'), findsWidgets);
    expect(find.text('DEMO-001'), findsWidgets);
    await disposeApp(tester);
  });

  testWidgets('Drivers: add, duplicate check and delete', (tester) async {
    await pumpApp(tester, signedInAs: AccountType.business);
    await tapAndWait(tester, find.text('More').last);
    await tapAndWait(tester, find.text('Drivers'));

    Future<void> fillAndSave(String name, String phone, String licence) async {
      await tapAndWait(tester, find.byKey(const Key('add-driver')));
      await tester.enterText(find.byKey(const Key('driver-name')), name);
      await tester.enterText(find.byKey(const Key('driver-phone')), phone);
      await tester.enterText(find.byKey(const Key('driver-licence')), licence);
      await tapAndWait(tester, find.byKey(const Key('driver-save')));
    }

    await fillAndSave('Zoya Test', '+91 90000 12345', 'UP16-2024-777');
    expect(find.text('Zoya Test added'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Zoya');
    await pumpFor(tester, const Duration(milliseconds: 400));
    expect(find.text('Zoya Test'), findsOneWidget);

    // Duplicate phone is rejected inside the form.
    await fillAndSave('Someone Else', '9000012345', 'HR26-2020-001');
    expect(find.textContaining('already uses this phone number'), findsOneWidget);
    await tester.tapAt(const Offset(200, 40)); // dismiss sheet
    await pumpFor(tester, const Duration(milliseconds: 600));

    // Delete via the card menu.
    await tapAndWait(tester, find.descendant(of: find.byType(DriverCard), matching: find.byType(PopupMenuButton<String>)));
    await tapAndWait(tester, find.text('Delete'));
    await tapAndWait(tester, find.byKey(const Key('driver-delete-confirm')));
    expect(find.text('Zoya Test'), findsNothing);
    expect(find.text('Zoya Test deleted'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('Dark mode renders the dashboard', (tester) async {
    await pumpApp(tester, signedInAs: AccountType.business, themeMode: ThemeMode.dark);
    expect(find.text('Total Devices'), findsOneWidget);
    expect(Theme.of(tester.element(find.text('Total Devices'))).brightness, Brightness.dark);
    await disposeApp(tester);
  });

  testWidgets('Tablet layout uses a navigation rail', (tester) async {
    await pumpApp(tester, signedInAs: AccountType.business, size: const Size(1100, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await disposeApp(tester);
  });
}
