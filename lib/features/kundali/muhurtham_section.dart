import 'package:flutter/material.dart' hide Text;

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../services/kundli_service.dart';
import 'auspicious_calendar.dart';
import 'kundali_data.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

/// Book handoff used by the section to seed the booking flow (step 2).
typedef MuhurthamBookCallback = void Function({
  required MuhurthamCeremony ceremony,
  required String date,
  required String timeSlot,
  required String location,
});

/// Mobile port of the web Muhurtham engine
/// (`PersonalizedKundliMuhurthamSection.jsx`): ceremony/location form,
/// loading stages, ranked recommendation cards, auspicious calendar and
/// traditional Vedic disclaimer.
class MuhurthamSection extends StatefulWidget {
  const MuhurthamSection({
    super.key,
    required this.birth,
    required this.onBook,
  });

  final KundaliBirthDetails birth;
  final MuhurthamBookCallback onBook;

  @override
  State<MuhurthamSection> createState() => _MuhurthamSectionState();
}

class _MuhurthamSectionState extends State<MuhurthamSection> {
  final KundliService _service = KundliService();
  final TextEditingController _customLocationCtrl = TextEditingController();

  late MuhurthamCeremony _ceremony;
  late String _location;
  bool _customLocation = false;
  bool _calculating = false;
  int _stage = 0;
  String? _notice;
  List<Map<String, dynamic>> _recs = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _matches = const <Map<String, dynamic>>[];
  Map<String, dynamic>? _calendar;
  Map<String, dynamic>? _selectedDay;
  String? _disclaimer;
  int? _expanded;
  late DateTime _month;
  late final List<DateTime> _months;
  bool _autoStarted = false;

  @override
  void initState() {
    super.initState();
    _ceremony = kMuhurthamCeremonies.first;
    final birthPlace = widget.birth.placeOfBirth;
    _location = (birthPlace != null && kPopularLocations.contains(birthPlace))
        ? birthPlace
        : kPopularLocations.first;
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    // Web parity: year dropdown offers current + next year, month dropdown
    // all 12 months of either year (PersonalizedKundliMuhurthamSection.jsx
    // year select `[currentYear, currentYear + 1]`, month select 1..12).
    _months = List<DateTime>.generate(
      24,
      (i) => DateTime(now.year + i ~/ 12, (i % 12) + 1),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAutoStart();
  }

  @override
  void didUpdateWidget(covariant MuhurthamSection old) {
    super.didUpdateWidget(old);
    _maybeAutoStart();
  }

  /// Mirrors the web engine: once birth details are complete the section
  /// calculates on its own (initial load or right after the birth modal
  /// saved a newly complete profile).
  void _maybeAutoStart() {
    if (_autoStarted || !widget.birth.isComplete) return;
    _autoStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_calculating && _recs.isEmpty) _calculate(toast: false);
    });
  }

  @override
  void dispose() {
    _customLocationCtrl.dispose();
    super.dispose();
  }

  String get _locationText =>
      _customLocation ? _customLocationCtrl.text.trim() : _location;

  /// "More dates" on a cross-ceremony match selects that ceremony and
  /// recalculates (web `ceremonyRecommendations` → `handleCalculateMuhurtham`).
  void _moreDates(String ceremonyName) {
    final match = kMuhurthamCeremonies
        .where((c) => c.name == ceremonyName)
        .toList();
    if (match.isNotEmpty && match.first != _ceremony) {
      setState(() => _ceremony = match.first);
    }
    _calculate(toast: true);
  }

  /// Best upcoming date for each ceremony (web "Best ceremony dates for
  /// your Kundali" panel, rendered only while the advanced block is open).
  Widget _bestDatesPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3D9AE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Best ceremony dates for your Kundali',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Ranked using your saved Janma Nakshatra and Moon sign, with upcoming Panchanga dates for the selected ceremony location. Updates when you recalculate.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          ..._matches.map((m) => _matchCard(context, m)),
        ],
      ),
    );
  }

  Widget _matchCard(BuildContext context, Map<String, dynamic> m) {
    final name = m['ceremony_name']?.toString() ?? '';
    final date = (m['display_date']?.toString().isNotEmpty ?? false)
        ? m['display_date'].toString()
        : Fmt.date(m['date']?.toString());
    final window = m['best_time_window']?.toString() ?? '';
    final compat = m['compatibility']?.toString() ?? '';
    final score = m['score'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            date,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.accentHover,
            ),
          ),
          if (window.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              window,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  [if (compat.isNotEmpty) compat, if (score != null) '$score']
                      .join(' · '),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _calculating ? null : () => _moreDates(name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4338CA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'More dates',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          _header(context),
          if (_matches.isNotEmpty) ...[
            const SizedBox(height: 14),
            _bestDatesPanel(context),
          ],
          const SizedBox(height: 14),
          _ceremonyField(context),
          const SizedBox(height: 12),
          _locationField(context),
          const SizedBox(height: 14),
          AppButton(
            key: const ValueKey<String>('muhurtham-calculate'),
            label: _calculating
                ? context.tr('kundali.engine.analyzing')
                : context.tr('kundali.engine.findMuhurtham'),
            loading: _calculating,
            onPressed: _calculating ? null : () => _calculate(),
          ),
          if (_calculating) ...[
            const SizedBox(height: 14),
            _loadingPanel(context),
          ],
          if (_notice != null) ...[
            const SizedBox(height: 14),
            _noticeBox(context),
          ],
          if (_recs.isNotEmpty) ...[
            const SizedBox(height: 18),
            _resultsHeader(context),
            const SizedBox(height: 10),
            for (var i = 0; i < _recs.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _resultCard(context, _recs[i], i),
            ],
          ],
          if (_calendar != null) ...[
            const SizedBox(height: 18),
            AuspiciousCalendar(
              key: const ValueKey<String>('muhurtham-calendar'),
              calendar: _calendar,
              month: _month,
              months: _months,
              onMonthChanged: _onMonthChanged,
              selectedDay: _selectedDay,
              onTapDay: _onTapDay,
              onBookDay: _onBookDay,
              ceremonyName: _ceremony.name,
              location: _locationText,
            ),
          ],
          const SizedBox(height: 14),
          _disclaimerBox(context),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ form

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6E8), Color(0xFFFFE9CE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3D9AE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('kundali.engine.title'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('kundali.engine.subtitle'),
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                context.tr('kundali.engine.timezoneLabel'),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  context.tr('kundali.engine.timezoneValue'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    ),
  );

  Widget _selectBox(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );

  Widget _ceremonyField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, context.tr('kundali.engine.ceremonyLabel')),
        _selectBox(
          DropdownButton<MuhurthamCeremony>(
            key: const ValueKey<String>('muhurtham-ceremony'),
            value: _ceremony,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: Colors.white,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            items: [
              for (final c in kMuhurthamCeremonies)
                DropdownMenuItem<MuhurthamCeremony>(
                  value: c,
                  child: Text(
                    c.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textDark),
                  ),
                ),
            ],
            onChanged: (value) => setState(() {
              if (value != null) _ceremony = value;
            }),
          ),
        ),
      ],
    );
  }

  Widget _locationField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _label(
                context,
                _customLocation
                    ? context.tr('kundali.engine.customCity')
                    : context.tr('kundali.engine.locationLabel'),
              ),
            ),
            IconButton(
              key: const ValueKey<String>('muhurtham-location-toggle'),
              tooltip: _customLocation
                  ? context.tr('kundali.engine.chooseFromList')
                  : context.tr('kundali.engine.customCity'),
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() {
                _customLocation = !_customLocation;
                if (_customLocation) {
                  _customLocationCtrl.text = _location;
                } else {
                  final text = _customLocationCtrl.text.trim();
                  _location = kPopularLocations.contains(text)
                      ? text
                      : kPopularLocations.first;
                }
              }),
              icon: Icon(
                _customLocation ? Icons.list_alt : Icons.edit_location_alt,
                size: 19,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        _selectBox(
          _customLocation
              ? TextField(
                  key: const ValueKey<String>('muhurtham-custom-location'),
                  controller: _customLocationCtrl,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: context.tr('kundali.engine.customCityHint'),
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                )
              : DropdownButton<String>(
                  key: const ValueKey<String>('muhurtham-location'),
                  value: kPopularLocations.contains(_location)
                      ? _location
                      : null,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  hint: Text(context.tr('kundali.engine.chooseFromList')),
                  items: [
                    for (final l in kPopularLocations)
                      DropdownMenuItem<String>(
                        value: l,
                        child: Text(
                          l,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    if (value != null) _location = value;
                  }),
                ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- loading

  Widget _loadingPanel(BuildContext context) {
    final stages = <String>[
      context.tr('kundali.engine.stage1'),
      context.tr('kundali.engine.stage2'),
      context.tr('kundali.engine.stage3'),
      context.tr('kundali.engine.stage4'),
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
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('kundali.engine.loadingTitle'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('kundali.engine.loadingBody'),
            style: const TextStyle(
              fontSize: 11,
              height: 1.45,
              color: Color(0xFF9FB3BF),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < stages.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    _stage > i + 1
                        ? Icons.check_circle
                        : _stage == i + 1
                        ? Icons.pending
                        : Icons.radio_button_unchecked,
                    size: 15,
                    color: _stage > i + 1
                        ? AppColors.success
                        : _stage == i + 1
                        ? AppColors.accent
                        : const Color(0xFF49636F),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stages[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _stage > i
                          ? Colors.white
                          : const Color(0xFF7E939E),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _noticeBox(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF7E3B0)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          size: 18,
          color: AppColors.warning,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _notice!,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    ),
  );

  // -------------------------------------------------------------- results

  Widget _resultsHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr('kundali.results.title')} ${_ceremony.name}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            context.tr('kundali.results.ranked', {'count': _recs.length}),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.accentHover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(BuildContext context, String text, Color bg, Color fg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: fg,
          ),
        ),
      );

  Widget _resultCard(BuildContext context, Map<String, dynamic> item, int i) {
    final isBest = i == 0;
    final panchanga = item['panchanga'] is Map<String, dynamic>
        ? item['panchanga'] as Map<String, dynamic>
        : null;
    final reasons = item['reasons'] is List
        ? (item['reasons'] as List).map((e) => '$e').toList()
        : const <String>[];
    final compatibility = item['compatibility']?.toString() ?? '-';
    final score = item['score'];
    final bestWindow =
        (item['best_time_window']?.toString() ?? '').replaceAll('–', '-');
    final altWindow =
        (item['alternative_time_window']?.toString() ?? '').replaceAll('–', '-');
    final expanded = _expanded == i;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBest ? AppColors.gold : AppColors.border,
          width: isBest ? 1.6 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A021F2C),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              isBest
                  ? _badge(
                      context,
                      context.tr('kundali.results.best'),
                      AppColors.gold,
                      AppColors.primary,
                    )
                  : _badge(
                      context,
                      '#${i + 1}',
                      AppColors.cream,
                      AppColors.textMuted,
                    ),
              const Spacer(),
              _badge(
                context,
                '${context.tr('kundali.results.compatibility', {'value': compatibility})}'
                '${score != null ? '  $score%' : ''}',
                isBest ? const Color(0xFFECFDF5) : AppColors.cream,
                isBest ? AppColors.successDark : AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item['ceremony_full_title']?.toString() ??
                item['ceremony_name']?.toString() ??
                _ceremony.fullTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                (item['display_date']?.toString().isNotEmpty ?? false)
                    ? item['display_date'].toString()
                    : Fmt.date(item['date']?.toString()),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Fmt.inr(item['price'] ?? _ceremony.price),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _windowRow(
            context,
            label: context.tr('kundali.results.windowLabel'),
            value: context.tr('kundali.results.ist', {'value': bestWindow}),
            strong: true,
          ),
          if (altWindow.isNotEmpty)
            _windowRow(
              context,
              label: context.tr('kundali.results.alternative'),
              value: context.tr('kundali.results.ist', {'value': altWindow}),
              strong: false,
            ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              context.tr('kundali.results.factors'),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in reasons)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD6E6FB)),
                    ),
                    child: Text(
                      r,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (expanded) ...[
            const SizedBox(height: 12),
            Text(
              context.tr('kundali.results.why'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item['why_text']?.toString() ?? '',
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
            if (item['tarabala'] != null) ...[
              const SizedBox(height: 8),
              _kvRow(context, 'Tarabala', '${item['tarabala']}'),
            ],
            if (item['chandrabala'] != null)
              _kvRow(context, 'Chandrabala', '${item['chandrabala']}'),
            if (panchanga != null) ...[
              const SizedBox(height: 10),
              Text(
                context.tr('kundali.results.panchanga', {
                  'nakshatra': panchanga['nakshatra']?.toString() ?? '-',
                  'tithi': panchanga['tithi']?.toString() ?? '-',
                }),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              _panchangaGrid(context, panchanga),
            ],
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: ValueKey<String>('muhurtham-details-$i'),
                  onPressed: () => setState(() => _expanded = expanded ? null : i),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    expanded
                        ? context.tr('kundali.results.hideDetails')
                        : context.tr('kundali.results.viewDetails'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  key: ValueKey<String>('muhurtham-book-$i'),
                  label: context.tr('kundali.results.bookPooja'),
                  expand: false,
                  height: 42,
                  onPressed: () => _bookRecommendation(item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _windowRow(
    BuildContext context, {
    required String label,
    required String value,
    required bool strong,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: strong ? 13.5 : 12.5,
                fontWeight: FontWeight.w800,
                color: strong ? AppColors.accentHover : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvRow(BuildContext context, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 120,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ),
    ],
  );

  Widget _panchangaGrid(BuildContext context, Map<String, dynamic> p) {
    final entries = <MapEntry<String, String>>[
      MapEntry('Tithi', '${p['tithi'] ?? '-'}'),
      MapEntry('Nakshatra', '${p['nakshatra'] ?? '-'}'),
      MapEntry('Yoga', '${p['yoga'] ?? '-'}'),
      MapEntry('Karana', '${p['karana'] ?? '-'}'),
      MapEntry('Vara', '${p['vara'] ?? '-'}'),
      MapEntry('Sunrise', '${p['sunrise'] ?? '-'}'),
      MapEntry('Sunset', '${p['sunset'] ?? '-'}'),
      MapEntry('Rahu Kalam', '${p['rahu_kaal'] ?? '-'}'),
      MapEntry('Abhijit Muhurat', '${p['abhijit_muhurat'] ?? '-'}'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _panchangaCell(entries[i])),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < entries.length
                        ? _panchangaCell(entries[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _panchangaCell(MapEntry<String, String> e) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        e.key,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.4,
        ),
      ),
      Text(
        e.value,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    ],
  );

  Widget _disclaimerBox(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F9FA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.gavel_outlined, size: 15, color: AppColors.info),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.tr('kundali.disclaimer.title'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          (_disclaimer?.isNotEmpty ?? false)
              ? _disclaimer!
              : context.tr('kundali.disclaimer.body'),
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    ),
  );

  // ------------------------------------------------------------- actions

  Future<void> _calculate({bool toast = true}) async {
    if (!widget.birth.isComplete) {
      showAppToast(
        context,
        context.tr('kundali.engine.missingBirth'),
        type: ToastType.warning,
        title: 'Muhurtham',
      );
      return;
    }
    final target = _month;
    if (!mounted) return;
    setState(() {
      _calculating = true;
      _stage = 1;
      _notice = null;
    });
    // Web resolves the ceremony city through lookupCityCoords before calling
    // the engine; the geo-lookup endpoint mirrors it, so the payload can
    // carry the same ceremonyLatitude/ceremonyLongitude the backend reads.
    // Fired alongside the stage animation to hide the extra round-trip.
    final parts = kSplitLocation(_locationText);
    final geoFuture = _service.geoLookup(
      city: parts.city,
      state: parts.state.isEmpty ? null : parts.state,
      place: _locationText,
    );
    for (var s = 2; s <= 4; s++) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() => _stage = s);
    }
    final geo = await geoFuture;
    if (!mounted) return;
    // Web parity guard: only send ceremony coordinates when the lookup
    // genuinely resolved the chosen city (not the Vijayawada default),
    // otherwise the backend resolves the location itself.
    final resolvedCity = geo?.city?.trim() ?? '';
    final isResolved = geo != null &&
        geo.latitude != null &&
        geo.longitude != null &&
        resolvedCity.isNotEmpty &&
        (geo.latitude != 16.5062 ||
            geo.longitude != 80.648 ||
            _locationText.toLowerCase().contains('vijayawada')) &&
        _locationText.toLowerCase().contains(resolvedCity.toLowerCase());
    final resolved = isResolved ? geo : null;

    final payload = <String, dynamic>{
      'full_name': widget.birth.fullName ?? 'Devotee',
      'dateOfBirth': widget.birth.dateOfBirth,
      'timeOfBirth': widget.birth.timeOfBirth,
      'birthPlace': widget.birth.placeOfBirth,
      'birthLatitude': widget.birth.latitude,
      'birthLongitude': widget.birth.longitude,
      'birthTimezone': widget.birth.timezone,
      'ceremonyType': _ceremony.name,
      'ceremonyLocation': _locationText,
      if (resolved != null) 'ceremonyLatitude': resolved.latitude,
      if (resolved != null) 'ceremonyLongitude': resolved.longitude,
      'year': target.year,
      'month': target.month,
    };
    final res = await _service.calculateMuhurtham(payload);
    if (!mounted) return;

    if (res != null && res.success) {
      setState(() {
        _calculating = false;
        _recs = res.recommendations;
        _matches = res.ceremonyRecommendations;
        _calendar = res.calendar;
        _disclaimer = res.disclaimer;
        _selectedDay = null;
        _expanded = _recs.isEmpty ? null : 0;
      });
      if (toast) {
        showAppToast(
          context,
          context.tr('kundali.toast.found', {'ceremony': _ceremony.name}),
          type: ToastType.success,
          title: 'Muhurtham',
        );
      }
    } else {
      setState(() {
        _calculating = false;
        _notice = context.tr('kundali.toast.failed');
      });
      if (toast) {
        showAppToast(
          context,
          context.tr('kundali.toast.failed'),
          type: ToastType.info,
          title: 'Muhurtham',
        );
      }
    }
  }

  Future<void> _onMonthChanged(DateTime m) async {
    final hasResults = _calendar != null || _recs.isNotEmpty;
    setState(() {
      _month = m;
      _selectedDay = null;
    });
    if (hasResults) {
      await _calculate(toast: false);
    }
  }

  bool _isPast(Map<String, dynamic> day) =>
      day['is_past'] == true || day['status']?.toString() == 'past';

  void _onTapDay(Map<String, dynamic> day) {
    if (_isPast(day)) {
      showAppToast(
        context,
        context.tr('kundali.calendar.pastToast'),
        type: ToastType.warning,
        title: 'Calendar',
      );
      return;
    }
    setState(() => _selectedDay = day);
  }

  void _onBookDay(Map<String, dynamic> day) {
    if (_isPast(day)) {
      showAppToast(
        context,
        context.tr('kundali.calendar.pastToast'),
        type: ToastType.warning,
        title: 'Calendar',
      );
      return;
    }
    widget.onBook(
      ceremony: _ceremony,
      date: day['date']?.toString() ?? '',
      timeSlot: _slotLabel(day['available_muhurtham']?.toString()),
      location: _locationText,
    );
  }

  void _bookRecommendation(Map<String, dynamic> item) {
    widget.onBook(
      ceremony: _ceremony,
      date: item['date']?.toString() ?? '',
      timeSlot: _slotLabel(item['best_time_window']?.toString()),
      location: item['location']?.toString() ?? _locationText,
    );
  }

  String _slotLabel(String? window) {
    final cleaned = (window ?? '').replaceAll('–', '-').trim();
    final time = cleaned.isEmpty ? '06:00 AM - 09:00 AM' : cleaned;
    return '${_ceremony.name} Shubha Muhurtham ($time)';
  }
}
