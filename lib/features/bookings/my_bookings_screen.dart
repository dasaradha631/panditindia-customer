import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/storage/review_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/receipt_pdf.dart';
import '../../core/widgets/common.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/profile_provider.dart';
import '../booking/booking_flow_screen.dart';
import '../pujas/puja_catalogue_screen.dart';
import '../reviews/review_sheet.dart';
import '../samagri/samagri_orders_screen.dart';
import '../tracking/live_tracking_screen.dart';
import 'booking_actions.dart';
import 'booking_details_screen.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String filter = 'All';
  bool _prompted = false;
  Timer? _retryTimer;
  int _attempts = 0;

  static const _filters = ['All', 'Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptReview());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _maybePromptReview() async {
    if (_prompted || !mounted) return;
    final p = context.read<BookingProvider>();
    for (final b in p.myBookings.where(
      (b) => b.isCompleted && b.bookingId != null,
    )) {
      if (await ReviewStore.isPrompted(b.bookingId)) continue;
      if (!mounted) return;
      _prompted = true;
      await showReviewSheet(
        context,
        bookingId: b.bookingId!,
        ceremonyName: b.ceremony ?? 'the ceremony',
        panditName: b.assignedPandit,
        devoteeName: b.fullName,
        onDone: () {
          if (mounted) context.read<BookingProvider>().loadMyBookings();
        },
      );
      return;
    }
    if (_attempts < 12 && p.myBookings.isEmpty && p.loadingBookings) {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_retryTimer != null) return;
    _attempts++;
    _retryTimer = Timer(const Duration(milliseconds: 500), () {
      _retryTimer = null;
      if (mounted && !_prompted) _maybePromptReview();
    });
  }

  /// Mobile counterpart of the web `handleBookNewCeremony` — opens the
  /// booking wizard with a fresh draft prefilled from the devotee profile.
  void _bookNewCeremony() {
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
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BookingFlowScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BookingProvider>();
    final items = p.filtered(filter);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'My Sacred Ceremony Bookings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                GestureDetector(
                  key: const ValueKey<String>('book-new-ceremony'),
                  onTap: _bookNewCeremony,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentHover],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Book New Ceremony',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                final selected = f == filter;
                return ChoiceChip(
                  label: Text(
                    '$f (${p.filtered(f).length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textDark,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                  onSelected: (_) => setState(() => filter = f),
                );
              },
            ),
          ),
          Expanded(
            child: p.loadingBookings && p.myBookings.isEmpty
                ? const LoadingView(label: 'Loading your bookings...')
                : items.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: filter == 'All'
                        ? 'No bookings yet'
                        : 'No $filter bookings',
                    subtitle: 'Book a puja or homam and it will appear here for tracking.',
                    actionLabel: 'Browse Pujas',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PujaCatalogueScreen(),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: () => p.loadMyBookings(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _BookingTile(booking: items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final color = AppStatus.colorFor(booking.rawStatus);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingDetailsScreen(
            bookingId: booking.bookingId,
            initial: booking,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    booking.displayId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                StatusBadge(
                  label: booking.displayStatus,
                  color: color,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              booking.ceremony ?? 'Puja',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Fmt.date(booking.bookingDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if ((booking.timeSlot ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          booking.timeSlot!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  booking.priceDisplay,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Icon(
                  booking.hasPandit && booking.isAccepted
                      ? Icons.verified_rounded
                      : Icons.hourglass_top_rounded,
                  size: 14,
                  color: booking.hasPandit && booking.isAccepted
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking.hasPandit
                        ? (booking.isAccepted
                              ? 'Acharya ${booking.assignedPandit}'
                              : 'Acharya assigned • Awaiting acceptance')
                        : 'Looking for an Acharya near you',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: booking.hasPandit && booking.isAccepted
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if ((booking.ecokit ?? '').trim().isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.eco_outlined,
                    size: 14,
                    color: AppColors.successDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.ecokit!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.successDark,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            InkWell(
              onTap: () => _showEcoKitSheet(context, booking),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: AppColors.successDark,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'View Items & Prices',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.successDark,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.successDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!booking.isCompleted && !booking.isCancelled)
                  _ActionButton(
                    icon: Icons.location_on_rounded,
                    label: 'Track',
                    color: AppColors.accent,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LiveTrackingScreen(
                          bookingId: booking.bookingId,
                          panditName: booking.assignedPandit,
                          customerAddress:
                              booking.address ?? booking.addressLine1,
                          booking: booking,
                        ),
                      ),
                    ),
                  ),
                if (booking.canReschedule)
                  _ActionButton(
                    icon: Icons.event_repeat_rounded,
                    label: 'Reschedule',
                    color: AppColors.info,
                    onTap: () => showRescheduleSheet(context, booking),
                  ),
                if (!booking.isCompleted && !booking.isCancelled)
                  _ActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    color: AppColors.danger,
                    onTap: () => cancelBookingWithConfirm(context, booking),
                  ),
                _ActionButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Details',
                  color: AppColors.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookingDetailsScreen(
                        bookingId: booking.bookingId,
                        initial: booking,
                      ),
                    ),
                  ),
                ),
                _ActionButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Receipt',
                  color: AppColors.info,
                  onTap: () => ReceiptPdf.share(context, booking),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the per-booking "Eco Kit — View Items & Prices" bottom sheet (mobile
/// counterpart of the web `viewEcoKitModal` in UserDashboardPage.jsx).
///
/// Shows *this* booking's `ecokit` line items, `ecokit_price` and samagri
/// package name, with a secondary link to the global Samagri orders list.
Future<void> _showEcoKitSheet(BuildContext context, Booking booking) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EcoKitSheet(booking: booking),
  );
}

class _EcoKitSheet extends StatelessWidget {
  const _EcoKitSheet({required this.booking});

  final Booking booking;

  /// The stored `ecokit` value is either a single package label
  /// (`Premium Sealed Samagri Kit (₹800)`) or an itemized breakdown
  /// (`Ghee 100ml (₹120 × 2 = ₹240), Kumkum (₹40 × 1 = ₹40), …`).
  /// Split it back into one row per entry so it reads like the web modal.
  List<String> get _items {
    final raw = (booking.ecokit ?? '').trim();
    if (raw.isEmpty) return const [];
    return raw
        .split(RegExp(r'\r?\n'))
        .expand((line) => line.split(', '))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String get _packageName {
    final name = (booking.samagri ?? '').trim();
    return name.isEmpty ? 'Premium Eco-Samagri Kit' : name;
  }

  String get _price {
    final price = booking.ecokitPrice;
    if (price != null) return Fmt.inr(price);
    return Fmt.inr(_packageName.contains('Premium') ? 1200 : 800);
  }

  Widget _metaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.successDark,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final slot = (booking.timeSlot ?? '').trim();
    final hasDate = (booking.bookingDate ?? '').isNotEmpty;
    final dateLine = slot.isEmpty
        ? Fmt.date(booking.bookingDate)
        : '${Fmt.date(booking.bookingDate)} • $slot';
    final devoteeLine = (booking.fullName?.trim().isNotEmpty ?? false)
        ? '${booking.fullName!.trim()}${(booking.mobile?.trim().isNotEmpty ?? false) ? ' (${booking.mobile!.trim()})' : ''}'
        : 'Devotee${(booking.mobile?.trim().isNotEmpty ?? false) ? ' (${booking.mobile!.trim()})' : ''}';
    final cityState = [
      if (booking.city?.trim().isNotEmpty ?? false) booking.city!.trim(),
      if (booking.state?.trim().isNotEmpty ?? false) booking.state!.trim(),
    ].join(', ');
    final addressFallback = [
      if (cityState.isNotEmpty) cityState,
      if (booking.pincode?.trim().isNotEmpty ?? false)
        '- ${booking.pincode!.trim()}',
    ].join(' ');
    final addressLine = booking.address?.trim().isNotEmpty ?? false
        ? booking.address!.trim()
        : (booking.addressLine1?.trim().isNotEmpty ?? false
            ? booking.addressLine1!.trim()
            : (addressFallback.trim().isEmpty ? 'Not provided' : addressFallback));
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.eco_outlined,
                                size: 14,
                                color: AppColors.successDark,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Eco-Samagri Kit Specification',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    color: AppColors.successDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${booking.displayId} • '
                            '${booking.ceremony ?? 'Puja'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _metaRow('Package Type', _packageName),
                      const SizedBox(height: 9),
                      _metaRow('Total Eco-Kit Price', _price),
                      const SizedBox(height: 9),
                      _metaRow('Devotee / Yajman', devoteeLine),
                      if (hasDate) ...[
                        const SizedBox(height: 9),
                        _metaRow('Ceremony Date', dateLine),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.success.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📍 Ceremony & Kit Delivery Address',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: AppColors.successDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppColors.success.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                addressLine,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Included Eco-Kit Items & Price Breakdown',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: items.isEmpty
                      ? const Text(
                          'Standard Eco-Kit inclusions with certified Vedic '
                          'herbs & pure cow ghee.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: AppColors.textDark,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final item in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: AppColors.successDark,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 18),
                AppButton(
                  label: 'View All Samagri Orders',
                  icon: Icons.inventory_2_outlined,
                  variant: AppButtonVariant.outline,
                  onPressed: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.push(
                      MaterialPageRoute(
                        builder: (_) => const SamagriOrdersScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
