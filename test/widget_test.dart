import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/widgets/common.dart';
import 'package:customer_app/models/catalogue_data.dart';

void main() {
  test('booking id normalization matches the web format', () {
    expect(AppStatus.normalizeBookingId('#PI-2026-8842'), '8842');
    expect(AppStatus.displayBookingId(8842), '#PI-2026-8842');
    expect(AppStatus.displayStatus('pending_acceptance'), 'Pending Acceptance');
    expect(AppStatus.displayStatus('in_progress'), 'In Progress');
    expect(AppStatus.displayStatus('completed'), 'Completed');
  });

  test('travel allowance tiers follow the web pricing rules', () {
    expect(calculateTravelAllowance(5), 0);
    expect(calculateTravelAllowance(15), 150);
    expect(calculateTravelAllowance(30), 300);
    expect(calculateTravelAllowance(50), 400);
  });

  testWidgets('StatusBadge renders its label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(label: 'Confirmed', color: AppColors.info),
        ),
      ),
    );
    expect(find.text('CONFIRMED'), findsOneWidget);
  });
}
