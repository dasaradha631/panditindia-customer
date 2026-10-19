import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../services/booking_service.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

/// Confirmation dialog -> DELETE -> toast -> list refresh for cancelling a
/// booking. Shared by the details screen and the bookings list tile.
///
/// Returns true when the booking was actually cancelled. [onBusy] brackets
/// the network call so callers can show their own progress state.
Future<bool> cancelBookingWithConfirm(
  BuildContext context,
  Booking booking, {
  void Function(bool busy)? onBusy,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Cancel booking?'),
      content: const Text(
        'Are you sure you want to cancel this ceremony booking? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Keep Booking'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'Cancel Booking',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  onBusy?.call(true);
  final ok = await BookingService().cancelBooking(booking.bookingId);
  onBusy?.call(false);
  if (!context.mounted) return false;

  if (!ok) {
    showAppToast(
      context,
      'Unable to cancel the booking. Please try again.',
      type: ToastType.error,
      title: 'Cancel',
    );
    return false;
  }
  showAppToast(
    context,
    'Booking cancelled successfully.',
    type: ToastType.success,
    title: 'Cancelled',
  );
  await context.read<BookingProvider>().loadMyBookings();
  return context.mounted;
}
