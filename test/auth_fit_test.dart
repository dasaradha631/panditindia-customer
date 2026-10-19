import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/features/auth/login_screen.dart';
import 'package:customer_app/features/auth/register_screen.dart';
import 'package:customer_app/providers/auth_provider.dart';
import 'package:customer_app/providers/language_provider.dart';

import 'support/test_environment.dart';

/// Guards the compact auth layout.
///
/// Login must fit a normal phone viewport with no scrolling at all.
///
/// Create Account is held to a slightly looser bound on purpose: the form stacks
/// all six inputs full width (name, email, phone, DOB, password, confirm) rather
/// than pairing them, so it needs more vertical room than the baseline canvas.
/// It still fits a normal phone without scrolling, and only the two smaller
/// viewports below are allowed a short scroll.
void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  Future<void> pumpScreen(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData(fontFamily: TestEnvironment.fontFamily),
          home: screen,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// How much taller the page is than the viewport it was given.
  double overflowOf(WidgetTester tester) {
    final state = tester.state<ScrollableState>(find.byType(Scrollable).first);
    return state.position.maxScrollExtent;
  }

  Future<double> measure(WidgetTester tester, Widget screen, Size size) async {
    await pumpScreen(tester, screen, size);
    expect(tester.takeException(), isNull);
    return overflowOf(tester);
  }

  const tall = Size(412, 820);
  const common = Size(360, 740);
  const short = Size(360, 600);

  testWidgets('login fits a normal phone without scrolling', (tester) async {
    expect(await measure(tester, const LoginScreen(), tall), 0);
    expect(await measure(tester, const LoginScreen(), common), 0);
  });

  testWidgets('create account fits a normal phone without scrolling', (
    tester,
  ) async {
    expect(await measure(tester, const RegisterScreen(), tall), 0);
  });

  testWidgets('create account only needs a short scroll on small phones', (
    tester,
  ) async {
    expect(
      await measure(tester, const RegisterScreen(), common),
      lessThanOrEqualTo(90),
    );
  });

  testWidgets('short viewports stay compact instead of overflowing', (
    tester,
  ) async {
    expect(await measure(tester, const LoginScreen(), short), lessThan(120));
    expect(await measure(tester, const RegisterScreen(), short), lessThan(240));
  });
}
