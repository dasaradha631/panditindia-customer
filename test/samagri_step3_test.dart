import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/features/booking/booking_flow_screen.dart';
import 'package:customer_app/features/booking/samagri_kit_editor.dart';
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

  /// Griha Pravesh (default catalogue ceremony) parked on step 3.
  BookingProvider prepared() {
    final b = BookingProvider();
    b.resetDraft();
    b.selectCeremony(CeremonyCatalogue.ceremonies.first);
    b.setStep(3);
    return b;
  }

  Future<void> pumpStep3(WidgetTester tester, BookingProvider p) async {
    tester.view.physicalSize = const Size(412 * 2, 900 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(p));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('step 3 header fits the page and cards expose both actions',
      (tester) async {
    final p = prepared();
    await pumpStep3(tester, p);

    // Header: title + full-width subtitle + ceremony pill all render.
    expect(find.text('Choose Pure Eco-Samagri Kit'), findsOneWidget);
    expect(
      find.textContaining('100% Unadulterated Organic Ghee'),
      findsOneWidget,
    );
    expect(find.textContaining('Ceremony: Griha Pravesh'), findsOneWidget);
    expect(find.text('Samagri Package'), findsOneWidget);

    // All three package options with their badges.
    expect(find.text('Premium Sealed Eco-Samagri Kit'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('Standard Vedic Samagri Kit'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('Devotee Will Arrange Own Items'), findsOneWidget);
    expect(find.text('Self Arrange'), findsOneWidget);

    // Two actions on each purchasable kit + checklist on the self-arrange.
    expect(find.text('Cost Breakdown'), findsNWidgets(2));
    expect(find.text('Customize Items (+ Add/Remove)'), findsNWidgets(2));
    expect(find.text('View Vedic Checklist'), findsOneWidget);

    // Priced item rows (grihapravesh premium ₹220 first row) + overflow chip.
    expect(find.text('₹220'), findsWidgets);
    expect(find.text('+2 more'), findsWidgets);

    // No layout overflow anywhere in the step.
    expect(tester.takeException(), isNull);
  });

  testWidgets('cost breakdown opens with category totals and live total',
      (tester) async {
    final p = prepared();
    await pumpStep3(tester, p);

    final breakdownBtn = find.text('Cost Breakdown').first;
    await tester.ensureVisible(breakdownBtn);
    await tester.pump();
    await tester.tap(breakdownBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('Itemized Kit Cost Breakdown & Price Differentiation'),
      findsOneWidget,
    );
    expect(find.text('CATEGORY-WISE COST SUMMARY'), findsOneWidget);
    // Category chips (label + amount as separate texts). Griha Pravesh
    // premium: Utensils 220+200=420, Dry Items 120, Liquids 340, Herbs 90,
    // Incense 80 → total ₹1,050.
    expect(find.text('₹420'), findsOneWidget);
    expect(find.text('Liquids'), findsWidgets);
    expect(find.text('₹340'), findsWidgets);
    expect(find.text('ALL 6 SACRED ITEMS IN THIS KIT'), findsOneWidget);
    expect(find.text('Total Kit Dakshina'), findsOneWidget);
    expect(find.text('₹1,050'), findsWidgets);
    expect(find.text('Close Breakdown'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Close Breakdown'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Close Breakdown'), findsNothing);
  });

  testWidgets('customize editor applies an edited kit back to the step',
      (tester) async {
    final p = prepared();
    await pumpStep3(tester, p);

    final customizeBtn = find.text('Customize Items (+ Add/Remove)').first;
    await tester.ensureVisible(customizeBtn);
    await tester.pump();
    await tester.tap(customizeBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Customize Eco-Samagri Kit'), findsOneWidget);
    expect(find.text('Cost Differentiation Dialog'), findsOneWidget);
    expect(find.text('Ceremony Base Inclusions:'), findsOneWidget);
    expect(find.text('Save & Apply Kit (₹1,050)'), findsOneWidget);

    // Bump the first cart row (₹220 Navaratna box) → ₹1,270 total.
    final editorPlus = find.descendant(
      of: find.byType(SamagriKitEditor),
      matching: find.byIcon(Icons.add),
    );
    await tester.tap(editorPlus.first);
    await tester.pump();
    expect(find.text('Save & Apply Kit (₹1,270)'), findsOneWidget);

    await tester.tap(find.text('Save & Apply Kit (₹1,270)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Back on step 3 with the customized kit committed.
    expect(find.text('Edit Customized Kit (6 Items)'), findsOneWidget);
    expect(p.draft.samagriCustomized, isTrue);
    expect(p.draft.samagriPrice, 1270);
    expect(tester.takeException(), isNull);
  });
}
