import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/l10n/app_l10n.dart';
import 'core/session/session_guard.dart';
import 'core/theme/app_theme.dart';
import 'core/translation/translated_scope.dart';
import 'core/widgets/floating_ai_assistant.dart';
import 'core/widgets/mobile_frame.dart';
import 'features/splash/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/language_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/profile_provider.dart';

/// Shared with the global floating AI assistant so it can push routes
/// (e.g. "Book Now") onto the app's root navigator from any screen.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PanditIndiaCustomerApp());
}

class PanditIndiaCustomerApp extends StatelessWidget {
  const PanditIndiaCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationsProvider(recipientType: 'user'),
        ),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, language, _) => Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) =>
              context.read<AuthProvider>().touchActivityThrottled(),
          child: MaterialApp(
            title: 'PanditIndia',
            debugShowCheckedModeBanner: false,
            navigatorKey: rootNavigatorKey,
            theme: AppTheme.light(),
            locale: language.locale,
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.delegates,
            // Translates every rendered string into the selected language —
            // the mobile counterpart of the web app's Google Translate widget.
            // The floating Acharya AI assistant sits on top of every route
            // (signup/login included) and can be dragged + collapsed.
            builder: (context, child) => TranslatedScope(
              // SessionGuard reacts to the 15-minute idle sign-out by
              // routing to the login screen with an explanatory toast so
              // screens never sit there with empty, cleared-session data.
              child: SessionGuard(
                navigatorKey: rootNavigatorKey,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    buildMobileFrame(context, child),
                    FloatingAiAssistant(navigatorKey: rootNavigatorKey),
                  ],
                ),
              ),
            ),
            home: const SplashScreen(),
          ),
        ),
      ),
    );
  }
}
