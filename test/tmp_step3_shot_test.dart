import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/features/booking/booking_flow_screen.dart';
import 'package:customer_app/models/catalogue_data.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/providers/booking_provider.dart';
import 'package:customer_app/providers/language_provider.dart';
import 'package:customer_app/providers/profile_provider.dart';

import 'support/test_environment.dart';

void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  Widget host(BookingProvider booking) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: booking),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        theme: ThemeData(fontFamily: TestEnvironment.fontFamily),
        home: const BookingFlowScreen(),
      ),
    );
  }

  BookingProvider prepared() {
    final b = BookingProvider();
    b.resetDraft();
    b.selectCeremony(CeremonyCatalogue.ceremonies.first);
    b.setStep(3);
    return b;
  }

  Future<void> pumpFlow(WidgetTester tester, BookingProvider p) async {
    tester.view.physicalSize = const Size(412 * 2, 900 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(p));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('capture booking step 3', (tester) async {
    await pumpFlow(tester, prepared());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tmp_step3.png'),
    );
  });

  testWidgets('capture step 3 cost breakdown', (tester) async {
    await pumpFlow(tester, prepared());
    final btn = find.text('Cost Breakdown').first;
    await tester.ensureVisible(btn);
    await tester.pump();
    await tester.tap(btn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tmp_step3_breakdown.png'),
    );
  });

  testWidgets('capture step 3 customize editor', (tester) async {
    await pumpFlow(tester, prepared());
    final btn = find.text('Customize Items (+ Add/Remove)').first;
    await tester.ensureVisible(btn);
    await tester.pump();
    await tester.tap(btn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tmp_step3_editor.png'),
    );
  });
}
