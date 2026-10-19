import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/ceremony_stages.dart';
import '../../core/utils/contact_actions.dart';
import '../../core/utils/receipt_pdf.dart';
import '../../core/widgets/common.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/profile_provider.dart';
import '../auth/auth_design.dart';
import '../notifications/notifications_screen.dart';
import '../pujas/puja_catalogue_screen.dart';
import '../reviews/review_sheet.dart';
import '../tracking/live_tracking_screen.dart';
import 'booking_details_modal.dart';
import 'live_stream_modal.dart';
import 'panchang_service.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

/// Design G header avatar: the devotee's initial inside a gold ring; it
/// leads the bar and opens the navigation drawer.
class _HomeHeaderAvatar extends StatelessWidget {
  const _HomeHeaderAvatar({required this.name, required this.onTap});

  static const Key avatarKey = ValueKey<String>('home-avatar');

  final String? name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final clean = (name ?? '').trim();
    final letter = clean.isEmpty ? 'D' : clean.substring(0, 1).toUpperCase();
    return GestureDetector(
      key: avatarKey,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.85),
            width: 1.6,
          ),
        ),
        child: Text(
          letter,
          textAlign: TextAlign.center,
          textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false, applyHeightToLastDescent: false),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NotificationsProvider? _notifs;
  final PanchangService _panchangService = PanchangService();
  Timer? _clockTimer;
  String _clock = '';
  PanchangToday? _panchang;

  @override
  void initState() {
    super.initState();
    _notifs = context.read<NotificationsProvider>();
    _clock = PanchangService.clockLabel(PanchangService.now());
    // Lightweight minute ticker for the strip clock (web re-runs every second;
    // minute resolution is enough here and keeps rebuilds cheap).
    _clockTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _tickClock(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final notifs = context.read<NotificationsProvider>();
      if (auth.session != null) {
        notifs.load(auth.recipientId);
        notifs.startPolling(auth.recipientId);
      }
      _loadPanchang();
    });
  }

  void _tickClock() {
    if (!mounted) return;
    setState(() => _clock = PanchangService.clockLabel(PanchangService.now()));
  }

  /// Local panchanga first so the strip paints immediately, then the backend
  /// calendar's authoritative values once the devotee is signed in. Both
  /// paths swallow their own failures — the strip only ever loses a field.
  Future<void> _loadPanchang() async {
    if (!mounted) return;
    final profile = context.read<ProfileProvider>().profile;
    final lat = double.tryParse(profile?.latitude ?? '');
    final lon = double.tryParse(profile?.longitude ?? '');
    setState(() {
      _panchang = PanchangService.computeLocal(latitude: lat, longitude: lon);
    });
    if (context.read<AuthProvider>().session == null) return;
    final city = (profile?.city ?? '').trim();
    final state = (profile?.state ?? '').trim();
    final location = <String>[city, state].where((p) => p.isNotEmpty).join(', ');
    final remote = await _panchangService.fetchFromCalendar(
      location: location.isEmpty ? null : location,
    );
    if (!mounted || remote == null) return;
    setState(() {
      _panchang = (_panchang ?? const PanchangToday()).mergedWith(remote);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _notifs?.stopPolling();
    super.dispose();
  }

  void _openCatalogue({String? query}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PujaCatalogueScreen(initialQuery: query),
      ),
    );
  }

  void _openLiveTracking(Booking? booking) {
    if (booking == null || booking.bookingId == null) {
      showAppToast(
        context,
        'No active ceremony to track right now.',
        type: ToastType.info,
        title: 'Live GPS',
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveTrackingScreen(
          bookingId: booking.bookingId,
          panditName: booking.assignedPandit,
          customerAddress: booking.address ?? booking.addressLine1,
          booking: booking,
        ),
      ),
    );
  }

  void _downloadReceipt(Booking b) {
    ReceiptPdf.share(context, b);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bookings = context.watch<BookingProvider>();
    final notifs = context.watch<NotificationsProvider>();

    Booking? hero;
    for (final b in bookings.myBookings) {
      if (!b.isCompleted && !b.isCancelled) {
        hero = b;
        break;
      }
    }
    Booking? completedHero;
    for (final b in bookings.myBookings) {
      if (b.isCompleted) {
        completedHero = b;
        break;
      }
    }

    final totalBookings = bookings.myBookings.length;
    final activeBookings = bookings.myBookings
        .where((b) => !b.isCompleted && !b.isCancelled)
        .length;
    final completedBookings = bookings.myBookings
        .where((b) => b.isCompleted)
        .length;
    final loading =
        bookings.loadingBookings && bookings.myBookings.isEmpty;
    final active = hero;
    final completed = completedHero;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => bookings.loadMyBookings(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            _buildHeader(auth, notifs),
            const SizedBox(height: 12),

            // ═══ PANCHANG & TITHI BAR (web fixed top bar) ═══
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PanchangBar(clock: _clock, panchang: _panchang),
            ),
            const SizedBox(height: 16),

            // ═══ ACTIVE SACRED BOOKING (web overview hero) ═══
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: loading
                  ? const _HeroSkeleton()
                  : active != null
                  ? _ActiveHeroCard(
                      booking: active,
                      onViewDetails: () =>
                          showBookingDetailsModal(context, active),
                      onLiveTrack: () => _openLiveTracking(active),
                      onDownloadReceipt: () => _downloadReceipt(active),
                    )
                  : _EmptyHeroCard(onBookNew: () => _openCatalogue()),
            ),

            if (!loading && active == null && completed != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _CompletedRecap(
                  booking: completed,
                  onBookNext: () => _openCatalogue(),
                  onReceipt: () => _downloadReceipt(completed),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ═══ METRIC STAT CARDS ═══
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.menu_book_rounded,
                          colors: const [
                            Color(0xFFFF8C00),
                            Color(0xFFD4AF37),
                          ],
                          labelColor: const Color(0xFF92400E),
                          border: const Color(0xFFFDE68A),
                          label: 'Total Bookings',
                          value: '$totalBookings',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.hourglass_top_rounded,
                          colors: const [
                            Color(0xFF06B6D4),
                            Color(0xFF6366F1),
                          ],
                          labelColor: const Color(0xFF1E40AF),
                          border: const Color(0xFFBAE6FD),
                          label: 'Pending / Active',
                          value: '$activeBookings',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.check_circle_rounded,
                          colors: const [
                            Color(0xFF10B981),
                            Color(0xFF059669),
                          ],
                          labelColor: const Color(0xFF065F46),
                          border: const Color(0xFFA7F3D0),
                          label: 'Completed',
                          value: '$completedBookings',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.stars_rounded,
                          colors: const [
                            Color(0xFF8B5CF6),
                            Color(0xFFC026D3),
                          ],
                          labelColor: const Color(0xFF6B21A8),
                          border: const Color(0xFFE9D5FF),
                          label: 'Punya Loyalty',
                          value: '450 Pts',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ═══ VIRTUAL PUJA ROOM + DEVOTIONAL OFFICER ═══
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PujaRoomCard(
                onOpenStream: () => showLiveStreamModal(
                  context,
                  ceremony: active?.ceremony,
                  acharya: active?.assignedPandit,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _DevotionalOfficerCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth, NotificationsProvider notifs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HomeHeaderAvatar(
                name: auth.session?.displayName,
                onTap: () => Scaffold.maybeOf(context)?.openDrawer(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jai Shri Ram,',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auth.session?.displayName ?? 'Devotee',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const HeaderLanguagePill(),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Badge(
                    isLabelVisible: notifs.unreadCount > 0,
                    label: Text('${notifs.unreadCount}'),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _openCatalogue(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 19,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Search Pujas, Homam or Festival',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PANCHANG & TITHI BAR (web fixed top bar, UserDashboardPage.jsx:2001-2035)
// ═══════════════════════════════════════════════════════════════════════════

class _PanchangBar extends StatelessWidget {
  const _PanchangBar({required this.clock, required this.panchang});

  /// Live IST clock text from the home state's minute ticker.
  final String clock;

  /// Today's panchanga — null until the first computation lands.
  final PanchangToday? panchang;

  @override
  Widget build(BuildContext context) {
    final abhijit = panchang?.abhijitMuhurat;
    final rahu = panchang?.rahuKaal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF021824), Color(0xFF072B3C), Color(0xFF021824)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.gold],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🪔', style: TextStyle(fontSize: 10)),
                    SizedBox(width: 4),
                    Text(
                      'Panchang & Tithi',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  clock,
                  style: const TextStyle(
                    color: Color(0xFFFCD34D),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            PanchangService.tithiLine(PanchangService.now(), panchang?.tithi),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFFDE68A),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          // Abhijit / Rahu windows hide individually when unknown.
          if (abhijit != null || rahu != null) ...[
            const SizedBox(height: 7),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (abhijit != null)
                  _windowChip(
                    icon: '☀️',
                    color: const Color(0xFFFCD34D),
                    label: 'Abhijit Muhurat:',
                    value: abhijit,
                  ),
                if (rahu != null)
                  _windowChip(
                    icon: '⚠️',
                    color: const Color(0xFFFDA4AF),
                    label: 'Rahu Kaal:',
                    value: rahu,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _windowChip({
    required String icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$icon $label ',
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTIVE SACRED BOOKING HERO
// ═══════════════════════════════════════════════════════════════════════════

class _ActiveHeroCard extends StatelessWidget {
  const _ActiveHeroCard({
    required this.booking,
    required this.onViewDetails,
    required this.onLiveTrack,
    required this.onDownloadReceipt,
  });

  final Booking booking;
  final VoidCallback onViewDetails;
  final VoidCallback onLiveTrack;
  final VoidCallback onDownloadReceipt;

  bool get _assigned => booking.hasPandit;
  bool get _cancelled => booking.isCancelled;

  bool get _enRoute {
    final raw = (booking.rawStatus ?? booking.status ?? '').toLowerCase();
    return raw.contains('route') ||
        raw.contains('transit') ||
        (booking.isTracking ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final life = ceremonyLifecycle(booking);
    final date = Fmt.dateShort(booking.bookingDate);
    final time = booking.timeSlot ?? 'Morning Muhurat';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF021824), Color(0xFF180900), Color(0xFF032533)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Badges ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.gold],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '🪔 Active Sacred Booking',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF34D399).withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  'Sankalpa Locked',
                  style: TextStyle(
                    color: Color(0xFF6EE7B7),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Ceremony ──
          Text(
            booking.ceremony ?? 'Vedic Sacred Ceremony',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Booking Ref: ',
                      style: TextStyle(
                        color: const Color(0xFFFDE68A).withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: booking.displayId,
                      style: const TextStyle(
                        color: Color(0xFFFCD34D),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '•',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              Text(
                booking.priceDisplay,
                style: const TextStyle(
                  color: Color(0xFF6EE7B7),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                '•',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              Text(
                (booking.samagri?.isNotEmpty ?? false)
                    ? booking.samagri!
                    : 'Eco-Samagri Kit Included',
                style: TextStyle(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if ((booking.address ?? '').isNotEmpty ||
              (booking.addressLine1 ?? '').isNotEmpty) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFFB7185),
                  size: 14,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    [booking.address, booking.addressLine1]
                        .where((a) => (a ?? '').isNotEmpty)
                        .join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // ── Status + schedule ──
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusPill(
                  cancelled: _cancelled,
                  enRoute: _enRoute,
                  assigned: _assigned,
                  status: booking.displayStatus,
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_rounded,
                      color: Color(0xFFFBBF24),
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Scheduled: ',
                              style: TextStyle(
                                color: Color(0xFFFDE68A),
                                fontSize: 11.5,
                              ),
                            ),
                            TextSpan(
                              text: '$date • $time',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Lifecycle timeline ──
          _LifecycleTimeline(lifecycle: life),

          // ── Live GPS telemetry bar ──
          if (!_cancelled && _assigned) ...[
            const SizedBox(height: 12),
            _LiveTelemetryBar(
              booking: booking,
              enRoute: _enRoute,
              onTap: onLiveTrack,
            ),
          ],

          // ── Acharya / allocation ──
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 12),
          if (_assigned)
            _AcharyaRow(
              booking: booking,
              onViewDetails: onViewDetails,
              onLiveTrack: onLiveTrack,
            )
          else
            _AllocationNotice(
              onViewDetails: onViewDetails,
              onReceipt: onDownloadReceipt,
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.cancelled,
    required this.enRoute,
    required this.assigned,
    required this.status,
  });

  final bool cancelled;
  final bool enRoute;
  final bool assigned;
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, colors, fg) = cancelled
        ? ('✕ Cancelled', [const Color(0xFFE11D48)], Colors.white)
        : enRoute
        ? (
          '🟢 Acharya En Route (Live GPS)',
          [const Color(0xFFFBBF24), const Color(0xFFF97316), AppColors.accent],
          const Color(0xFF020617),
        )
        : assigned
        ? (
          '✓ Acharya Assigned ($status)',
          [const Color(0xFF10B981), const Color(0xFF0D9488)],
          Colors.white,
        )
        : (
          '✓ Booking Confirmed (Allocating Acharya)',
          [const Color(0xFF2563EB), const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
          Colors.white,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LifecycleTimeline extends StatelessWidget {
  const _LifecycleTimeline({required this.lifecycle});

  final CeremonyLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    if (lifecycle.isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF450A0A).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel_rounded, color: Color(0xFFFCA5A5), size: 17),
                SizedBox(width: 7),
                Text(
                  'CEREMONY BOOKING CANCELLED',
                  style: TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'This ceremony booking was cancelled. 100% refund has been credited to your original payment method or as Punya credits.',
              style: TextStyle(
                color: Color(0xFFFECACA),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, color: AppColors.accent, size: 14),
              const SizedBox(width: 6),
              const Text(
                'SACRED RITUAL LIFECYCLE PROGRESS',
                style: TextStyle(
                  color: Color(0xFFFCD34D),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              for (var i = 0; i < lifecycle.stages.length; i++)
                _StageRow(
                  stage: lifecycle.stages[i],
                  showLine: i < lifecycle.stages.length - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.stage, required this.showLine});

  final CeremonyStage stage;
  final bool showLine;

  static const _done = Color(0xFF6EE7B7);
  static const _current = Color(0xFFFCD34D);
  static const _upcoming = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final done = stage.isDone;
    final current = stage.isCurrent;
    final nodeColor = done
        ? const Color(0xFF059669)
        : current
        ? AppColors.accent
        : const Color(0xFF1E293B);
    final textColor = done ? _done : current ? _current : _upcoming;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: nodeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done
                        ? const Color(0xFF34D399)
                        : current
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF475569),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : Text(
                          '${stage.num}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: current
                                ? AppColors.primary
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                ),
              ),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: done
                        ? const Color(0xFF059669)
                        : const Color(0xFF334155),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? 14 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stage.title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (current)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'CURRENT',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else if (done)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 11,
                              color: Color(0xFF34D399),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Done',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stage.description,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 11,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stage.detail,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTelemetryBar extends StatelessWidget {
  const _LiveTelemetryBar({
    required this.booking,
    required this.enRoute,
    required this.onTap,
  });

  final Booking booking;
  final bool enRoute;
  final VoidCallback onTap;

  String get _telemetry {
    if (enRoute) {
      final eta = booking.etaMinutes;
      final dist = booking.distanceKm;
      if (eta == null && dist == null) {
        return 'En route — waiting for live GPS from Acharya';
      }
      final etaText = eta != null
          ? (eta > 0 ? '$eta Mins' : 'Arrived')
          : 'ETA pending';
      final distText = dist != null ? ' ($dist km away)' : '';
      return 'ETA: $etaText$distText';
    }
    return 'Journey not started — live GPS begins when the Acharya departs';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xE6000000), Color(0xE60F172A), Color(0xE6000000)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LIVE GPS TELEMETRY BROADCAST',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${booking.assignedPandit ?? 'Acharya'}'
                                  '${enRoute ? ' is on transit • ' : ' assigned • '}',
                              style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 11.5,
                              ),
                            ),
                            TextSpan(
                              text: _telemetry,
                              style: const TextStyle(
                                color: Color(0xFFFCD34D),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFFFBBF24), AppColors.accentHover],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broadcast_on_personal, size: 14, color: AppColors.primary),
                    SizedBox(width: 5),
                    Text(
                      'View Full Live Map →',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
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
    );
  }
}

class _AcharyaRow extends StatelessWidget {
  const _AcharyaRow({
    required this.booking,
    required this.onViewDetails,
    required this.onLiveTrack,
  });

  final Booking booking;
  final VoidCallback onViewDetails;
  final VoidCallback onLiveTrack;

  @override
  Widget build(BuildContext context) {
    final name = booking.assignedPandit ?? 'Acharya';
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🕉️ ASSIGNED VEDIC ACHARYA',
                    style: TextStyle(
                      color: Color(0xFFFCD34D),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '✓ ${(booking.panditVeda ?? 'Rigveda')} Scholar',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        '•',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      Text(
                        '${booking.panditExperience ?? '20+'} Yrs Exp',
                        style: const TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 11,
                        ),
                      ),
                      const Text(
                        '•',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      const Text(
                        'Verified Acharya',
                        style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if ((booking.panditPhone ?? '').isNotEmpty) ...[
              _heroButton(
                label: 'Call',
                icon: Icons.call_rounded,
                fg: Colors.white,
                bg: Colors.white.withValues(alpha: 0.15),
                border: Colors.white24,
                onTap: () => callNumber(booking.panditPhone),
              ),
              _heroButton(
                label: 'WhatsApp',
                icon: Icons.chat_rounded,
                fg: Colors.white,
                bg: const Color(0xFF059669),
                border: const Color(0xFF10B981),
                onTap: () => openWhatsApp(booking.panditPhone),
              ),
            ],
            _heroButton(
              label: 'Details',
              icon: Icons.info_outline_rounded,
              fg: Colors.white,
              bg: Colors.white.withValues(alpha: 0.15),
              border: Colors.white24,
              onTap: onViewDetails,
            ),
            _heroButton(
              label: 'Live GPS Track',
              icon: Icons.broadcast_on_personal,
              fg: AppColors.primary,
              bg: AppColors.accent,
              border: AppColors.accent,
              gradient: const [
                AppColors.accent,
                Color(0xFFFBBF24),
                AppColors.accentHover,
              ],
              onTap: onLiveTrack,
            ),
          ],
        ),
      ],
    );
  }

  Widget _heroButton({
    required String label,
    required IconData icon,
    required Color fg,
    required Color bg,
    required Color border,
    List<Color>? gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          gradient: gradient == null ? null : LinearGradient(colors: gradient),
          color: gradient == null ? bg : null,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocationNotice extends StatelessWidget {
  const _AllocationNotice({
    required this.onViewDetails,
    required this.onReceipt,
  });

  final VoidCallback onViewDetails;
  final VoidCallback onReceipt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Color(0xFFFDE68A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allocating Certified Gurukul Acharya',
                      style: TextStyle(
                        color: Color(0xFFFCD34D),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Our Vedic coordinator is matching an Acharya with your Gotra and ceremony dialect. You will receive an SMS and WhatsApp alert once locked.',
                      style: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _noticeButton(
                label: 'View Details',
                fg: Colors.white,
                bg: Colors.white.withValues(alpha: 0.15),
                border: Colors.white24,
                onTap: onViewDetails,
              ),
              _noticeButton(
                label: 'Receipt',
                fg: AppColors.primary,
                bg: Colors.white,
                border: Colors.white,
                onTap: onReceipt,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _noticeButton({
    required String label,
    required Color fg,
    required Color bg,
    required Color border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY + LOADING STATES
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyHeroCard extends StatelessWidget {
  const _EmptyHeroCard({required this.onBookNew});

  final VoidCallback onBookNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF021F2C), Color(0xFF1A0A00), Color(0xFF063447)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text('🪔', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, Color(0xFFFCD34D), AppColors.gold],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '✨ AUSPICIOUS VEDIC PUJAS',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Schedule Your Next Sacred Ceremony',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Experience authentic rituals performed by verified Gurukul Acharyas at your doorstep with 100% pure eco-organic Samagri kits.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFDE68A),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureChip('✨ Verified Gurukul Pandits', Color(0xFFB45309), Color(0x33F59E0B)),
              _FeatureChip('🌿 Pure Organic Samagri', Color(0xFF6EE7B7), Color(0x3310B981)),
              _FeatureChip('📡 Real-Time GPS Tracking', Color(0xFF93C5FD), Color(0x333B82F6)),
            ],
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: onBookNew,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 26,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, Color(0xFFFBBF24), AppColors.accentHover],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department_rounded, size: 19, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Book Auspicious Ceremony Now',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip(this.label, this.fg, this.bg);

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h, Color c) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF021824), Color(0xFF180900), Color(0xFF032533)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(130, 16, AppColors.accent.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          bar(220, 24, Colors.white.withValues(alpha: 0.18)),
          const SizedBox(height: 8),
          bar(170, 12, Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Container(
            height: 92,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    bar(140, 14, Colors.white.withValues(alpha: 0.18)),
                    const SizedBox(height: 6),
                    bar(100, 11, Colors.white.withValues(alpha: 0.1)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPLETED CEREMONY RECAP
// ═══════════════════════════════════════════════════════════════════════════

class _CompletedRecap extends StatelessWidget {
  const _CompletedRecap({
    required this.booking,
    required this.onBookNext,
    required this.onReceipt,
  });

  final Booking booking;
  final VoidCallback onBookNext;
  final VoidCallback onReceipt;

  @override
  Widget build(BuildContext context) {
    final name = booking.assignedPandit ?? 'Acharya';
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final phone = booking.panditPhone;

    return Column(
      children: [
        // ── Success bar ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF02231C), Color(0xFF043324), Color(0xFF02231C)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF34D399).withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '✓ Ceremony Successfully Completed',
                      style: TextStyle(
                        color: Color(0xFF022C22),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Text(
                    'Shubham Bhavatu 🪔',
                    style: TextStyle(
                      color: Color(0xFF6EE7B7),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                booking.ceremony ?? 'Sacred Ceremony',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          'Completed on ${Fmt.dateShort(booking.bookingDate)} • ${booking.city ?? 'Gurugram'} • ',
                      style: const TextStyle(
                        color: Color(0xFFA7F3D0),
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: booking.priceDisplay,
                      style: const TextStyle(
                        color: Color(0xFFFCD34D),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InkWell(
                    onTap: onBookNext,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, Color(0xFFFBBF24), AppColors.accentHover],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Book Next Ceremony',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onReceipt,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download_rounded,
                            size: 14,
                            color: Color(0xFF047857),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Receipt PDF',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Full lifecycle with the final two stages rendered as completed ──
        _LifecycleTimeline(lifecycle: ceremonyLifecycle(booking)),
        const SizedBox(height: 12),

        // ── Pandit profile recap ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFBEB), Color(0xFFFFF7ED), Color(0xFFFFFBEB)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.badge_rounded,
                    color: Color(0xFFD97706),
                    size: 15,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'YOUR CEREMONY PANDIT — FULL PROFILE & VEDIC CREDENTIALS',
                      style: TextStyle(
                        color: Color(0xFF78350F),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Rigveda Acharya',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Verified Acharya',
                          style: TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _credentialTile(
                      'VEDA BRANCH',
                      booking.panditVeda ?? 'Rigveda',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _credentialTile(
                      'EXPERIENCE',
                      '${booking.panditExperience ?? '20+'} Yrs',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _credentialTile('LANGUAGES', 'Hindi, Sanskrit')),
                  const SizedBox(width: 8),
                  Expanded(child: _credentialTile('GURUKUL', 'Kashi Vidyapeeth')),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFFFDE68A)),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 13,
                        color: AppColors.successDark,
                      ),
                      const SizedBox(width: 5),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Acharya Contact: ',
                              style: TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 11.5,
                              ),
                            ),
                            TextSpan(
                              text: phone,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (phone != null && phone.isNotEmpty) ...[
                        _recapButton(
                          label: 'Call',
                          icon: Icons.call_rounded,
                          fg: const Color(0xFF334155),
                          bg: Colors.white,
                          border: const Color(0xFFE2E8F0),
                          onTap: () => callNumber(phone),
                        ),
                        _recapButton(
                          label: 'WhatsApp',
                          icon: Icons.chat_rounded,
                          fg: Colors.white,
                          bg: const Color(0xFF059669),
                          border: const Color(0xFF059669),
                          onTap: () => openWhatsApp(phone),
                        ),
                      ],
                      _recapButton(
                        label: 'Rate Pandit',
                        icon: Icons.star_rounded,
                        fg: AppColors.primary,
                        bg: AppColors.accent,
                        border: AppColors.accent,
                        onTap: () => showReviewSheet(
                          context,
                          bookingId: booking.bookingId ?? 0,
                          ceremonyName: booking.ceremony ?? 'the ceremony',
                          panditName: booking.assignedPandit,
                          devoteeName: booking.fullName,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _credentialTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recapButton({
    required String label,
    required IconData icon,
    required Color fg,
    required Color bg,
    required Color border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STAT TILES
// ═══════════════════════════════════════════════════════════════════════════

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.colors,
    required this.labelColor,
    required this.border,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final List<Color> colors;
  final Color labelColor;
  final Color border;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VIRTUAL PUJA ROOM
// ═══════════════════════════════════════════════════════════════════════════

class _PujaRoomCard extends StatelessWidget {
  const _PujaRoomCard({required this.onOpenStream});

  final VoidCallback onOpenStream;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF021824), Color(0xFF082B3C), Color(0xFF021824)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Real-Time Virtual Puja Room & Chants',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '4K HD Live Stream',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onOpenStream,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _waveBar(10),
                      const SizedBox(width: 4),
                      _waveBar(18),
                      const SizedBox(width: 4),
                      _waveBar(26),
                      const SizedBox(width: 4),
                      _waveBar(18),
                      const SizedBox(width: 4),
                      _waveBar(10),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, Color(0xFFFBBF24), AppColors.accent],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.45),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Join Live HD Ceremony Stream & Sacred Chants',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFCD34D),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Family members across India & abroad can join via private link',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.people_rounded, color: Color(0xFFFBBF24), size: 15),
              const SizedBox(width: 6),
              const Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Private link shared with ',
                        style: TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 11.5,
                        ),
                      ),
                      TextSpan(
                        text: '4 Family Members',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: onOpenStream,
                borderRadius: BorderRadius.circular(8),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open Live Stream',
                      style: TextStyle(
                        color: Color(0xFFFCD34D),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFFCD34D),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _waveBar(double h) {
    return Container(
      width: 4,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DEVOTIONAL OFFICER
// ═══════════════════════════════════════════════════════════════════════════

class _DevotionalOfficerCard extends StatelessWidget {
  const _DevotionalOfficerCard();

  static const String _waNumber = '9118008908334';
  static const String _telNumber = '18008908334';

  Future<void> _whatsapp(BuildContext context) async {
    final ok = await openWhatsApp(_waNumber);
    if (!ok && context.mounted) {
      showAppToast(
        context,
        'WhatsApp could not be opened. Call us on +91 1800-890-8334 instead.',
        type: ToastType.error,
        title: 'WhatsApp',
      );
    }
  }

  Future<void> _call(BuildContext context) async {
    final ok = await callNumber(_telNumber);
    if (!ok && context.mounted) {
      showAppToast(
        context,
        'Dialer could not be opened. Try +91 1800-890-8334.',
        type: ToastType.error,
        title: 'Direct Call',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFFBF5), Color(0xFFFFF7ED)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFCD34D), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.support_agent_rounded,
                color: AppColors.accent,
                size: 17,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Dedicated Devotional Officer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Your dedicated coordinator handles Acharya allocation, custom Havya samagri requests, and Prasad delivery.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A), width: 2),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Text(
                    'PM',
                    style: TextStyle(
                      color: Color(0xFF3730A3),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priya Mukherjee',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Senior Devotional Coordinator',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF4338CA),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 12,
                            color: Color(0xFFD97706),
                          ),
                          SizedBox(width: 5),
                          Text(
                            '+91 1800-890-8334',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: 'WhatsApp',
                  icon: Icons.chat_rounded,
                  fg: const Color(0xFF065F46),
                  bg: const Color(0xFFECFDF5),
                  border: const Color(0xFF34D399),
                  onTap: () => _whatsapp(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  label: 'Direct Call',
                  icon: Icons.call_rounded,
                  fg: AppColors.primary,
                  bg: AppColors.accent,
                  border: AppColors.accent,
                  gradient: const [
                    AppColors.accent,
                    Color(0xFFFBBF24),
                    AppColors.accentHover,
                  ],
                  onTap: () => _call(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color fg,
    required Color bg,
    required Color border,
    List<Color>? gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient == null ? null : LinearGradient(colors: gradient),
          color: gradient == null ? bg : null,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
