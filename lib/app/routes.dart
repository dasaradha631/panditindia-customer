import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_strings.dart';
import '../features/auth/forgot_password/forgot_password_screen.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/login_type/login_type_screen.dart';
import '../features/auth/register/register_screen.dart';
import '../features/auth/reset_password/reset_password_screen.dart';
import '../features/home/home_screen.dart';
import '../features/shared/placeholder_screen.dart';
import '../features/splash/splash_screen.dart';
import '../models/auth_models.dart';

/// All application routes (PDF section 10 - routing).
///
/// `/home`, `/services`, `/bookings` and `/profile` are the four bottom
/// navigation destinations and share the home shell with a different tab.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginTypeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (BuildContext context, GoRouterState state) =>
            const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'resetPassword',
        builder: (BuildContext context, GoRouterState state) =>
            ResetPasswordScreen(
          challenge: state.extra is OtpChallenge
              ? state.extra as OtpChallenge
              : null,
        ),
      ),

      // Bottom navigation shell
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(initialTab: 0),
      ),
      GoRoute(
        path: '/services',
        name: 'services',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(initialTab: 1),
      ),
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(initialTab: 2),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(initialTab: 3),
      ),

      // Drawer destinations scheduled for later stages
      _placeholder('/pandits', AppStrings.menuPandits, Icons.face_outlined),
      _placeholder('/events', AppStrings.menuEvents, Icons.celebration_outlined),
      _placeholder('/gallery', AppStrings.menuGallery, Icons.photo_library_outlined),
      _placeholder('/blogs', AppStrings.menuBlogs, Icons.article_outlined),
      _placeholder('/about', AppStrings.menuAbout, Icons.info_outline_rounded),
      _placeholder('/contact', AppStrings.menuContact, Icons.mail_outline_rounded),
      _placeholder('/addresses', AppStrings.menuAddresses, Icons.place_outlined),
      _placeholder('/help', AppStrings.menuHelp, Icons.support_agent_rounded),
      _placeholder(
        '/notifications',
        'Notifications',
        Icons.notifications_none_rounded,
      ),
      _placeholder('/book', AppStrings.bookPujaNow, Icons.event_available_rounded),
    ],
  );
}

GoRoute _placeholder(String path, String title, IconData icon) => GoRoute(
      path: path,
      builder: (BuildContext context, GoRouterState state) =>
          PlaceholderScreen(title: title, icon: icon),
    );
