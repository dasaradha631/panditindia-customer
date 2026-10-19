import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/storage/review_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../services/booking_service.dart';
import '../reviews/review_sheet.dart';
import '../tracking/live_tracking_screen.dart';
import 'booking_actions.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key, this.bookingId, this.initial});

  final int? bookingId;
  final Booking? initial;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final BookingService _service = BookingService();
  Booking? booking;
  bool loading = true;
  bool busy = false;
  bool _autoPromptTried = false;

  @override
  void initState() {
    super.initState();
    booking = widget.initial;
    _load();
  }

  Future<void> _load() async {
    final id = widget.bookingId ?? widget.initial?.bookingId;
    if (id != null) {
      final fresh = await _service.getBooking(id);
      if (fresh != null) booking = fresh;
    }
    if (mounted) setState(() => loading = false);
    _maybeAutoPromptReview();
  }

  Future<void> _maybeAutoPromptReview() async {
    final b = booking;
    if (_autoPromptTried ||
        b == null ||
        b.bookingId == null ||
        !b.isCompleted) {
      return;
    }
    _autoPromptTried = true;
    if (await ReviewStore.isPrompted(b.bookingId)) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _review();
    });
  }

  Future<void> _refresh() async {
    final id = widget.bookingId ?? booking?.bookingId;
    if (id == null) return;
    final fresh = await _service.getBooking(id);
    if (fresh != null && mounted) setState(() => booking = fresh);
    if (mounted) context.read<BookingProvider>().loadMyBookings();
  }

  Future<void> _cancel() async {
    final current = booking;
    if (current == null) return;
    final ok = await cancelBookingWithConfirm(
      context,
      current,
      onBusy: (value) {
        if (mounted) setState(() => busy = value);
      },
    );
    if (!mounted || !ok) return;
    await _refresh();
  }

  Future<void> _reschedule() async {
    final id = booking?.bookingId;
    if (id == null) return;
    setState(() => busy = true);
    final options = await _service.rescheduleOptions(id);
    setState(() => busy = false);
    if (!mounted) return;
    if (options == null) {
      showAppToast(
        context,
        'No alternate slots are available for this booking.',
        type: ToastType.warning,
        title: 'Reschedule',
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RescheduleSheet(
        bookingId: id,
        options: options,
        onDone: () {
          _refresh();
          context.read<BookingProvider>().loadMyBookings();
        },
      ),
    );
  }

  Future<void> _review() async {
    final b = booking;
    final id = b?.bookingId;
    if (b == null || id == null) return;
    await showReviewSheet(
      context,
      bookingId: id,
      ceremonyName: b.ceremony ?? 'the ceremony',
      panditName: b.assignedPandit,
      devoteeName: b.fullName,
      onDone: _refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: GradientAppBar(
        title: 'Booking Details',
        actions: [
          IconButton(
            onPressed: loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
      body: loading && b == null
          ? const LoadingView(label: 'Loading booking...')
          : b == null
          ? const EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Booking not found',
              subtitle: 'This booking may have been removed.',
            )
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _header(b),
                  const SizedBox(height: 16),
                  _statusCard(b),
                  const SizedBox(height: 16),
                  if (b.hasPandit) ...[
                    _panditCard(b),
                    const SizedBox(height: 16),
                  ],
                  _infoCard(b),
                  const SizedBox(height: 16),
                  _ritualCard(b),
                  const SizedBox(height: 20),
                  ..._actions(b),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _header(Booking b) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  b.displayId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: b.displayStatus,
                color: AppStatus.colorFor(b.rawStatus),
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            b.ceremony ?? 'Puja',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: AppColors.gold,
              ),
              const SizedBox(width: 7),
              Text(
                Fmt.date(b.bookingDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.wb_twilight_outlined,
                size: 15,
                color: AppColors.gold,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  b.timeSlot ?? '-',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Amount',
                  style: TextStyle(color: Color(0xFF9DB4C0), fontSize: 12.5),
                ),
              ),
              Text(
                b.priceDisplay,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusCard(Booking b) {
    final steps = [
      ('Requested', Icons.bookmark_added_outlined),
      ('Acharya Assigned', Icons.person_search_outlined),
      ('Accepted', Icons.verified_user_outlined),
      ('Ceremony', Icons.local_fire_department_outlined),
      ('Completed', Icons.check_circle_outline),
    ];
    final raw = (b.rawStatus ?? '').toLowerCase();
    var current = 0;
    if (b.hasPandit) current = 1;
    if (b.hasPandit && b.isAccepted) current = 2;
    if (raw.contains('route') ||
        raw.contains('arrived') ||
        raw.contains('progress') ||
        raw.contains('aarti')) {
      current = 3;
    }
    if (b.isCompleted) current = 4;
    if (b.isCancelled) current = -1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Progress',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          ...steps.asMap().entries.map((e) {
            final i = e.key;
            final (label, icon) = e.value;
            final done = current >= i && current >= 0;
            final active = current == i;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? AppColors.success : Colors.white,
                        border: Border.all(
                          color: done ? AppColors.success : AppColors.border,
                          width: 1.8,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 15,
                        color: done ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 24,
                        color: current > i
                            ? AppColors.success
                            : AppColors.border,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                        color: done ? AppColors.textDark : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                if (active)
                  const StatusBadge(
                    label: 'Now',
                    color: AppColors.accent,
                    dense: true,
                  ),
              ],
            );
          }),
          if (b.isCancelled) ...[
            const SizedBox(height: 10),
            const StatusBadge(label: 'Cancelled', color: AppColors.danger),
            if (b.declineReason != null && b.declineReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: ${b.declineReason}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _panditCard(Booking b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.4),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 18,
                color: AppColors.gold,
              ),
              SizedBox(width: 8),
              Text(
                'Your Acharya',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.accentLight,
                backgroundImage:
                    (b.panditPhoto != null && b.panditPhoto!.isNotEmpty)
                    ? NetworkImage(b.panditPhoto!)
                    : null,
                child: (b.panditPhoto == null || b.panditPhoto!.isEmpty)
                    ? const Text('🕉', style: TextStyle(fontSize: 22))
                    : null,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            b.assignedPandit ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (b.panditVerified == true) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified,
                            size: 15,
                            color: AppColors.info,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                            if (b.panditExperience != null &&
                                b.panditExperience!.isNotEmpty)
                              b.panditExperience!,
                            if (b.panditVeda != null &&
                                b.panditVeda!.isNotEmpty)
                              b.panditVeda!,
                            if (b.panditCity != null &&
                                b.panditCity!.isNotEmpty)
                              b.panditCity!,
                          ].join(' • ').isEmpty
                          ? 'Verified Pandit'
                          : [
                              if (b.panditExperience != null &&
                                  b.panditExperience!.isNotEmpty)
                                b.panditExperience!,
                              if (b.panditVeda != null &&
                                  b.panditVeda!.isNotEmpty)
                                b.panditVeda!,
                              if (b.panditCity != null &&
                                  b.panditCity!.isNotEmpty)
                                b.panditCity!,
                            ].join(' • '),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 7),
                    StatusBadge(
                      label: b.isAccepted ? 'Accepted' : 'Awaiting Acceptance',
                      color: b.isAccepted
                          ? AppColors.success
                          : AppColors.warning,
                      dense: true,
                    ),
                  ],
                ),
              ),
              if (b.isAccepted &&
                  b.panditPhone != null &&
                  b.panditPhone!.isNotEmpty)
                _iconAction(
                  icon: Icons.call_rounded,
                  color: AppColors.success,
                  onTap: () => showAppToast(
                    context,
                    'Call Acharya on ${b.panditPhone}',
                    type: ToastType.info,
                    title: 'Contact',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }

  Widget _infoCard(Booking b) {
    // Venue address: the stored address may already carry the pincode (the
    // GPS-detected full address does), so only append a separate pincode when
    // it isn't already present — avoids "…524227, India - 524227".
    final baseAddress = (b.address ?? b.addressLine1 ?? '').trim();
    final pin = (b.pincode ?? '').trim();
    final venue = [
      if (baseAddress.isNotEmpty) baseAddress,
      if (pin.isNotEmpty && !baseAddress.contains(pin)) pin,
    ].join(' - ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ceremony Details',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const Divider(height: 20),
          InfoRow(
            label: 'Devotee',
            value: b.fullName ?? '-',
            icon: Icons.person_outline,
          ),
          if (b.mobile != null && b.mobile!.isNotEmpty)
            InfoRow(
              label: 'Mobile',
              value: b.mobile!,
              icon: Icons.phone_outlined,
            ),
          if (b.email != null && b.email!.isNotEmpty)
            InfoRow(
              label: 'Email',
              value: b.email!,
              icon: Icons.email_outlined,
            ),
          InfoRow(
            label: 'Language',
            value: b.language ?? '-',
            icon: Icons.translate_outlined,
          ),
          InfoRow(
            label: 'City',
            value:
                [
                  b.city,
                  b.state,
                ].where((s) => s != null && s.isNotEmpty).join(', ').isEmpty
                ? '-'
                : [
                    b.city,
                    b.state,
                  ].where((s) => s != null && s.isNotEmpty).join(', '),
            icon: Icons.location_on_outlined,
          ),
          InfoRow(
            label: 'Address',
            value: venue.isEmpty ? '-' : venue,
            icon: Icons.home_outlined,
          ),
          if (b.samagri != null && b.samagri!.isNotEmpty)
            InfoRow(
              label: 'Samagri',
              value: b.samagri!,
              icon: Icons.inventory_2_outlined,
            ),
        ],
      ),
    );
  }

  Widget _ritualCard(Booking b) {
    final rows = <(String, String)>[
      if (b.gothram != null && b.gothram!.isNotEmpty) ('Gothram', b.gothram!),
      if (b.nakshatra != null && b.nakshatra!.isNotEmpty)
        ('Nakshatra', b.nakshatra!),
      if (b.rashi != null && b.rashi!.isNotEmpty) ('Rashi', b.rashi!),
      if (b.specialRequests != null && b.specialRequests!.isNotEmpty)
        ('Special Requests', b.specialRequests!),
      if (b.createdAt != null && b.createdAt!.isNotEmpty)
        ('Booked On', Fmt.relative(b.createdAt)),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ritual Information',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const Divider(height: 20),
          ...rows.map((r) => InfoRow(label: r.$1, value: r.$2)),
        ],
      ),
    );
  }

  List<Widget> _actions(Booking b) {
    final widgets = <Widget>[];
    if (b.isCompleted) {
      widgets.add(
        AppButton(
          label: 'Write a Review',
          icon: Icons.star_outline,
          onPressed: _review,
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }
    if (!b.isCompleted && !b.isCancelled) {
      widgets.add(
        AppButton(
          label: 'Live Tracking',
          icon: Icons.my_location_rounded,
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LiveTrackingScreen(
                bookingId: b.bookingId,
                panditName: b.assignedPandit,
                customerAddress: b.address ?? b.addressLine1,
                booking: b,
              ),
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }
    if (b.canReschedule) {
      widgets.add(
        AppButton(
          label: 'Reschedule Ceremony',
          icon: Icons.event_repeat_rounded,
          variant: AppButtonVariant.outline,
          onPressed: busy ? null : _reschedule,
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }
    if (!b.isCompleted && !b.isCancelled) {
      widgets.add(
        AppButton(
          label: busy ? 'Please wait...' : 'Cancel Booking',
          icon: Icons.cancel_outlined,
          variant: AppButtonVariant.danger,
          loading: busy,
          onPressed: _cancel,
        ),
      );
    }
    return widgets;
  }
}

/// Opens the reschedule bottom sheet for [booking] from anywhere (details
/// modal, overview cards). Returns true when the reschedule went through.
Future<bool> showRescheduleSheet(BuildContext context, Booking booking) async {
  final id = booking.bookingId;
  if (id == null) return false;
  final options = await BookingService().rescheduleOptions(id);
  if (!context.mounted) return false;
  if (options == null) {
    showAppToast(
      context,
      'No alternate slots are available for this booking.',
      type: ToastType.warning,
      title: 'Reschedule',
    );
    return false;
  }
  var applied = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RescheduleSheet(
      bookingId: id,
      options: options,
      onDone: () {
        applied = true;
        if (context.mounted) context.read<BookingProvider>().loadMyBookings();
      },
    ),
  );
  return applied;
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({
    required this.bookingId,
    required this.options,
    required this.onDone,
  });

  final int bookingId;
  final Map<String, dynamic> options;
  final VoidCallback onDone;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  final BookingService _service = BookingService();
  String? date;
  String? slot;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final currentDate =
        '${widget.options['current_date'] ?? ''}'.split('T').first;
    final match = _options
        .where((o) => o.date == currentDate && o.available)
        .firstOrNull;
    final preferred = match ?? _options.where((o) => o.available).firstOrNull;
    date = preferred?.date;
    slot = _slots.where((s) => s.available).firstOrNull?.name;
  }

  /// Normalizes the `GET /bookings/{id}/reschedule-options` payload
  /// (`available_dates[{date, formatted_date, is_available,
  /// available_slot_count, slots[]}]`) plus the older `{dates, slots}` shape
  /// into one list.
  List<_DateOption> get _options {
    final raw = widget.options['available_dates'];
    if (raw is List && raw.isNotEmpty) {
      final parsed = <_DateOption>[];
      for (final entry in raw.whereType<Map>()) {
        final value = '${entry['date'] ?? ''}';
        if (value.isEmpty) continue;
        final slots = <_SlotOption>[];
        final slotsRaw = entry['slots'];
        if (slotsRaw is List) {
          for (final s in slotsRaw) {
            if (s is! Map) {
              slots.add(_SlotOption(s.toString()));
              continue;
            }
            final label = _slotLabel(s);
            if (label.isEmpty) continue;
            slots.add(
              _SlotOption(
                label,
                available: s['is_available'] != false,
                type: _cleanText(s['type']),
                desc: _cleanText(s['desc']),
                conflictReason: _cleanText(s['conflict_reason']),
              ),
            );
          }
        }
        final countRaw = entry['available_slot_count'];
        parsed.add(
          _DateOption(
            value,
            label: entry['formatted_date']?.toString() ??
                entry['day_name']?.toString(),
            available: entry['is_available'] != false,
            slotCount:
                countRaw is int ? countRaw : int.tryParse('${countRaw ?? ''}'),
            slots: slots,
          ),
        );
      }
      if (parsed.isNotEmpty) return parsed;
    }
    final legacyDates = widget.options['dates'];
    if (legacyDates is List) {
      final slots =
          _slotOptions(widget.options['slots'] ?? widget.options['time_slots']);
      return legacyDates
          .map((d) => _DateOption(d.toString(), slots: slots))
          .where((o) => o.date.isNotEmpty)
          .toList();
    }
    return const [];
  }

  _DateOption? get _selected =>
      _options.where((o) => o.date == date).firstOrNull;

  List<_SlotOption> get _slots {
    final forDate = _selected?.slots;
    if (forDate != null && forDate.isNotEmpty) return forDate;
    final standard = _slotOptions(widget.options['standard_slots']);
    if (standard.isNotEmpty) return standard;
    return _slotOptions(widget.options['slots'] ?? widget.options['time_slots']);
  }

  static String _slotLabel(dynamic slot) {
    if (slot is Map) return '${slot['name'] ?? slot['id'] ?? ''}'.trim();
    return slot.toString().trim();
  }

  static String? _cleanText(dynamic value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  static List<_SlotOption> _slotOptions(dynamic raw) {
    if (raw is! List) return const [];
    final parsed = <_SlotOption>[];
    for (final s in raw) {
      final label = _slotLabel(s);
      if (label.isEmpty) continue;
      if (s is Map) {
        parsed.add(
          _SlotOption(
            label,
            available: s['is_available'] != false,
            type: _cleanText(s['type']),
            desc: _cleanText(s['desc']),
            conflictReason: _cleanText(s['conflict_reason']),
          ),
        );
      } else {
        parsed.add(_SlotOption(label));
      }
    }
    return parsed;
  }

  void _selectDate(String next) {
    date = next;
    slot = _slots.where((s) => s.available).firstOrNull?.name;
    setState(() {});
  }

  Future<void> _apply() async {
    if (date == null || slot == null) {
      showAppToast(
        context,
        'Please pick a date and a time slot.',
        type: ToastType.warning,
        title: 'Reschedule',
      );
      return;
    }
    setState(() => saving = true);
    final ok = await _service.reschedule(
      widget.bookingId,
      date: date!,
      timeSlot: slot!,
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (!ok) {
      showAppToast(
        context,
        'Could not reschedule. Please try again.',
        type: ToastType.error,
        title: 'Reschedule',
      );
      return;
    }
    showAppToast(
      context,
      'Your booking has been rescheduled.',
      type: ToastType.success,
      title: 'Rescheduled',
    );
    widget.onDone();
    if (mounted) Navigator.of(context).pop();
  }

  Widget _slotBadge(
    String text, {
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(22),
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
              const Text(
                'Reschedule Ceremony',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pick a new date and Muhurat slot available with your Acharya.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              if (_options.isEmpty)
                const Text(
                  'No alternate dates are currently available.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                )
              else ...[
                const Text(
                  'NEW DATE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _options.take(12).map((option) {
                    final selected = option.date == date;
                    final enabled = option.available;
                    final badge = enabled
                        ? (option.slotCount != null
                            ? '${option.slotCount} Slots'
                            : null)
                        : 'Booked';
                    return ChoiceChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            option.label != null
                                ? '${Fmt.date(option.date)} · ${option.label}'
                                : Fmt.date(option.date),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: enabled ? null : AppColors.textMuted,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: enabled
                                    ? AppColors.accentLight
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: enabled
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      selected: selected,
                      selectedColor: AppColors.accent,
                      backgroundColor:
                          enabled ? AppColors.cream : const Color(0xFFF1F5F9),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textDark,
                      ),
                      side: BorderSide(
                        color: selected ? AppColors.accent : AppColors.border,
                      ),
                      onSelected: enabled ? (_) => _selectDate(option.date) : null,
                    );
                  }).toList(),
                ),
              ],
              if (_slots.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'NEW TIME SLOT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                ..._slots.map((s) {
                  final enabled = s.available;
                  final selected = enabled && s.name == slot;
                  return GestureDetector(
                    onTap: enabled ? () => setState(() => slot = s.name) : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: !enabled
                            ? const Color(0xFFF1F5F9)
                            : selected
                                ? AppColors.accentLight
                                : AppColors.cream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 18,
                            color: !enabled
                                ? AppColors.textMuted
                                : selected
                                    ? AppColors.accent
                                    : AppColors.border,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: enabled
                                        ? AppColors.textDark
                                        : AppColors.textMuted,
                                  ),
                                ),
                                if (s.type != null || !enabled) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if (s.type != null)
                                        _slotBadge(
                                          s.type!,
                                          color: const Color(0xFF92400E),
                                          background: const Color(0xFFFEF3C7),
                                        ),
                                      if (!enabled)
                                        _slotBadge(
                                          s.conflictReason ?? 'Occupied',
                                          color: const Color(0xFFBE123C),
                                          background: const Color(0xFFFCE7F3),
                                        ),
                                    ],
                                  ),
                                ],
                                if (s.desc != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    s.desc!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 14),
              AppButton(
                label: 'Confirm Reschedule',
                loading: saving,
                onPressed: _apply,
              ),
            ],
          ),
        ),
      ),
    ),
  ),
    );
  }
}

/// One reschedulable date with its slots, normalized from the
/// `reschedule-options` payload.
class _DateOption {
  const _DateOption(
    this.date, {
    this.label,
    this.available = true,
    this.slotCount,
    this.slots = const [],
  });

  final String date;
  final String? label;
  final bool available;
  final int? slotCount;
  final List<_SlotOption> slots;
}

/// One muhurat slot within a date, kept even when unavailable so conflicts
/// can be shown (mirrors the web reschedule modal).
class _SlotOption {
  const _SlotOption(
    this.name, {
    this.available = true,
    this.type,
    this.desc,
    this.conflictReason,
  });

  final String name;
  final bool available;
  final String? type;
  final String? desc;
  final String? conflictReason;
}
