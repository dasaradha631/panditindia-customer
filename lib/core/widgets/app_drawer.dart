import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/language_selector.dart';
import '../../models/booking.dart';
import '../../models/user_session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/profile_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/booking/booking_flow_screen.dart';
import '../../features/kundali/kundali_screen.dart';
import '../../features/profile/support_screen.dart';
import '../../features/receipts/receipts_screen.dart';
import '../../features/samagri/samagri_orders_screen.dart';
import '../../features/tracking/live_tracking_screen.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

/// Left-side navigation drawer mirroring the web DevoteeNavigation sidebar.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.onSelectTab});

  /// Switches the bottom tab (0 Home, 1 Bookings, 2 Profile).
  final void Function(int) onSelectTab;

  Booking? _activeBooking(BookingProvider bookings) {
    for (final b in bookings.myBookings) {
      if (!b.isCompleted && !b.isCancelled) return b;
    }
    return null;
  }

  void _openLiveGps(BuildContext context, BookingProvider bookings) {
    final nav = Navigator.of(context);
    final b = _activeBooking(bookings);
    if (b == null || b.bookingId == null) {
      showAppToast(
        context,
        context.tr('tracking.noActive'),
        type: ToastType.info,
        title: context.tr('nav.liveGps'),
      );
      nav.pop();
      onSelectTab(1);
      return;
    }
    nav.pop();
    nav.push(
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

  Future<void> _logout(BuildContext context) async {
    final nav = Navigator.of(context);
    final auth = context.read<AuthProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(context.tr('profile.signOutConfirm')),
        content: Text(context.tr('profile.signOutMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.tr('auth.signOut'),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    nav.pop();
    await auth.logout();
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profileP = context.watch<ProfileProvider>();
    final bookings = context.watch<BookingProvider>();
    final session = auth.session;
    final profile = profileP.profile;
    final active = _activeBooking(bookings);
    final nav = Navigator.of(context);

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _header(context),
                  _profileCard(profile, session),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.temple_hindu_rounded,
                          size: 15,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'SACRED DEVOTEE PORTALS',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Text(
                            'VEDIC 2.0',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: AppColors.accentHover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Text(
                      'Quick navigation across your spiritual journey',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        _navItem(
                          icon: Icons.grid_view_rounded,
                          color: AppColors.gold,
                          label: context.tr('nav.overview'),
                          onTap: () {
                            nav.pop();
                            onSelectTab(0);
                          },
                        ),
                        _navItem(
                          icon: Icons.cell_tower_rounded,
                          color: AppColors.danger,
                          label: context.tr('nav.liveGps'),
                          live: active != null,
                          onTap: () => _openLiveGps(context, bookings),
                        ),
                        _navItem(
                          icon: Icons.calendar_month_rounded,
                          color: AppColors.success,
                          label: context.tr('nav.bookings'),
                          count: bookings.myBookings.length,
                          onTap: () {
                            nav.pop();
                            onSelectTab(1);
                          },
                        ),
                        _navItem(
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFF8A4B00),
                          label: context.tr('nav.bookPuja'),
                          highlight: true,
                          onTap: () {
                            nav.pop();
                            bookings.resetDraft(
                              devoteeName:
                                  profile?.fullName ?? auth.session?.name,
                              mobile:
                                  profile?.phonenumber ?? auth.session?.phone,
                              email:
                                  profile?.email ?? auth.session?.email,
                              address: profile?.address,
                              city: profile?.city,
                              state: profile?.state,
                            );
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) => const BookingFlowScreen(),
                              ),
                            );
                          },
                        ),
                        _navItem(
                          icon: Icons.auto_awesome,
                          color: const Color(0xFF4F46E5),
                          label: context.tr('nav.kundali'),
                          vedic: true,
                          onTap: () {
                            nav.pop();
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) => const KundaliScreen(),
                              ),
                            );
                          },
                        ),
                        _navItem(
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.success,
                          label: context.tr('nav.ecoSamagri'),
                          onTap: () {
                            nav.pop();
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) => const SamagriOrdersScreen(),
                              ),
                            );
                          },
                        ),
                        _navItem(
                          icon: Icons.receipt_long_rounded,
                          color: AppColors.purple,
                          label: context.tr('nav.receipts'),
                          onTap: () {
                            nav.pop();
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) => const ReceiptsScreen(),
                              ),
                            );
                          },
                        ),
                        _navItem(
                          icon: Icons.person_outline_rounded,
                          color: AppColors.info,
                          label: context.tr('nav.gotraProfile'),
                          onTap: () {
                            nav.pop();
                            onSelectTab(2);
                          },
                        ),
                        _navItem(
                          icon: Icons.support_agent_rounded,
                          color: const Color(0xFFDB2777),
                          label: context.tr('nav.supportDesk'),
                          onTap: () {
                            nav.pop();
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) => const SupportScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(indent: 12, endIndent: 12, height: 14),
                        _navItem(
                          icon: Icons.logout_rounded,
                          color: AppColors.danger,
                          label: context.tr('nav.logoutDevotee'),
                          danger: true,
                          onTap: () => _logout(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _punyaFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF092B3A), AppColors.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/branding/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Text('🪔', textAlign: TextAlign.center),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(text: 'Pandit'),
                          TextSpan(
                            text: 'India',
                            style: TextStyle(color: AppColors.accent),
                          ),
                          TextSpan(text: ' 🪔', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'DEVOTEE SPIRITUAL DESK',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: LanguageSelectorBar(onDark: true, compact: true),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(CustomerProfile? profile, UserSession? session) {
    final name = profile?.fullName ?? session?.name ?? 'Devotee';
    final gotra = (profile?.gotra?.isNotEmpty ?? false)
        ? profile!.gotra!
        : 'Kashyapa';
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFFF7ED), Color(0xFFFFFBEB)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFFEF3C7),
            backgroundImage: (profile?.profilePhotoUrl?.isNotEmpty ?? false)
                ? NetworkImage(profile!.profilePhotoUrl!)
                : null,
            child: (profile?.profilePhotoUrl?.isNotEmpty ?? false)
                ? null
                : Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF92400E),
                    ),
                    children: [
                      const TextSpan(text: 'Gotra: '),
                      TextSpan(
                        text: gotra,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  '✓ VERIFIED DEVOTEE',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool live = false,
    bool highlight = false,
    bool vedic = false,
    bool danger = false,
    int? count,
  }) {
    final rowColor = danger
        ? AppColors.danger
        : (highlight ? const Color(0xFF9A3412) : AppColors.textDark);
    return Material(
      color: highlight ? const Color(0xFFFFF7ED) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: highlight ? 1 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: highlight
                      ? Border.all(color: const Color(0xFFFF8C00))
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: highlight ? Colors.white : color,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: highlight || danger
                        ? FontWeight.w900
                        : FontWeight.w800,
                    color: rowColor,
                  ),
                ),
              ),
              if (vedic)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Vedic',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              if (live)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (count != null)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accentHover,
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: danger ? AppColors.danger : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRedeemSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RedeemVoucherSheet(),
    );
  }

  Widget _punyaFooter(BuildContext context) {
    // `Material` has no `margin` — the padding lives on the wrapping
    // Container so the card still sits inside the drawer gutter.
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openRedeemSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
            ),
            child: const Row(
              children: [
                Text('🪙', style: TextStyle(fontSize: 17)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '450 Punya Pts',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent, AppColors.accentHover],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    child: Text(
                      'Redeem',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RedeemVoucherSheet extends StatefulWidget {
  const _RedeemVoucherSheet();

  @override
  State<_RedeemVoucherSheet> createState() => _RedeemVoucherSheetState();
}

class _RedeemVoucherSheetState extends State<_RedeemVoucherSheet> {
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _redeem() {
    if (_code.text.trim().isEmpty) {
      showAppToast(
        context,
        'Enter your Punya voucher code to redeem.',
        type: ToastType.warning,
        title: 'Redeem',
      );
      return;
    }
    showAppToast(
      context,
      'Punya voucher redemption is coming soon. Your 450 Punya Pts are safe.',
      type: ToastType.info,
      title: 'Redeem',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Redeem Punya Voucher',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You have 450 Punya Pts. 1 Punya Point = ₹1 discount on any sacred ceremony booking or Eco-Samagri upgrade.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Voucher Code',
                controller: _code,
                hint: 'e.g. PUNYA450',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Redeem',
                icon: Icons.card_giftcard_rounded,
                onPressed: _redeem,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
