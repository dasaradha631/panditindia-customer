import 'package:flutter/material.dart' hide Text;
import 'package:intl/intl.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

/// Mobile port of the web 2026/annual auspicious calendar
/// (`PersonalizedKundliMuhurthamSection.jsx` calendar grid + day drawer).
class AuspiciousCalendar extends StatelessWidget {
  const AuspiciousCalendar({
    super.key,
    required this.calendar,
    required this.month,
    required this.months,
    required this.onMonthChanged,
    required this.selectedDay,
    required this.onTapDay,
    required this.onBookDay,
    this.ceremonyName = '',
    this.location = '',
  });

  /// Backend payload: `{year, month, month_name, first_weekday, location, days:[...]}`.
  final Map<String, dynamic>? calendar;
  final DateTime month;
  final List<DateTime> months;
  final ValueChanged<DateTime> onMonthChanged;
  final Map<String, dynamic>? selectedDay;
  final ValueChanged<Map<String, dynamic>> onTapDay;
  final ValueChanged<Map<String, dynamic>> onBookDay;
  final String ceremonyName;
  final String location;

  static const List<String> _weekdayKeys = <String>[
    'kundali.week.mon',
    'kundali.week.tue',
    'kundali.week.wed',
    'kundali.week.thu',
    'kundali.week.fri',
    'kundali.week.sat',
    'kundali.week.sun',
  ];

  static Color statusColor(String? status) {
    switch (status) {
      case 'excellent':
        return AppColors.success;
      case 'good':
        return AppColors.warning;
      case 'past':
        return const Color(0xFFCBD5E1);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  static Color _statusFill(String? status) {
    switch (status) {
      case 'excellent':
        return const Color(0xFFECFDF5);
      case 'good':
        return const Color(0xFFFFFBEB);
      case 'past':
        return const Color(0xFFF1F5F9);
      default:
        return Colors.white;
    }
  }

  static Color _statusBorder(String? status) {
    switch (status) {
      case 'excellent':
        return const Color(0xFFA7F3D0);
      case 'good':
        return const Color(0xFFFDE68A);
      case 'past':
        return const Color(0xFFE2E8F0);
      default:
        return AppColors.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final data = calendar ?? const <String, dynamic>{};
    final days = (data['days'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];
    final offset = (data['first_weekday'] as num?)?.toInt() ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D021F2C),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              'kundali.calendar.title',
              {'year': '${data['year'] ?? month.year}'},
            ),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('kundali.calendar.subtitle', {
              'ceremony': ceremonyName,
              'location': location,
            }),
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: months.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final m = months[index];
                final selected =
                    m.year == month.year && m.month == month.month;
                return ChoiceChip(
                  key: ValueKey<String>('month-${m.year}-${m.month}'),
                  label: Text(
                    '${DateFormat.MMM(locale).format(m)} ${m.year}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => onMonthChanged(m),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.cream,
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final key in _weekdayKeys)
                Expanded(
                  child: Text(
                    context.tr(key),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.86,
            children: [
              for (var i = 0; i < offset; i++) const SizedBox.shrink(),
              for (final day in days) _dayCell(context, day),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(context, 'excellent', 'kundali.calendar.excellent'),
              const SizedBox(width: 14),
              _legendDot(context, 'good', 'kundali.calendar.good'),
              const SizedBox(width: 14),
              _legendDot(context, 'regular', 'kundali.calendar.regular'),
            ],
          ),
          if (selectedDay != null) ...[
            const SizedBox(height: 14),
            _dayDrawer(context, selectedDay!),
          ],
        ],
      ),
    );
  }

  Widget _legendDot(BuildContext context, String status, String key) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: statusColor(status),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          context.tr(key),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _dayCell(BuildContext context, Map<String, dynamic> day) {
    final status = day['status']?.toString();
    final isPast = day['is_past'] == true || status == 'past';
    final dateKey = day['date']?.toString();
    final selected = dateKey != null && dateKey == selectedDay?['date'];
    final dayNumber = day['day'] ?? dateKey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>('day-$dateKey'),
        onTap: () {
          // Past days stay visible for reference but are never selectable.
          if (isPast) {
            showAppToast(
              context,
              context.tr('kundali.calendar.pastToast'),
              type: ToastType.warning,
              title: 'Calendar',
            );
            return;
          }
          onTapDay(day);
        },
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : _statusFill(status),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : _statusBorder(status),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : (isPast ? AppColors.textMuted : AppColors.textDark),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accent
                      : statusColor(status)
                          .withValues(alpha: isPast ? 0.5 : 1),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, String? status) {
    switch (status) {
      case 'excellent':
        return context.tr('kundali.calendar.excellent');
      case 'good':
        return context.tr('kundali.calendar.good');
      case 'past':
        return context.tr('kundali.calendar.pastDate');
      default:
        return context.tr('kundali.calendar.regular');
    }
  }

  Widget _dayDrawer(BuildContext context, Map<String, dynamic> day) {
    final status = day['status']?.toString();
    final rows = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('kundali.calendar.status'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9FB3BF),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: statusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    _statusLabel(context, status),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _drawerRow(
        context,
        label: context.tr('kundali.calendar.window'),
        value: day['available_muhurtham']?.toString() ?? '-',
      ),
      _drawerRow(
        context,
        label: context.tr('kundali.calendar.ceremony'),
        value: day['recommended_ceremony']?.toString() ?? ceremonyName,
      ),
      if (day['nakshatra'] != null)
        _drawerRow(
          context,
          label: 'Nakshatra',
          value: day['nakshatra'].toString(),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (day['display_date']?.toString().isNotEmpty ?? false)
                ? day['display_date'].toString()
                : Fmt.date(day['date']?.toString()),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey<String>('calendar-book-day'),
              onPressed: () => onBookDay(day),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                context.tr('kundali.calendar.bookForDate'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9FB3BF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
