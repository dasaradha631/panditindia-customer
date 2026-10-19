import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/catalogue_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/kundli_service.dart';
import '../booking/booking_flow_screen.dart';
import 'birth_details_modal.dart';
import 'kundali_data.dart';
import 'muhurtham_section.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class KundaliScreen extends StatefulWidget {
  const KundaliScreen({super.key});

  @override
  State<KundaliScreen> createState() => _KundaliScreenState();
}

class _KundaliScreenState extends State<KundaliScreen> {
  final KundliService _service = KundliService();
  KundliResult? _result;
  bool _loading = true;
  // The web dashboard starts with the advanced block collapsed
  // (PersonalizedKundliMuhurthamSection `showAdvancedKundli = false`);
  // the toggle button reveals navagraha, transits and the Muhurtham engine.
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    KundliResult? result;
    try {
      final profile = context.read<ProfileProvider>().profile;
      result = await _service.getMyKundli(
        dob: profile?.dateOfBirth,
        tob: profile?.timeOfBirth,
        place: profile?.placeOfBirth ?? profile?.city,
        lat: profile?.latitude,
        lon: profile?.longitude,
        tz: profile?.timezone,
        name: profile?.fullName,
      );
    } catch (_) {
      result = null;
    }
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  String _str(Map<String, dynamic> k, String key, [String fallback = '-']) {
    final v = k[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty || s == '?' || s == '—' ? fallback : s;
  }

  /// Mirrors the web `formatDate` hub: `01/June/1995`.
  /// Accepts ISO (`1995-06-01`), `DD-MM-YYYY` and `DD/MM/YYYY`.
  String _formatDisplayDate(String raw) => Fmt.date(raw);

  /// Mirrors the web `formatTimeOfBirth`: strips seconds and keeps an
  /// explicit AM/PM (`22:30` → `10:30 PM`, `10:30:15 AM` → `10:30 AM`).
  String _formatDisplayTime(String raw) {
    final v = raw.trim();
    if (v.isEmpty || v == '-') return raw;
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$', caseSensitive: false)
            .firstMatch(v);
    if (match == null) return v;
    var hour = int.parse(match[1]!);
    final minute = match[2]!;
    var period = match[3]?.toUpperCase();
    if (period == null) {
      period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
    }
    return '$hour:$minute $period';
  }

  /// Birth place shown in the header / coordinates card, mirroring the web
  /// fallbacks: kundli payload → profile → `city, state` → `Birth Place`.
  String _placeDisplay(Map<String, dynamic> k) {
    final fromK = _str(k, 'place_of_birth', '');
    if (fromK.isNotEmpty && fromK != '-') return fromK;
    final p = context.read<ProfileProvider>().profile;
    final place = p?.placeOfBirth?.trim();
    if (place != null && place.isNotEmpty) return place;
    final city = p?.city?.trim();
    if (city != null && city.isNotEmpty) {
      final state = p?.state?.trim();
      return (state == null || state.isEmpty) ? city : '$city, $state';
    }
    return 'Birth Place';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: GradientAppBar(title: 'Kundali & Horoscope'),
      body: _loading
          ? const LoadingView(label: 'Computing your Janam Kundali...')
          : _buildResult(),
    );
  }

  /// Birth data for the Muhurtham engine: the saved profile wins (it is what
  /// the birth modal edits), falling back to the computed kundli payload.
  KundaliBirthDetails _birthFrom(Map<String, dynamic> k) {
    final p = context.read<ProfileProvider>().profile;
    String? pick(String? profileValue, String kundliKey) {
      final pv = profileValue?.trim();
      if (pv != null && pv.isNotEmpty) return pv;
      final kv = k[kundliKey]?.toString().trim();
      return (kv == null || kv.isEmpty) ? null : kv;
    }

    return KundaliBirthDetails(
      fullName: pick(p?.fullName, 'full_name'),
      dateOfBirth: pick(p?.dateOfBirth, 'date_of_birth'),
      timeOfBirth: pick(p?.timeOfBirth, 'time_of_birth'),
      placeOfBirth: pick(p?.placeOfBirth, 'place_of_birth'),
      city: pick(p?.city, 'city'),
      state: pick(p?.state, 'state'),
      latitude: pick(p?.latitude, 'latitude'),
      longitude: pick(p?.longitude, 'longitude'),
      timezone: pick(p?.timezone, 'timezone'),
    );
  }

  Future<void> _openBirthModal() async {
    final profile = context.read<ProfileProvider>().profile;
    await showBirthDetailsModal(
      context,
      profile: profile,
      onSaved: () {
        _load();
        if (mounted) setState(() {});
      },
    );
  }

  /// Seeds booking step 2 from a Muhurtham recommendation (ceremony, date,
  /// shubha muhurtham window and ceremony location).
  void _bookMuhurtham({
    required MuhurthamCeremony ceremony,
    required String date,
    required String timeSlot,
    required String location,
  }) {
    final bookings = context.read<BookingProvider>();
    final profile = context.read<ProfileProvider>();
    final auth = context.read<AuthProvider>();
    final parts = kSplitLocation(location);

    bookings.resetDraft(
      devoteeName: profile.profile?.fullName ?? auth.session?.name,
      mobile: profile.profile?.phonenumber ?? auth.session?.phone,
      email: profile.profile?.email ?? auth.session?.email,
      address: profile.profile?.address,
      city: parts.city,
      state: parts.state,
    );
    final base = CeremonyCatalogue.ceremonies.firstWhere(
      (c) => c.id == ceremony.catalogueId,
      orElse: () => CeremonyCatalogue.ceremonies.first,
    );
    bookings.selectCeremony(base);
    // Keep the catalogue ceremony price chosen by `selectCeremony`; the
    // muhurtham-catalogue listing price must not leak into the booking draft
    // (web re-selects the catalogue ceremony and discards it).
    bookings.updateDraft((d) {
      d.ceremonyName = ceremony.fullTitle;
      d.date = date;
      d.timeSlot = timeSlot;
      d.cityText = parts.city;
      d.stateText = parts.state;
    });
    bookings.setStep(2);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BookingFlowScreen()),
    );
  }

  Widget _buildResult() {
    final result = _result;
    final k = result?.kundli;
    // Never fabricate a chart: on API failure or an incomplete payload,
    // mirror the web dashboard with an error banner (birth details saved)
    // or an incomplete-birth CTA card instead of fake data.
    if (result == null || k == null || k['is_complete'] != true) {
      final profile = context.read<ProfileProvider>().profile;
      final hasBirth = KundaliBirthDetails.fromProfile(profile).isComplete;
      return RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (hasBirth) ...[
              _buildErrorBanner(),
              const SizedBox(height: 10),
              _buildEditBirthButton(),
            ] else ...[
              _buildIncompleteBanner(),
              const SizedBox(height: 12),
              _buildRetryButton(),
            ],
          ],
        ),
      );
    }
    final transits =
        result.transits.whereType<Map<String, dynamic>>().toList();
    final birth = _birthFrom(k);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _buildHeader(k),
          const SizedBox(height: 14),
          _buildTrioCards(k),
          const SizedBox(height: 14),
          _buildDashaCard(k),
          const SizedBox(height: 14),
          _buildCoordinatesCard(k),
          const SizedBox(height: 14),
          if (!birth.isComplete) ...[
            _buildIncompleteBanner(),
            const SizedBox(height: 12),
          ],
          _buildEditBirthButton(),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showAdvanced
                          ? 'Hide Advanced Astrological Details'
                          : 'View Advanced Astrological Details & Transits',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _showAdvanced
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showAdvanced) ...[
            const SizedBox(height: 14),
            _buildPlanetaryPositions(
              k,
              (k['planetary_positions'] as List? ?? const [])
                  .whereType<Map<String, dynamic>>()
                  .toList(),
            ),
            if (transits.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildTransits(transits),
            ],
            const SizedBox(height: 14),
            MuhurthamSection(
              key: const ValueKey<String>('kundali-muhurtham'),
              birth: birth,
              onBook: _bookMuhurtham,
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showAppToast(
                context,
                'Connecting to Senior Vedic Astrologer desk...',
                type: ToastType.info,
                title: 'Jyotish',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.call_rounded, size: 18),
              label: const Text(
                'Speak to Senior Jyotish Astrologer',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Web-style failure state (`PersonalizedKundliMuhurthamSection` kundliError
  /// banner): birth details are saved but the astrology service did not
  /// return a chart — offer a retry instead of fabricating one.
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5B8B8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: AppColors.danger,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Accurate Kundali data is unavailable right now. Please try again after the astrology service is available.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRetryButton(),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        key: const ValueKey<String>('kundali-retry'),
        onPressed: _load,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Retry',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildEditBirthButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const ValueKey<String>('kundali-update-birth'),
        onPressed: _openBirthModal,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.edit_calendar_outlined, size: 17),
        label: Text(
          context.tr('kundali.birth.open'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildIncompleteBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6E8), Color(0xFFFFEBD1)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3D9AE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: AppColors.accentHover,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  context.tr('kundali.birth.incompleteTitle'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            context.tr('kundali.birth.incompleteBody'),
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey<String>('kundali-incomplete-cta'),
              onPressed: _openBirthModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                context.tr('kundali.birth.incompleteCta'),
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

  Widget _buildHeader(Map<String, dynamic> k) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF021824), Color(0xFF09243C)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.brightness_5_rounded,
                  color: AppColors.gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VEDIC BIRTH CHART',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_str(k, 'full_name', 'Devotee')} (Janam Kundali)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'DOB: ${_formatDisplayDate(_str(k, 'date_of_birth', ''))}'
                      ' • TOB: ${_formatDisplayTime(_str(k, 'time_of_birth', ''))}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '📍 ${_placeDisplay(k)}',
                      style: TextStyle(
                        color: AppColors.gold.withValues(alpha: 0.9),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildTrioCards(Map<String, dynamic> k) {
    return Row(
      children: [
        Expanded(
          child: _trioCard(
            'RASHI (MOON)',
            _str(k, 'rashi'),
            [
              _str(k, 'rashi_sanskrit', ''),
              if (_str(k, 'rashi_degree_formatted', '') != '-')
                _str(k, 'rashi_degree_formatted'),
            ].where((s) => s.isNotEmpty && s != '-').join(' • '),
            const Color(0xFF22D3EE),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _trioCard(
            'NAKSHATRA & PADA',
            _str(k, 'nakshatra'),
            'Pada ${k['pada'] ?? 1} • ${_str(k, 'nakshatra_lord', '')}',
            const Color(0xFF34D399),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _trioCard(
            'LAGNA (ASCENDANT)',
            _str(k, 'lagna'),
            [
              _str(k, 'lagna_sanskrit', ''),
              if (_str(k, 'lagna_degree_formatted', '') != '-')
                _str(k, 'lagna_degree_formatted'),
            ].where((s) => s.isNotEmpty && s != '-').join(' • '),
            const Color(0xFFA78BFA),
          ),
        ),
      ],
    );
  }

  Widget _trioCard(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          if (sub.isNotEmpty && sub != '-') ...[
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDashaCard(Map<String, dynamic> k) {
    final dasha = k['dasha_details'] is Map
        ? Map<String, dynamic>.from(k['dasha_details'] as Map)
        : const <String, dynamic>{};
    final progress = (dasha['progress_percentage'] as num?)?.toDouble() ?? 50.0;
    final startYear =
        (dasha['starts_year'] ?? dasha['startsYear'])?.toString() ?? '2019';
    final endYear =
        (dasha['ends_year'] ?? dasha['endsYear'])?.toString() ?? '2036';

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
          Row(
            children: [
              const Icon(
                Icons.timelapse_rounded,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'CURRENT ACTIVE DASHA (2026)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '$startYear – $endYear',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mahadasha:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _str(k, 'mahadasha'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Antardasha:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _str(k, 'antardasha'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatesCard(Map<String, dynamic> k) {
    final p = context.read<ProfileProvider>().profile;
    final lat = (k['latitude'] as num?) ?? double.tryParse(p?.latitude ?? '');
    final lon = (k['longitude'] as num?) ?? double.tryParse(p?.longitude ?? '');
    final tz = _str(k, 'timezone', '') != '-'
        ? _str(k, 'timezone')
        : (p?.timezone?.trim().isNotEmpty ?? false)
            ? p!.timezone!
            : 'Asia/Kolkata';
    String coord(num? value, String positive, String negative) {
      if (value == null) return '-';
      final dir = value < 0 ? negative : positive;
      return '${value.abs()}° $dir';
    }

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
          Row(
            children: const [
              Expanded(
                child: Text(
                  'BIRTH COORDINATES & TIMEZONE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Place:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      _placeDisplay(k),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Timezone:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      tz,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lat:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      coord(lat, 'N', 'S'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lon:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      coord(lon, 'E', 'W'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
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

  Widget _buildPlanetaryPositions(
    Map<String, dynamic> k,
    List<Map<String, dynamic>> planets,
  ) {
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'PLANETARY POSITIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (_str(k, 'ayanamsha_deg', '') != '-' &&
                  _str(k, 'ayanamsha_deg', '').isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Ayanamsha: ${_str(k, 'ayanamsha_deg')}° (Lahiri)',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...planets.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _str(p, 'planet').split(' ').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (_str(p, 'rashi', '') != '-' &&
                            _str(p, 'rashi', '').isNotEmpty)
                          Text(
                            _str(p, 'rashi').split(' ').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      _str(p, 'degree_formatted') != '-'
                          ? _str(p, 'degree_formatted')
                          : p['deg'] is num
                              ? '${(p['deg'] as num).toStringAsFixed(1)}°'
                              : '-',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _str(p, 'nature'),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
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

  Widget _buildTransits(List<Map<String, dynamic>> transits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PERSONALIZED 2026 TRANSITS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        ...transits.map((t) => _transitCard(t)),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: const Text(
            'These are current planetary-position snapshots, not future transit forecasts. '
            'Muhurtham dates are app-generated estimates and are not verified against TTD Panchangam data.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _transitCard(Map<String, dynamic> t) {
    final recommended = (t['recommended_ceremonies'] as List? ?? const [])
        .map(
          (e) => e is Map
              ? (e['name'] ?? e['title'] ?? '').toString()
              : e.toString(),
        )
        .where((s) => s.isNotEmpty && s != 'null')
        .toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _str(t, 'planet'),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Flexible(
                child: StatusBadge(
                  label: _str(t, 'impact_level', 'Transit'),
                  color: AppColors.gold,
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InfoRow(
            label: 'Enters',
            value: _str(t, 'transit_sign'),
            icon: Icons.swap_horiz,
          ),
          InfoRow(
            label: 'Date',
            value: _str(t, 'transit_date'),
            icon: Icons.calendar_today_outlined,
          ),
          InfoRow(
            label: 'Duration',
            value: _str(t, 'duration'),
            icon: Icons.timelapse,
          ),
          if (_str(t, 'interpretation') != '-') ...[
            const SizedBox(height: 8),
            Text(
              _str(t, 'interpretation'),
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.55,
              ),
            ),
          ],
          if (recommended.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: recommended
                  .map(
                    (c) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentHover,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
