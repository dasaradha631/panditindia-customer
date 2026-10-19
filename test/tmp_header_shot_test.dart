import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/features/home/home_screen.dart';
import 'package:customer_app/features/home/panchang_service.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/providers/booking_provider.dart';
import 'package:customer_app/providers/language_provider.dart';
import 'package:customer_app/providers/notifications_provider.dart';
import 'package:customer_app/providers/profile_provider.dart';

import 'support/test_environment.dart';

void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  setUp(() {
    // The header pill renders `hh:mm IST` at minute precision — pin the
    // wall clock so the golden doesn't drift between runs.
    PanchangService.now = () => DateTime.utc(2026, 10, 13, 16, 30);
  });

  tearDown(() {
    PanchangService.now = DateTime.now;
  });

  testWidgets('capture home header', (tester) async {
    tester.view.physicalSize = const Size(412 * 2, 900 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
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
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tmp_home_header.png'),
    );
  });
}
