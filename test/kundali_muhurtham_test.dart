import 'package:flutter/material.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/features/kundali/auspicious_calendar.dart';
import 'package:customer_app/features/kundali/birth_details_modal.dart';
import 'package:customer_app/features/kundali/kundali_data.dart';
import 'package:customer_app/features/kundali/kundali_screen.dart';
import 'package:customer_app/features/kundali/muhurtham_section.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/providers/booking_provider.dart';
import 'package:customer_app/providers/language_provider.dart';
import 'package:customer_app/providers/notifications_provider.dart';
import 'package:customer_app/providers/profile_provider.dart';

import 'support/test_environment.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

Widget _app(Widget home) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ChangeNotifierProvider(create: (_) => BookingProvider()),
    ChangeNotifierProvider(
      create: (_) => NotificationsProvider(recipientType: 'user'),
    ),
    ChangeNotifierProvider(create: (_) => ProfileProvider()),
  ],
  child: MaterialApp(
    theme: ThemeData(fontFamily: TestEnvironment.fontFamily),
    home: home,
  ),
);

Map<String, dynamic> _calendarFor(DateTime month, DateTime today) {
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  return {
    'year': month.year,
    'month': month.month,
    'month_name': 'Month',
    'first_weekday': DateTime(month.year, month.month, 1).weekday - 1,
    'location': 'Hyderabad, Telangana',
    'days': [
      for (var d = 1; d <= daysInMonth; d++)
        () {
          final date = DateTime(month.year, month.month, d);
          final past = date.isBefore(DateTime(today.year, today.month, today.day));
          return {
            'day': d,
            'date': _iso(date),
            'display_date': '$d ${month.month}/${month.year}',
            'is_past': past,
            'status': past ? 'past' : (d.isEven ? 'excellent' : 'good'),
            'status_label': past ? 'Past Date' : 'Good',
            'color_dot': past ? 'bg-slate-300' : 'bg-emerald-500',
            'nakshatra': 'Rohini',
            'tithi': 'Shukla Panchami',
            'available_muhurtham': '06:15 - 07:45',
            'recommended_ceremony': 'Griha Pravesh',
            'panchanga': <String, dynamic>{
              'tithi': 'Shukla Panchami',
              'nakshatra': 'Rohini',
              'yoga': 'Siddha',
              'karana': 'Bava',
              'vara': 'Somavara (Monday)',
              'sunrise': '06:04',
              'sunset': '18:11',
              'rahu_kaal': '07:30 - 09:00',
              'abhijit_muhurat': '11:48 - 12:36',
            },
          };
        }(),
    ],
  };
}

void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  test('muhurtham helpers map ceremonies and split locations', () {
    expect(kCeremonyCatalogueIdFor('Griha Pravesh'), 'grihapravesh');
    expect(kCeremonyCatalogueIdFor('Marriage'), 'wedding');
    expect(kCeremonyCatalogueIdFor('Maha Rudrabhishekam'), 'rudrabhishekam');
    expect(kSplitLocation('Hyderabad, Telangana').city, 'Hyderabad');
    expect(kSplitLocation('Hyderabad, Telangana').state, 'Telangana');
    expect(kMuhurthamCeremonies, hasLength(19));
    expect(kPopularLocations, contains('Varanasi, Uttar Pradesh'));
    expect(kIndianStates, hasLength(36));
  });

  testWidgets('muhurtham engine shows the web form copy and guards missing birth details',
      (tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var booked = false;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: SingleChildScrollView(
            child: MuhurthamSection(
              birth: const KundaliBirthDetails(),
              onBook: ({
                required MuhurthamCeremony ceremony,
                required String date,
                required String timeSlot,
                required String location,
              }) {
                booked = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Recommended Muhurthams for You'), findsOneWidget);
    expect(
      find.text(
        'Vedic Panchanga + Tarabala + Chandrabala + Rahu Kalam avoidance for your specific location & birth chart.',
      ),
      findsOneWidget,
    );
    expect(find.text('Location Timezone:'), findsOneWidget);
    expect(find.text('IST (UTC+5:30)'), findsOneWidget);
    expect(find.text('What ceremony are you planning? *'), findsOneWidget);
    expect(find.text('Ceremony Location *'), findsOneWidget);
    expect(find.text('Griha Pravesh'), findsOneWidget);
    expect(find.text('Hyderabad, Telangana'), findsOneWidget);
    expect(find.text('Find My Best Muhurtham'), findsOneWidget);
    expect(
      find.text('Traditional Vedic Jyotisha & Panchanga Disclaimer'),
      findsOneWidget,
    );
    expect(booked, isFalse);

    final calculate = find.byKey(const ValueKey<String>('muhurtham-calculate'));
    await tester.ensureVisible(calculate);
    await tester.pump();
    await tester.tap(calculate);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(
        'Please enter your birth details to compute personalized Muhurtham timings.',
      ),
      findsOneWidget,
    );
    // Calculation must not have started.
    expect(find.text('Find My Best Muhurtham'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });

  testWidgets('ceremony dropdown switches the selected ceremony', (tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        Scaffold(
          body: SingleChildScrollView(
            child: MuhurthamSection(
              birth: const KundaliBirthDetails(),
              onBook: ({
                required MuhurthamCeremony ceremony,
                required String date,
                required String timeSlot,
                required String location,
              }) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('muhurtham-ceremony')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marriage').last);
    await tester.pumpAndSettle();

    expect(find.text('Marriage'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auspicious calendar renders months, days, drawer and blocks past dates',
      (tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final months = List<DateTime>.generate(4, (i) => DateTime(now.year, now.month + i));
    final calendar = _calendarFor(today, today);
    String? selectedDate;
    String? bookedDate;
    final futureDay =
        today.day < 25 ? today.day + 3 : 24;
    final pastDay = today.day > 2 ? today.day - 1 : null;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: TestEnvironment.fontFamily),
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => AuspiciousCalendar(
                calendar: calendar,
                month: today,
                months: months,
                onMonthChanged: (_) {},
                selectedDay: selectedDate == null
                    ? null
                    : (calendar['days'] as List)
                          .cast<Map<String, dynamic>>()
                          .firstWhere((d) => d['date'] == selectedDate),
                onTapDay: (day) => setState(() => selectedDate = day['date'] as String),
                onBookDay: (day) => bookedDate = day['date'] as String,
                ceremonyName: 'Griha Pravesh',
                location: 'Hyderabad, Telangana',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('${today.year} Auspicious Dates Calendar'),
      findsOneWidget,
    );
    expect(find.text('Excellent'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Regular'), findsOneWidget);
    for (final key in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      expect(find.text(key), findsOneWidget);
    }
    expect(
      find.byKey(ValueKey<String>('month-${months.first.year}-${months.first.month}')),
      findsOneWidget,
    );
    expect(find.byKey(ValueKey<String>('day-${_iso(today)}')), findsOneWidget);

    // Past day selection is refused with the localized hint.
    if (pastDay != null) {
      final pastDate = DateTime(today.year, today.month, pastDay);
      final pastCell = find.byKey(ValueKey<String>('day-${_iso(pastDate)}'));
      await tester.ensureVisible(pastCell);
      await tester.pump();
      await tester.tap(pastCell);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text(
          'This date has passed. Please select an upcoming auspicious date from today onwards.',
        ),
        findsOneWidget,
      );
      expect(selectedDate, isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
    }

    // Future day opens the day drawer with the muhurtham window and CTA.
    final futureDate = DateTime(today.year, today.month, futureDay);
    final futureCell = find.byKey(ValueKey<String>('day-${_iso(futureDate)}'));
    await tester.ensureVisible(futureCell);
    await tester.pump();
    await tester.tap(futureCell);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Available Muhurtham Window'), findsOneWidget);
    expect(find.text('06:15 - 07:45'), findsOneWidget);
    expect(find.text('Book for this Date'), findsOneWidget);
    expect(selectedDate, _iso(futureDate));

    final bookBtn = find.byKey(const ValueKey<String>('calendar-book-day'));
    await tester.ensureVisible(bookBtn);
    await tester.pump();
    await tester.tap(bookBtn);
    await tester.pump();
    expect(bookedDate, _iso(futureDate));
    expect(tester.takeException(), isNull);
  });
  testWidgets('birth details modal validates required fields', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              key: const ValueKey<String>('open-birth-modal'),
              onPressed: () => showBirthDetailsModal(context, profile: null),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('open-birth-modal')));
    await tester.pumpAndSettle();

    expect(find.text('Update Devotee Birth Details'), findsOneWidget);
    expect(
      find.text('Used for Janam Kundali & Muhurtham calculations'),
      findsOneWidget,
    );
    expect(find.text('Date of Birth *'), findsOneWidget);
    expect(find.text('Time of Birth *'), findsOneWidget);
    expect(find.text('Place of Birth (City, State) *'), findsOneWidget);
    expect(find.text('Vedic Ephemeris Coordinates'), findsOneWidget);
    expect(find.text('Save & Calculate Kundli →'), findsOneWidget);

    final save = find.byKey(const ValueKey<String>('birth-modal-save'));
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(
        'Please fill in Date of Birth, Time of Birth, and Place of Birth for accurate astrological calculations.',
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('birth-modal-close')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('kundali screen shows the incomplete-birth state instead of fabricating a chart',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    // The screen is a ListView; give it room for the banner cards.
    tester.view.physicalSize = const Size(412, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const KundaliScreen()));
    await tester.pump();

    // The kundli request fails fast (no network in tests); pump fake time
    // until the loading view is replaced by the incomplete-birth state.
    for (var i = 0; i < 12 && find.byKey(const ValueKey<String>('kundali-retry')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
    }

    // No fabricated chart: without a real, complete API payload the chart,
    // its update-birth button and the advanced muhurtham engine stay absent.
    expect(find.byKey(const ValueKey<String>('kundali-retry')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('kundali-update-birth')), findsNothing);
    expect(find.byKey(const ValueKey<String>('kundali-muhurtham')), findsNothing);
    expect(find.text('VEDIC BIRTH CHART'), findsNothing);

    // Retry re-requests the chart without breaking the page.
    final retry = find.byKey(const ValueKey<String>('kundali-retry'));
    await tester.ensureVisible(retry);
    await tester.pump();
    await tester.tap(retry);
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      if (find.byKey(const ValueKey<String>('kundali-retry')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey<String>('kundali-retry')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
