import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/features/kundali/kundali_screen.dart';
import 'package:customer_app/features/profile/profile_screen.dart';
import 'package:customer_app/features/pujas/puja_catalogue_screen.dart';
import 'package:customer_app/features/pujas/puja_details_screen.dart';
import 'package:customer_app/features/receipts/receipts_screen.dart';
import 'package:customer_app/features/samagri/samagri_orders_screen.dart';
import 'package:customer_app/models/catalogue_data.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/providers/booking_provider.dart';
import 'package:customer_app/providers/language_provider.dart';
import 'package:customer_app/providers/notifications_provider.dart';
import 'package:customer_app/providers/profile_provider.dart';

import 'support/test_environment.dart';

/// Renders screens at the exact logical size used by the web phone frame
/// (412x900). Unlike screens_layout_test, overflow errors are NOT suppressed
/// here — any RenderFlex overflow fails the test.
void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  Future<void> pumpAtFrameSize(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
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
          home: screen,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  final cases = <String, Widget Function()>{
    'puja details': () =>
        PujaDetailsScreen(ceremony: CeremonyCatalogue.ceremonies.first),
    'puja catalogue': () => const PujaCatalogueScreen(),
    'profile with portals': () => const ProfileScreen(),
    'kundali': () => const KundaliScreen(),
    'samagri': () => const SamagriOrdersScreen(),
    'receipts': () => const ReceiptsScreen(),
  };

  cases.forEach((name, make) {
    testWidgets('$name has no overflow at 412x900', (tester) async {
      await pumpAtFrameSize(tester, make());
      // Any RenderFlex overflow is routed to FlutterError.onError by the
      // test binding and fails this test automatically — nothing to assert.
      expect(tester.takeException(), isNull);
    });
  });
}
