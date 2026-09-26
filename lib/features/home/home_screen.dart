import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/empty_state.dart';
import 'widgets/home_content.dart';
import 'widgets/home_drawer.dart';

/// Customer home shell: header + hamburger drawer + bottom navigation
/// (PDF section 13 - mobile navigation strategy).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<_Tab> _tabs = <_Tab>[
    _Tab(AppStrings.tabHome, Icons.home_rounded, '/home'),
    _Tab(AppStrings.tabServices, Icons.search_rounded, '/services'),
    _Tab(AppStrings.tabBookings, Icons.receipt_long_rounded, '/bookings'),
    _Tab(AppStrings.tabProfile, Icons.person_rounded, '/profile'),
  ];

  void _goTab(int index) {
    final String path = _tabs[index].path;
    if (GoRouterState.of(context).uri.path == path) return;
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final int tab = widget.initialTab.clamp(0, _tabs.length - 1);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightStatus,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.cream,
        appBar: AppHeader(
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          trailing: HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            badge: true,
            onTap: () => context.go('/notifications'),
          ),
        ),
        drawer: const HomeDrawer(),
        body: IndexedStack(
          index: tab,
          children: const <Widget>[
            HomeContent(),
            EmptyState(
              icon: Icons.search_rounded,
              title: AppStrings.menuServices,
              subtitle: 'Search pujas, havans and ceremonies by category. '
                  'Full discovery lands with Stage 4.',
            ),
            EmptyState(
              icon: Icons.receipt_long_rounded,
              title: AppStrings.menuBookings,
              subtitle: 'Your upcoming, completed and cancelled bookings '
                  'will be listed here.',
            ),
            EmptyState(
              icon: Icons.person_rounded,
              title: AppStrings.menuProfile,
              subtitle: 'Manage your details, saved addresses and '
                  'preferences from here.',
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: _goTab,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primarySoft,
          height: 66,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: List<NavigationDestination>.generate(
            _tabs.length,
            (int index) => NavigationDestination(
              icon: Icon(
                _tabs[index].icon,
                color: AppColors.muted,
              ),
              selectedIcon: Icon(
                _tabs[index].icon,
                color: AppColors.primary,
              ),
              label: _tabs[index].label,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}
