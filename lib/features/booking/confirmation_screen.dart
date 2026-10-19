import 'package:flutter/material.dart' hide Text;

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../main_shell.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({
    super.key,
    this.bookingId,
    this.message,
    required this.draft,
  });

  final int? bookingId;
  final String? message;
  final dynamic draft;

  @override
  Widget build(BuildContext context) {
    final b = draft.breakdown;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 58,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Request Sent!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message ?? 'A verified Acharya will review and accept your booking shortly. You will be notified as soon as they respond.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textMuted,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    if (bookingId != null) ...[
                      const Text(
                        'BOOKING ID',
                        style: TextStyle(
                          color: Color(0xFF9DB4C0),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        AppStatus.displayBookingId(bookingId),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 24),
                    ],
                    _row('Ceremony', draft.ceremonyName),
                    _row('Date', Fmt.date(draft.date)),
                    _row('Time Slot', draft.timeSlot),
                    _row('Devotee', draft.devoteeName),
                    const Divider(color: Colors.white24, height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total Payable',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          b.totalFormatted,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.accent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No online payment is needed. Pay in cash or UPI directly to the Acharya after the ceremony is completed.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Track My Booking',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 1)),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Back to Home',
                variant: AppButtonVariant.outline,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0)),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF9DB4C0), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
