import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/features/auth/forgot_password_screen.dart';
import 'package:customer_app/features/auth/login_screen.dart';
import 'package:customer_app/features/auth/register_screen.dart';
import 'package:customer_app/features/bookings/my_bookings_screen.dart';
import 'package:customer_app/features/home/home_screen.dart';
import 'package:customer_app/features/main_shell.dart';
import 'package:customer_app/features/kundali/kundali_screen.dart';
import 'package:customer_app/features/notifications/notifications_screen.dart';
import 'package:customer_app/features/profile/family_members_screen.dart';
import 'package:customer_app/features/profile/profile_screen.dart';
import 'package:customer_app/features/profile/saved_addresses_screen.dart';
import 'package:customer_app/features/profile/support_screen.dart';
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

void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
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
    await tester.pump(const Duration(milliseconds: 100));
  }

  final cases = <String, Widget Function()>{
    'home': () => const Scaffold(body: HomeScreen()),
    'catalogue': () => const PujaCatalogueScreen(),
    'my bookings': () => const Scaffold(body: MyBookingsScreen()),
    'profile': () => const Scaffold(body: ProfileScreen()),
    'notifications': () => const NotificationsScreen(),
    'family': () => const FamilyMembersScreen(),
    'addresses': () => const SavedAddressesScreen(),
    'support': () => const SupportScreen(),
    'login': () => const LoginScreen(),
    'register': () => const RegisterScreen(),
    'forgot': () => const ForgotPasswordScreen(),
    'shell': () => const MainShell(),
    'kundali': () => const KundaliScreen(),
    'samagri': () => const SamagriOrdersScreen(),
    'receipts': () => const ReceiptsScreen(),
    'puja details': () =>
        PujaDetailsScreen(ceremony: CeremonyCatalogue.ceremonies.first),
  };

  cases.forEach((name, make) {
    testWidgets('$name renders without layout exceptions', (tester) async {
      await pumpScreen(tester, make());
      if (name == 'notifications') {
        final nav = tester.element(find.byType(MaterialApp));
        nav.read<NotificationsProvider>().stopPolling();
      }
    });
  });
}
