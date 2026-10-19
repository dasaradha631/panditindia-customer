import 'package:flutter/material.dart' hide Text;

import '../../core/theme/app_theme.dart';
import '../../core/utils/contact_actions.dart';
import '../../core/utils/receipt_pdf.dart';
import '../../models/booking.dart';
import '../bookings/booking_details_screen.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

/// Opens the booking details modal (port of the web MODAL 4: "BOOKING DETAILS
/// MODAL").
Future<void> showBookingDetailsModal(BuildContext context, Booking booking) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    builder: (_) => BookingDetailsModal(booking: booking, outerContext: context),
  );
}

class BookingDetailsModal extends StatelessWidget {
  const BookingDetailsModal({
    super.key,
    required this.booking,
    required this.outerContext,
  });

  final Booking booking;

  /// The caller's context from outside the dialog route. It outlives this
  /// dialog, so follow-up flows (e.g. the reschedule sheet) stay mounted.
  final BuildContext outerContext;

  @override
  Widget build(BuildContext context) {
    final statusPill = booking.displayStatus;
    final date = Fmt.dateShort(booking.bookingDate);
    final time = booking.timeSlot ?? 'Morning Muhurat';
    final acharya = booking.hasPandit
        ? booking.assignedPandit!
        : 'Allocating Certified Acharya…';
    final address = [
      if ((booking.address ?? '').isNotEmpty) booking.address!,
      if ((booking.addressLine1 ?? '').isNotEmpty) booking.addressLine1!,
      if ((booking.city ?? '').isNotEmpty) booking.city!,
      if ((booking.state ?? '').isNotEmpty) booking.state!,
      if ((booking.pincode ?? '').isNotEmpty) booking.pincode!,
    ].join(', ');

    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 460),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF021824), Color(0xFF1A0A00), Color(0xFF021824)],
                  ),
                  border: Border(
                    bottom: BorderSide(color: AppColors.accent, width: 2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.accent, AppColors.gold],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statusPill,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            booking.ceremony ?? 'Vedic Sacred Ceremony',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.displayId,
                            style: const TextStyle(
                              color: Color(0xFFFCD34D),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ──
              Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _infoCard(
                      label: 'DATE & MUHURAT:',
                      child: Text(
                        '$date • $time',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _infoCard(
                      label: 'ASSIGNED ACHARYA:',
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              acharya,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (booking.hasPandit && booking.panditPhone != null)
                            GestureDetector(
                              onTap: () => callNumber(booking.panditPhone),
                              child: const Icon(
                                Icons.phone_rounded,
                                size: 16,
                                color: AppColors.success,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _infoCard(
                      label: 'VENUE ADDRESS:',
                      child: Text(
                        address.isEmpty ? 'Venue address to be confirmed' : address,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _infoCard(
                      label: 'DAKSHINA & SAMAGRI:',
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              (booking.samagri?.isNotEmpty ?? false)
                                  ? booking.samagri!
                                  : 'Eco-Samagri Kit Included',
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            booking.priceDisplay,
                            style: const TextStyle(
                              color: AppColors.successDark,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Footer ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 2)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _footerButton(
                      context,
                      label: 'Download Receipt',
                      icon: Icons.download_rounded,
                      foreground: const Color(0xFF1D4ED8),
                      background: const Color(0xFFEFF6FF),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      onTap: () => ReceiptPdf.share(context, booking),
                    ),
                    if (booking.canReschedule)
                      _footerButton(
                        context,
                        label: 'Reschedule',
                        icon: Icons.event_rounded,
                        foreground: AppColors.primary,
                        background: AppColors.accent,
                        side: BorderSide.none,
                        onTap: () async {
                          Navigator.of(context).pop();
                          await showRescheduleSheet(outerContext, booking);
                        },
                      ),
                    _footerButton(
                      context,
                      label: 'Close',
                      icon: null,
                      foreground: const Color(0xFF334155),
                      background: const Color(0xFFF1F5F9),
                      side: BorderSide.none,
                      onTap: () => Navigator.of(context).pop(),
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

  Widget _infoCard({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _footerButton(
    BuildContext context, {
    required String label,
    IconData? icon,
    required Color foreground,
    required Color background,
    required BorderSide side,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: side.color, width: side.width),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
