import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../../models/booking_model.dart';

/// Booking summary card used on Home (upcoming) and in My Bookings.
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking, this.onTap, this.compact = false});

  final BookingModel booking;
  final VoidCallback? onTap;
  final bool compact;

  Color get _statusColor => switch (booking.status) {
        BookingStatus.confirmed => AppColors.success,
        BookingStatus.pending => AppColors.gold,
        BookingStatus.inProgress => AppColors.info,
        BookingStatus.completed => AppColors.muted,
        BookingStatus.cancelled => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 13 : 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                booking.status.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              booking.formattedDate,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(booking.serviceTitle, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 5),
                        Row(
                          children: <Widget>[
                            const Icon(Icons.access_time_rounded,
                                size: 14, color: AppColors.muted),
                            const SizedBox(width: 5),
                            Text(booking.formattedTime,
                                style: theme.textTheme.bodySmall),
                            if (booking.panditName != null) ...<Widget>[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  booking.panditName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (!compact &&
                            (booking.address != null ||
                                booking.amount != null)) ...<Widget>[
                          const SizedBox(height: 9),
                          const Divider(),
                          const SizedBox(height: 9),
                          Row(
                            children: <Widget>[
                              if (booking.address != null)
                                Expanded(
                                  child: Row(
                                    children: <Widget>[
                                      const Icon(Icons.place_outlined,
                                          size: 14, color: AppColors.muted),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          booking.address!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (booking.amount != null)
                                Text(
                                  '₹${booking.amount!.toStringAsFixed(0)}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
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
