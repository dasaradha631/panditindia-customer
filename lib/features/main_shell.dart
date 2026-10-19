import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/common.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/profile_provider.dart';
import 'booking/booking_flow_screen.dart';
import 'bookings/my_bookings_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'tracking/live_tracking_screen.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  /// Pane to open on first build (0 = Home/Overview, 1 = My Bookings,
  /// 2 = Profile) — lets the post-booking confirmation land the devotee on
  /// the right tab instead of always resetting to Home.
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int index = 0;
  BookingProvider? _bookings;

  /// Previously visited panes so the system back gesture steps backwards
  /// through each screen the user came through instead of closing the app.
  final List<int> _history = [];

  void _go(int next) {
    if (next == index) return;
    setState(() {
      _history.add(index);
      index = next;
    });
  }

  /// System back: close the open drawer first, then return to the previous
  /// pane, then to Home, and only exit once the user is back at the start.
  void _handleBack() {
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
      return;
    }
    if (_history.isNotEmpty) {
      setState(() => index = _history.removeLast());
      return;
    }
    if (index != 0) {
      setState(() => index = 0);
      return;
    }
    SystemNavigator.pop();
  }

  void _showOverview() {
    if (mounted) _go(0);
  }

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    MainTabBridge.showOverview = _showOverview;
    final bookings = context.read<BookingProvider>();
    _bookings = bookings;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bookings.loadMyBookings();
      bookings.startPolling();
    });
  }

  @override
  void dispose() {
    MainTabBridge.showOverview = null;
    _bookings?.stopPolling();
    super.dispose();
  }

  Booking? get _activeBooking {
    for (final b in _bookings?.myBookings ?? const <Booking>[]) {
      if (!b.isCompleted && !b.isCancelled) return b;
    }
    return null;
  }

  void _openBookingFlow() {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final bookings = context.read<BookingProvider>();
    bookings.resetDraft(
      devoteeName: profile.profile?.fullName ?? auth.session?.name,
      mobile: profile.profile?.phonenumber ?? auth.session?.phone,
      email: profile.profile?.email ?? auth.session?.email,
      address: profile.profile?.address,
      city: profile.profile?.city,
      state: profile.profile?.state,
      gothram: profile.profile?.gotra,
      nakshatra: profile.profile?.nakshatra,
      rashi: profile.profile?.rashi,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BookingFlowScreen()),
    );
  }

  void _openTrack() {
    final b = _activeBooking;
    if (b == null || b.bookingId == null) {
      showAppToast(
        context,
        context.tr('tracking.noActive'),
        type: ToastType.info,
        title: context.tr('nav.track'),
      );
      _go(1);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveTrackingScreen(
          bookingId: b.bookingId,
          panditName: b.assignedPandit,
          customerAddress: b.address ?? b.addressLine1,
          booking: b,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const MyBookingsScreen(),
      ProfileScreen(onTab: _go),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.cream,
        drawer: AppDrawer(onSelectTab: _go),
        body: IndexedStack(index: index, children: screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      _navItem(
                        0,
                        Icons.home_outlined,
                        Icons.home_rounded,
                        context.tr('nav.home'),
                      ),
                      _navItem(
                        1,
                        Icons.menu_book_outlined,
                        Icons.menu_book_rounded,
                        context.tr('nav.bookings'),
                      ),
                      const Expanded(child: SizedBox()),
                      _trackItem(),
                      _navItem(
                        2,
                        Icons.person_outline,
                        Icons.person_rounded,
                        context.tr('nav.profile'),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: -30,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _bookFab(),
                        const SizedBox(height: 10),
                        Text(
                          context.tr('nav.book').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookFab() {
    return GestureDetector(
      key: const ValueKey<String>('nav-book-fab'),
      onTap: _openBookingFlow,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accent, AppColors.accentHover],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _trackItem() {
    final live = _activeBooking != null;
    final color = live ? AppColors.danger : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: _openTrack,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  live
                      ? Icons.location_on_rounded
                      : Icons.location_on_outlined,
                  color: color,
                  size: 23,
                ),
                if (live)
                  Positioned(
                    top: -1,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.4),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              context.tr('nav.track').toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, IconData activeIcon, String label) {
    final selected = index == i;
    return Expanded(
      child: InkWell(
        onTap: () => _go(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected ? AppColors.accent : AppColors.textMuted,
              size: 23,
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
