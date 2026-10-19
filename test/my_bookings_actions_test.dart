import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/features/bookings/my_bookings_screen.dart';
import 'package:customer_app/features/samagri/samagri_orders_screen.dart';
import 'package:customer_app/models/booking.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/providers/booking_provider.dart';
import 'package:customer_app/providers/language_provider.dart';
import 'package:customer_app/providers/notifications_provider.dart';
import 'package:customer_app/providers/profile_provider.dart';

import 'support/test_environment.dart';

Booking _booking({required int id, required String status}) => Booking.fromJson({
  'booking_id': id,
  'status': status,
  'ceremony': 'Ganapathi Homam',
  'booking_date': '2026-10-20',
  'time_slot': '06:00 AM - 08:00 AM',
  'full_name': 'Amit Sharma',
  'price': 2100,
});

void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  test('Active filter matches the web definition', () {
    final provider = BookingProvider()
      ..myBookings = [
        _booking(id: 1, status: 'confirmed'),
        _booking(id: 2, status: 'completed'),
        _booking(id: 3, status: 'cancelled'),
        _booking(id: 4, status: 'en_route'),
      ];

    expect(
      provider.filtered('Active').map((b) => b.bookingId).toList(),
      [1, 4],
    );
    expect(provider.filtered('Completed').single.bookingId, 2);
    expect(provider.filtered('Cancelled').single.bookingId, 3);
    expect(provider.filtered('All'), hasLength(4));
  });

  testWidgets('tile offers Eco Kit, Reschedule and Cancel actions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(
            create: (_) => BookingProvider()
              ..myBookings = [_booking(id: 8842, status: 'confirmed')],
          ),
          ChangeNotifierProvider(
            create: (_) => NotificationsProvider(recipientType: 'user'),
          ),
          ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData(fontFamily: TestEnvironment.fontFamily),
          home: Scaffold(body: MyBookingsScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Active (1)'), findsOneWidget);
    expect(find.text('Completed (0)'), findsOneWidget);
    expect(find.text('View Items & Prices'), findsOneWidget);
    expect(find.text('Reschedule'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel booking?'), findsOneWidget);
    await tester.tap(find.text('Keep Booking'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel booking?'), findsNothing);

    // Eco Kit opens the per-booking itemised kit sheet ("View Items &
    // Prices"); the orders screen sits behind the sheet's "View All" action.
    await tester.tap(find.text('View Items & Prices'));
    await tester.pumpAndSettle();
    expect(find.text('View All Samagri Orders'), findsOneWidget);
    await tester.ensureVisible(find.text('View All Samagri Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View All Samagri Orders'));
    await tester.pumpAndSettle();
    expect(find.byType(SamagriOrdersScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
