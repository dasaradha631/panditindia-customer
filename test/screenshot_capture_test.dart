import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/features/auth/login_screen.dart';
import 'package:customer_app/features/booking/booking_flow_screen.dart';
import 'package:customer_app/features/profile/profile_screen.dart';
import 'package:customer_app/features/pujas/puja_details_screen.dart';
import 'package:customer_app/features/reviews/review_sheet.dart';
import 'package:customer_app/features/tracking/live_tracking_screen.dart';
import 'package:customer_app/models/catalogue_data.dart';
import 'package:customer_app/models/booking.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/providers/booking_provider.dart';
import 'package:customer_app/providers/language_provider.dart';
import 'package:customer_app/providers/notifications_provider.dart';
import 'package:customer_app/providers/profile_provider.dart';

import 'support/test_environment.dart';

Booking _fakeBooking({String status = 'en_route'}) => Booking.fromJson({
  'booking_id': 8842,
  'status': status,
  'ceremony': 'Ganapathi Homam',
  'assigned_pandit': 'Pandit Ramesh Sharma',
  'booking_date': '2026-10-05',
  'time_slot': '06:00 AM - 08:00 AM',
  'full_name': 'Amit Sharma',
  'address': '12, MG Road, Bengaluru',
  'city': 'Bengaluru',
  'state': 'Karnataka',
  'price': 2100,
});

void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  Future<void> pumpAtFrame(
    WidgetTester tester,
    Widget screen, {
    void Function(BookingProvider)? prep,
    bool openReview = false,
  }) async {
    tester.view.physicalSize = const Size(412 * 2, 900 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(
            create: (_) {
              final p = BookingProvider();
              prep?.call(p);
              return p;
            },
          ),
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
    await tester.pump(const Duration(milliseconds: 200));
    if (openReview) {
      final ctx = tester.element(find.byType(Scaffold));
      showReviewSheet(
        ctx,
        bookingId: 8842,
        ceremonyName: 'Ganapathi Homam',
        panditName: 'Pandit Ramesh Sharma',
        devoteeName: 'Amit Sharma',
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
    }
  }

  testWidgets('capture login with brand logo', (tester) async {
    await pumpAtFrame(tester, const LoginScreen());
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/branding/logo.png'),
        tester.element(find.byType(MaterialApp)),
      );
    });
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/branding/logo.png',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/login.png'),
    );
  });

  testWidgets('capture puja details', (tester) async {
    await pumpAtFrame(
      tester,
      PujaDetailsScreen(ceremony: CeremonyCatalogue.ceremonies.first),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/puja_details.png'),
    );
  });

  testWidgets('capture booking step 2', (tester) async {
    await pumpAtFrame(
      tester,
      const BookingFlowScreen(),
      prep: (p) {
        p.selectCeremony(CeremonyCatalogue.ceremonies.first);
        // The draft defaults to "today + 2 days", so the rendered date would
        // drift every day and the golden would fail each morning. Pin it.
        p.updateDraft((d) => d.date = '2026-10-08');
        p.setStep(2);
      },
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/booking_step2.png'),
    );
  });

  testWidgets('capture profile portals', (tester) async {
    await pumpAtFrame(
      tester,
      const ProfileScreen(),
      prep: (p) => p.myBookings = [
        _fakeBooking(status: 'confirmed'),
        _fakeBooking(status: 'completed'),
      ],
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/profile_portals.png'),
    );
  });

  testWidgets('capture review modal', (tester) async {
    await pumpAtFrame(
      tester,
      const Scaffold(body: SizedBox()),
      openReview: true,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/review_modal.png'),
    );
  });

  testWidgets('capture live tracking journey', (tester) async {
    final b = _fakeBooking(status: 'en_route');
    await pumpAtFrame(
      tester,
      LiveTrackingScreen(
        bookingId: b.bookingId,
        booking: b,
        panditName: b.assignedPandit,
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/live_tracking.png'),
    );
  });
}
