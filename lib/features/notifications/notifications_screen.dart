import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/misc_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../bookings/booking_details_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../kundali/kundali_screen.dart';
import '../profile/support_screen.dart';
import '../receipts/receipts_screen.dart';
import '../samagri/samagri_orders_screen.dart';
import '../tracking/live_tracking_screen.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationsProvider? _notifs;

  @override
  void initState() {
    super.initState();
    _notifs = context.read<NotificationsProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<NotificationsProvider>();
      final id = context.read<AuthProvider>().recipientId;
      p.load(id);
      p.startPolling(id);
    });
  }

  @override
  void dispose() {
    _notifs?.stopPolling();
    super.dispose();
  }

  IconData _iconFor(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'booking':
        return Icons.receipt_long_rounded;
      case 'pandit':
      case 'assignment':
        return Icons.person_pin_rounded;
      case 'payment':
        return Icons.currency_rupee_rounded;
      case 'offer':
      case 'promo':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Widget? _destinationFor(AppNotification n) {
    final text = '${n.title ?? ''} ${n.message ?? ''} ${n.type ?? ''}'
        .toLowerCase();
    if (text.contains('ticket') ||
        text.contains('support') ||
        text.contains('escalation') ||
        text.contains('acharya desk')) {
      return const SupportScreen();
    }
    if (text.contains('samagri') ||
        text.contains('kit') ||
        text.contains('delivery')) {
      return const SamagriOrdersScreen();
    }
    if (text.contains('tracking') ||
        text.contains('gps') ||
        text.contains('en route') ||
        text.contains('transit') ||
        text.contains('started journey')) {
      final bookingId = n.bookingId;
      if (bookingId != null) return LiveTrackingScreen(bookingId: bookingId);
      return _bookingsPane();
    }
    if (text.contains('invoice') ||
        text.contains('receipt') ||
        text.contains('tax') ||
        text.contains('80g')) {
      return const ReceiptsScreen();
    }
    if (text.contains('kundali') ||
        text.contains('astrology') ||
        text.contains('horoscope')) {
      return const KundaliScreen();
    }
    if (text.contains('booking') ||
        text.contains('ceremony') ||
        text.contains('assigned') ||
        text.contains('confirmed') ||
        text.contains('puja')) {
      final bookingId = n.bookingId;
      if (bookingId != null) {
        return BookingDetailsScreen(bookingId: bookingId);
      }
      return _bookingsPane();
    }
    final bookingId = n.bookingId;
    if (bookingId != null) return BookingDetailsScreen(bookingId: bookingId);
    return null;
  }

  Widget _bookingsPane() => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: const GradientAppBar(title: 'My Bookings'),
    body: const MyBookingsScreen(),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NotificationsProvider>();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: GradientAppBar(
        title: 'Notifications',
        actions: [
          if (p.items.isNotEmpty)
            TextButton(
              onPressed: () => p.markAllRead(),
              child: const Text(
                'MARK ALL',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            onSelected: (v) async {
              if (v == 'clear') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    title: const Text('Clear all notifications?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                );
                if (ok == true && mounted) p.clearAll();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'clear',
                child: Text('Clear all notifications'),
              ),
            ],
          ),
        ],
      ),
      body: p.loading && p.items.isEmpty
          ? const LoadingView(label: 'Loading notifications...')
          : p.items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              subtitle: 'Booking updates and offers will show up here.',
            )
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () => p.load(p.recipientId),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: p.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _tile(p, p.items[i]),
              ),
            ),
    );
  }

  Widget _tile(NotificationsProvider p, AppNotification n) {
    return Dismissible(
      key: ValueKey('notif-${n.id ?? n.createdAt ?? n.title}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => p.remove(n),
      child: GestureDetector(
        onTap: () async {
          await p.markRead(n);
          if (!mounted) return;
          final destination = _destinationFor(n);
          if (destination == null) return;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => destination),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.isRead ? Colors.white : AppColors.accentLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: n.isRead
                  ? AppColors.border
                  : AppColors.accent.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  _iconFor(n.type),
                  size: 19,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title ?? 'Notification',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: n.isRead
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          Fmt.relative(n.createdAt),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (n.bookingId != null) ...[
                          const SizedBox(width: 8),
                          const Text(
                            '•',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStatus.displayBookingId(n.bookingId),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
