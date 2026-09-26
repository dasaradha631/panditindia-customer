import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:panditindia_customer/app/app.dart';
import 'package:panditindia_customer/app/routes.dart';
import 'package:panditindia_customer/core/constants/app_strings.dart';
import 'package:panditindia_customer/core/widgets/brand_logo.dart';
import 'package:panditindia_customer/features/auth/login_type/login_type_screen.dart';
import 'package:panditindia_customer/features/splash/splash_screen.dart';
import 'package:panditindia_customer/services/session_service.dart';

void main() {
  setUp(() {
    SessionService.instance = SessionService(store: InMemorySecureStore());
  });

  testWidgets('splash screen renders brand lockup and headline',
      (WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/welcome', builder: (_, _) => const LoginTypeScreen()),
      ],
    );
    await tester.pumpWidget(PanditIndiaApp(router: router));
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(BrandLockup), findsOneWidget);
    expect(find.text(AppStrings.splashHeadline), findsOneWidget);
    expect(find.text(AppStrings.loading), findsOneWidget);

    // Run the splash timers through to navigation (4 x 520ms + 350ms).
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 520));
    }
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.byType(LoginTypeScreen), findsOneWidget);
  });

  testWidgets('welcome screen shows both login types', (WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/welcome',
      routes: <RouteBase>[
        GoRoute(path: '/welcome', builder: (_, _) => const LoginTypeScreen()),
      ],
    );
    await tester.pumpWidget(PanditIndiaApp(router: router));
    await tester.pump();

    expect(find.byType(LoginTypeScreen), findsOneWidget);
    expect(find.text(AppStrings.customerRoleTitle), findsOneWidget);
    expect(find.text(AppStrings.panditRoleTitle), findsOneWidget);
    expect(find.text(AppStrings.createCustomerAccount), findsOneWidget);
    expect(find.text(AppStrings.signIn), findsOneWidget);
  });

  test('createRouter exposes all day-one routes', () {
    final GoRouter router = createRouter();
    expect(router.configuration.routes.length, greaterThanOrEqualTo(10));
    expect(router.configuration.routes.first, isA<GoRoute>());
  });
}
