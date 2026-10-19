import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/core/widgets/app_drawer.dart';
import 'package:customer_app/features/home/home_screen.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/providers/booking_provider.dart';
import 'package:customer_app/providers/language_provider.dart';
import 'package:customer_app/providers/notifications_provider.dart';
import 'package:customer_app/providers/profile_provider.dart';

import 'support/test_environment.dart';

void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  Widget harness({required Widget body}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationsProvider(recipientType: 'user'),
        ),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        theme: ThemeData(fontFamily: TestEnvironment.fontFamily),
        home: body,
      ),
    );
  }

  Future<void> openDrawer(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 2, 900 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  testWidgets('drawer lists all portal options', (tester) async {
    await tester.pumpWidget(
      harness(
        body: Scaffold(
          drawer: AppDrawer(onSelectTab: (_) {}),
          body: const SizedBox(),
        ),
      ),
    );
    await openDrawer(tester);

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('SACRED DEVOTEE PORTALS'), findsOneWidget);
    expect(find.text('VEDIC 2.0'), findsOneWidget);
    for (final label in [
      'Overview',
      'Live GPS Telemetry',
      'My Bookings',
      'Book Sacred Puja',
      'Kundali & Horoscope',
      'Eco-Samagri Kit',
      'Receipts & 80G',
      'Gotra & Profile',
      'Dedicated Acharya Desk',
      'Logout Devotee Account',
      '450 Punya Pts',
    ]) {
      expect(
        find.text(label),
        findsOneWidget,
        reason: 'missing drawer item: $label',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer tab items switch tabs and close drawer', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(
      harness(
        body: Scaffold(
          drawer: AppDrawer(onSelectTab: taps.add),
          body: const SizedBox(),
        ),
      ),
    );
    await openDrawer(tester);

    await tester.tap(find.text('My Bookings'));
    await tester.pumpAndSettle();
    expect(taps, [1]);
    expect(find.byType(Drawer), findsNothing);

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await tester.tap(find.text('Gotra & Profile'));
    await tester.pumpAndSettle();
    expect(taps, [1, 2]);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('home screen header avatar opens the drawer', (tester) async {
    await tester.pumpWidget(
      harness(
        body: Scaffold(
          drawer: AppDrawer(onSelectTab: (_) {}),
          body: const HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey<String>('home-avatar')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('home-avatar')));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('Book Sacred Puja'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
