import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/features/booking/booking_flow_screen.dart';
import 'package:customer_app/features/pujas/puja_details_screen.dart';
import 'package:customer_app/models/catalogue_data.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/providers/booking_provider.dart';
import 'package:customer_app/providers/language_provider.dart';
import 'package:customer_app/providers/profile_provider.dart';

import 'support/test_environment.dart';

void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  Widget host(BookingProvider booking, Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: booking),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        theme: ThemeData(fontFamily: TestEnvironment.fontFamily),
        home: child,
      ),
    );
  }

  testWidgets('puja details screen renders body content', (tester) async {
    final booking = BookingProvider();
    await tester.pumpWidget(
      host(
        booking,
        PujaDetailsScreen(ceremony: CeremonyCatalogue.ceremonies.first),
      ),
    );
    await tester.pump();
    expect(find.text('About this ceremony'), findsOneWidget);
    expect(find.text('Book This Puja'), findsOneWidget);
  });

  testWidgets('booking flow shows step 1 content', (tester) async {
    final booking = BookingProvider();
    booking.resetDraft(
      devoteeName: 'A',
      mobile: '9876543210',
      email: 'a@b.com',
    );
    booking.selectCeremony(CeremonyCatalogue.ceremonies.first);
    await tester.pumpWidget(host(booking, const BookingFlowScreen()));
    await tester.pump();
    expect(find.text('Book a Ceremony'), findsOneWidget);
    expect(find.text('Choose your ceremony'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('booking flow advances from step 1 to step 2', (tester) async {
    final booking = BookingProvider();
    booking.resetDraft();
    booking.selectCeremony(CeremonyCatalogue.ceremonies.first);
    await tester.pumpWidget(host(booking, const BookingFlowScreen()));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Select Auspicious Date & Muhurat'), findsOneWidget);
  });
}
