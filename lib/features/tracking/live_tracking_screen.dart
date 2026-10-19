import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/contact_actions.dart';
import '../../core/utils/receipt_pdf.dart';
import '../../core/widgets/common.dart';
import '../../models/booking.dart';
import '../../models/tracking.dart';
import '../../providers/booking_provider.dart';
import '../../services/booking_service.dart';
import '../../services/tracking_service.dart';
import '../pujas/puja_catalogue_screen.dart';
import '../reviews/review_sheet.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({
    super.key,
    required this.bookingId,
    this.panditName,
    this.customerAddress,
    this.booking,
  });

  final dynamic bookingId;
  final String? panditName;
  final String? customerAddress;
  final Booking? booking;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _StageData {
  const _StageData(this.title, this.desc);

  final String title;
  final String desc;
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  static const LatLng _fallbackCenter = LatLng(17.3850, 78.4867);

  // Web dashboard palette (Tailwind values from UserDashboardPage.jsx).
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate600 = Color(0xFF475569);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate300 = Color(0xFFCBD5E1);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _slate50 = Color(0xFFF8FAFC);
  static const Color _amber50 = Color(0xFFFFFBEB);
  static const Color _amber100 = Color(0xFFFEF3C7);
  static const Color _amber200 = Color(0xFFFDE68A);
  static const Color _amber300 = Color(0xFFFCD34D);
  static const Color _amber400 = Color(0xFFFBBF24);
  static const Color _amber900 = Color(0xFF78350F);
  static const Color _emerald50 = Color(0xFFECFDF5);
  static const Color _emerald300 = Color(0xFF6EE7B7);
  static const Color _emerald600 = Color(0xFF059669);
  static const Color _emerald700 = Color(0xFF047857);
  static const Color _emerald800 = Color(0xFF065F46);
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose700 = Color(0xFFBE123C);
  static const Color _blue50 = Color(0xFFEFF6FF);
  static const Color _blue200 = Color(0xFFBFDBFE);
  static const Color _blue600 = Color(0xFF2563EB);
  static const Color _blue800 = Color(0xFF1E40AF);
  static const Color _darkBg = Color(0xFF021824);
  static const Color _bannerMid = Color(0xFF1A0A00);
  static const Color _teal600 = Color(0xFF0D9488);

  static const List<_StageData> _stages = [
    _StageData('Booking Confirmed', 'Sankalpa locked & verified'),
    _StageData('Samagri Kit Dispatched', 'Organic herbs sealed'),
    _StageData('Pandit Assigned', 'Veda Murthy appointed'),
    _StageData('Journey Started + Live GPS', 'Acharya en route to mandap'),
    _StageData('Mandap Sthapana in Progress', 'Kalash & Agni invoked'),
    _StageData('Agni Hotra & Havan in Progress', '108 Ahutis underway'),
    _StageData('Purna Ahuti & Aarti in Progress', 'Maha Aarti blessed'),
    _StageData('Ceremony Completed', 'Prasad & 80G receipt'),
  ];

  final TrackingService _service = TrackingService();
  final BookingService _bookingService = BookingService();
  final MapController _mapController = MapController();

  Timer? _timer;
  int _pollTick = 0;
  LiveLocation? _data;
  Booking? _booking;
  bool _loading = true;
  bool _failed = false;
  bool _mapReady = false;
  LatLng? _lastCentered;
  bool _updatingPin = false;
  String? _pinAddress;
  double? _pinLat;
  double? _pinLon;

  /// Road route between the pandit and the mandap (web `useLiveGps.js`
  /// parity — OSRM geometry drawn as an orange polyline, with a dashed
  /// straight-line fallback while the fetch is in flight or offline).
  List<LatLng>? _routePoints;
  String? _routeKey;

  /// Booking being tracked — starts as [widget.bookingId] and moves to the
  /// booking picked in the header switcher.
  late dynamic _bookingId;

  /// Set once the user picks another booking. The constructor passthroughs
  /// ([widget.panditName] / [widget.customerAddress]) then describe a stale
  /// booking, so they are ignored in favour of `[_booking]`.
  bool _switched = false;

  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    _booking = widget.booking;
    if (_booking == null) _loadBooking();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<BookingProvider>();
      if (p.myBookings.isEmpty && !p.loadingBookings) p.loadMyBookings();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Constructor passthroughs describing the booking we were opened for.
  String? get _passedPanditName => _switched ? null : widget.panditName;

  String? get _passedAddress => _switched ? null : widget.customerAddress;

  Future<void> _loadBooking({bool force = false}) async {
    final id = _bookingId;
    if (id == null) return;
    final b = await _bookingService.getBooking(id);
    if (!mounted || b == null) return;
    if (Booking.normalizeIdString(id) !=
        Booking.normalizeIdString(_bookingId)) {
      return; // the user switched bookings while this request was in flight
    }
    if (force || _booking == null) setState(() => _booking = b);
  }

  Future<void> _load() async {
    _pollTick++;
    final id = _bookingId;
    final data = await _service.getLiveLocation(id);
    if (!mounted) return;
    if (Booking.normalizeIdString(id) !=
        Booking.normalizeIdString(_bookingId)) {
      return; // stale response from the previously tracked booking
    }
    setState(() {
      _loading = false;
      if (data != null) {
        _data = data;
        _failed = false;
      } else {
        _failed = _data == null;
      }
    });
    _recenterIfNeeded();
    _syncRoute();
    // Stage jumps land on the booking row (PATCH /status) while GPS ticks land
    // on the live row — refresh the booking snapshot every second cycle like
    // the web dashboard's 20 s booking poll so the banner, Acharya card and
    // 8-stage grid follow every update the pandit app makes.
    if (_pollTick % 2 == 0) _loadBooking(force: true);
  }

  /// Header dropdown handler — resolves the selected option back to its
  /// [Booking] and re-arms tracking for that booking.
  void _switchTo(String normalizedId) {
    Booking? match;
    for (final b in context.read<BookingProvider>().myBookings) {
      if (Booking.normalizeIdString(b.bookingId) == normalizedId) {
        match = b;
        break;
      }
    }
    final next = match;
    final id = next?.bookingId;
    if (next == null || id == null) return;
    if (Booking.normalizeIdString(id) ==
        Booking.normalizeIdString(_bookingId)) {
      return;
    }
    _timer?.cancel();
    setState(() {
      _switched = true;
      _bookingId = id;
      _booking = next;
      _data = null;
      _loading = true;
      _failed = false;
      _lastCentered = null;
      _updatingPin = false;
      _pinAddress = null;
      _pinLat = null;
      _pinLon = null;
      _routePoints = null;
      _routeKey = null;
    });
    _loadBooking(force: true);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  void _recenterIfNeeded() {
    if (!_mapReady) return;
    final target = _target();
    if (target == null) return;
    final last = _lastCentered;
    if (last != null &&
        const Distance().as(LengthUnit.Meter, last, target) < 150) {
      return;
    }
    _lastCentered = target;
    final zoom = _panditTarget() != null ? 15.0 : 12.0;
    _mapController.move(target, zoom);
  }

  /// Keeps the drawn route in sync with the current trip (web parity with
  /// the pandit app's `_syncRoute` / `useLiveGps.js`). Refetches only when
  /// the trip changed or the pandit origin moved about a kilometre.
  void _syncRoute() {
    if (!mounted) return;
    final pandit = _panditTarget();
    final mandap = _mandapTarget();
    if (pandit == null || mandap == null) {
      if (_routePoints != null || _routeKey != null) {
        setState(() {
          _routePoints = null;
          _routeKey = null;
        });
      }
      return;
    }
    final key = '${pandit.latitude.toStringAsFixed(2)},'
        '${pandit.longitude.toStringAsFixed(2)}|'
        '${mandap.latitude.toStringAsFixed(3)},'
        '${mandap.longitude.toStringAsFixed(3)}';
    if (key == _routeKey) return;
    _routeKey = key;
    _fetchRoute(pandit, mandap);
  }

  /// `https://router.project-osrm.org/route/v1/bike/…` — the same endpoint
  /// and profile the web dashboard (and the pandit nav screen) use to
  /// render the turn-by-turn route line between pandit and mandap.
  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/bike/'
      '${from.longitude},${from.latitude};'
      '${to.longitude},${to.latitude}?overview=full&geometries=geojson',
    );
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (!mounted || res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      final routes = body is Map<String, dynamic> ? body['routes'] : null;
      if (routes is! List || routes.isEmpty) return;
      final geometry = routes.first is Map<String, dynamic>
          ? routes.first['geometry']
          : null;
      final coords = geometry is Map<String, dynamic>
          ? geometry['coordinates']
          : null;
      if (coords is! List) return;
      final points = <LatLng>[
        for (final c in coords)
          if (c is List && c.length >= 2 && c[0] is num && c[1] is num)
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
      if (points.length < 2 || !mounted) return;
      setState(() => _routePoints = points);
    } catch (_) {
      // Offline or OSRM unreachable → keep the dashed straight-line
      // fallback, exactly like the web dashboard's catch branch.
    }
  }

  /// Sentinel names the backend returns when no Acharya is attached to the
  /// booking yet — never treat them as a real assignment (spec Step 1: no
  /// pandit details or live tracking before a pandit is assigned).
  static const Set<String> _noPanditNames = {'unassigned', 'none', 'pending', 'null'};

  static bool _isNamedPandit(String? name) {
    final v = (name ?? '').trim().toLowerCase();
    return v.isNotEmpty && !_noPanditNames.contains(v);
  }

  /// Maps any raw status string onto the 0-based 8-stage grid index.
  /// Returns -1 for cancelled and -2 when the string carries no signal.
  int _stageOf(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s.contains('cancel')) return -1;
    if (s.contains('complete')) return 7;
    if (s.contains('aarti') || s.contains('purna')) return 6;
    if (s.contains('progress') || s.contains('live')) return 5;
    if (s.contains('arrived')) return 4;
    if (s.contains('route') || s.contains('transit')) return 3;
    if (s.contains('dispatch') || s.contains('ship') || s.contains('samagri')) {
      return 1;
    }
    if (s.contains('accept')) return 2;
    return -2;
  }

  /// Furthest-along status between the live stream and the booking snapshot —
  /// PATCH /status stage jumps land on the booking row while GPS ticks land on
  /// the live row, so the display follows whichever is ahead and never
  /// regresses (web `rawStatus || status` parity, plus monotone staging).
  String get _rawSt {
    final live = (_data?.trackingStatus ?? '').trim();
    final book = (_booking?.rawStatus ?? _booking?.status ?? '').trim();
    final li = _stageOf(live);
    final bi = _stageOf(book);
    final chosen = (bi > li) ? book : (live.isNotEmpty ? live : book);
    return chosen.toLowerCase();
  }

  bool get _isCompleted => _rawSt.contains('complete');

  String _numericPin() {
    final digits = (_booking?.bookingId?.toString() ?? '')
        .replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? '8842' : digits;
  }

  String _lastFourPin() {
    final pin = _numericPin();
    return pin.length <= 4 ? pin.padLeft(4, '0') : pin.substring(pin.length - 4);
  }

  String _acharyaName() {
    final live = (_data?.panditName ?? '').trim();
    if (_isNamedPandit(live)) return live;
    final passed = (_passedPanditName ?? '').trim();
    if (_isNamedPandit(passed)) return passed;
    final assigned = (_booking?.assignedPandit ?? '').trim();
    return _isNamedPandit(assigned) ? assigned : 'Acharya';
  }

  String? _acharyaPhone() {
    final pandit = (_booking?.panditPhone ?? '').trim();
    if (pandit.isNotEmpty) return pandit;
    final mobile = (_booking?.mobile ?? '').trim();
    if (mobile.isNotEmpty) return mobile;
    return null;
  }

  /// Pin source, two tiers (web parity: the dashboard map opens the moment
  /// the Acharya is assigned, then follows actual movement once streaming):
  /// (a) a fresh live fix — the pin tracks the travelling pandit;
  /// (b) assigned but not streaming — the live-row coords (last known) or
  /// the booking's enriched pandit coordinates (base/profile position).
  /// Pre-assignment callers are blocked by [_hasPandit] (spec Step 1).
  LatLng? _panditTarget() {
    final c = _panditCoords();
    return c == null ? null : LatLng(c.$2, c.$3);
  }

  bool get _liveStreamActive => (_data?.isTracking ?? false) && !_isStale();

  LatLng? _mandapTarget() {
    if (_pinLat != null && _pinLon != null) {
      return LatLng(_pinLat!, _pinLon!);
    }
    final d = _data;
    if (d != null && d.hasCustomerCoords) {
      return LatLng(d.customerLat!, d.customerLon!);
    }
    return null;
  }

  LatLng? _target() => _panditTarget() ?? _mandapTarget();

  (bool, double, double)? _panditCoords() {
    final d = _data;
    // (a) Live stream healthy — first boolean marks a genuinely live fix.
    if (d != null && d.hasPanditCoords && d.isTracking && !_isStale()) {
      return (true, d.latitude!, d.longitude!);
    }
    if (!_hasPandit()) return null;
    // (b) Assigned, not streaming — last known row coords beat the static
    // booking enrichment; either way the map still shows the pandit.
    if (d != null && d.hasPanditCoords) {
      return (false, d.latitude!, d.longitude!);
    }
    final b = _booking;
    if (b != null && b.panditLatitude != null && b.panditLongitude != null) {
      return (false, b.panditLatitude!, b.panditLongitude!);
    }
    return null;
  }

  double? _distKm() => _data?.distanceKm ?? _booking?.distanceKm;

  int? _etaMins() => _data?.etaMinutes ?? _booking?.etaMinutes;

  double? _speedKmph() {
    final s = _data?.speed;
    if (s != null) {
      // The live row stores m/s (phone GPS `Position.speed`), but the
      // "not started" fallback response substitutes the enriched booking's
      // pre-formatted km/h value when the DB speed is null. Road transit
      // never exceeds ~40 m/s (144 km/h), so anything larger is already
      // km/h and must not be multiplied by 3.6 again.
      return s > 40 ? s : s * 3.6;
    }
    return _booking?.speedKmph;
  }

  /// Age of the latest fix in seconds, or null when missing/unparseable.
  ///
  /// Backend timestamps may arrive naive (MySQL `updated_at`, Python
  /// `utcnow()`) while the phone clock is device-local (or vice-versa).
  /// A naive string is therefore read both ways and the interpretation
  /// closest to now wins, so a UTC↔IST skew can never fake-stale a real
  /// stream (or fake-fresh an abandoned one). Zone-aware strings (Z /
  /// ±HH:MM) are trusted as-is.
  int? _ageSeconds() {
    final ts = (_data?.timestamp ?? '').trim();
    if (ts.isEmpty) return null;
    final parsed = DateTime.tryParse(ts);
    if (parsed == null) return null;
    final now = DateTime.now();
    final hasZone =
        ts.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(ts);
    if (hasZone) {
      return now.toUtc().difference(parsed.toUtc()).inSeconds;
    }
    final asLocal = now.difference(parsed).inSeconds;
    final asUtc = now
        .toUtc()
        .difference(
          DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
          ),
        )
        .inSeconds;
    return asLocal.abs() <= asUtc.abs() ? asLocal : asUtc;
  }

  /// A missing or unparseable timestamp counts as stale, and so does any
  /// reading further than 45 s from now in either direction. Staleness only
  /// drives the pill / follow-live choice — it never hides the pin.
  bool _isStale() {
    final age = _ageSeconds();
    return age == null || age.abs() > 45;
  }

  String _statusText() {
    final rawSt = _rawSt;
    if (rawSt.isEmpty) return 'Fetching live location...';
    if (rawSt.contains('cancel')) return 'Ceremony cancelled';
    if (rawSt.contains('complete')) return 'Ceremony completed';
    if (rawSt.contains('not_started')) return 'Journey not started yet';
    if (rawSt.contains('aarti') ||
        rawSt.contains('progress') ||
        rawSt.contains('live')) {
      return 'Ceremony in progress';
    }
    if (rawSt.contains('arrived')) return 'Reached Mandap';
    if (rawSt.contains('route') || rawSt.contains('transit')) {
      return 'Acharya is on the way';
    }
    if (rawSt.contains('dispatch') || rawSt.contains('ship')) {
      return 'Samagri kit dispatched';
    }
    if (rawSt.contains('accept')) return 'Acharya assigned — awaiting journey';
    if (rawSt.contains('pending')) return 'Awaiting pandit acceptance';
    if (rawSt.contains('confirm')) return 'Booking confirmed — awaiting journey';
    return _data?.message ?? 'Live tracking status';
  }

  bool _hasPandit() {
    if (_booking?.hasPandit == true) return true;
    if (_isNamedPandit(_data?.panditName)) return true;
    return _isNamedPandit(_passedPanditName);
  }

  int _stageIndex() {
    final live = _stageOf(_data?.trackingStatus);
    final book = _stageOf(_booking?.rawStatus ?? _booking?.status);
    if (live == -1 || book == -1) return -1;
    final candidates = <int>[live, book];
    if (_hasPandit()) candidates.add(2);
    final signal = candidates.where((v) => v >= 0).toList();
    return signal.isEmpty ? 0 : signal.reduce((a, b) => a > b ? a : b);
  }

  /// True once the journey itself has begun (stage 4 of 8 or live tracking).
  bool get _journeyLive =>
      _rawSt.contains('route') ||
      _rawSt.contains('transit') ||
      (_data?.isTracking ?? false);

  String _bannerTitle() {
    if (_isCompleted) return 'Sacred Ceremony Completed';
    final rawSt = _rawSt;
    if (rawSt.contains('aarti')) return 'Purna Ahuti & Aarti Live';
    if (rawSt.contains('progress')) return 'Live Puja in Progress';
    if (rawSt.contains('arrived')) return 'Acharya Reached Mandap';
    if (_journeyLive) return '${_acharyaName()} is on the way';
    return '${_acharyaName()} Assigned for Your Ceremony';
  }

  String _bannerSubtitle() {
    if (_isCompleted) return 'Ritual concluded with sanctity • Shubham Bhavatu';
    final rawSt = _rawSt;
    if (rawSt.contains('arrived')) {
      return 'Acharya has arrived at your address and is preparing the mandap kund.';
    }
    if (rawSt.contains('progress')) {
      return 'Vedic mantras & hawan in progress. Family members can join stream.';
    }
    // Distance / ETA ship with the enriched booking from the moment the
    // Acharya is assigned (web shows them pre-journey too).
    final dist = _distKm();
    final eta = _etaMins();
    final stats = <String>[
      if (dist != null && dist > 0) '${dist.toStringAsFixed(1)} km away',
      if (eta != null && eta > 0) 'Estimated arrival in $eta Mins',
    ].join(' • ');
    if (!_journeyLive && !rawSt.contains('complete')) {
      const note =
          'Live GPS tracking and the route map activate automatically '
          'once the Acharya starts the journey.';
      return stats.isEmpty ? note : '$stats • $note';
    }
    return stats.isEmpty
        ? 'Live transit ETA and distance update automatically.'
        : stats;
  }

  String _muhurat() {
    final slot = (_booking?.timeSlot ?? '').split('(')[0].trim();
    return slot.isEmpty ? 'Morning Muhurat' : slot;
  }

  String _venueAddress() {
    final pin = (_pinAddress ?? '').trim();
    if (pin.isNotEmpty) return pin;
    final base = [
      (_booking?.address ?? '').trim(),
      (_booking?.addressLine1 ?? '').trim(),
      (_passedAddress ?? '').trim(),
    ].firstWhere((v) => v.isNotEmpty, orElse: () => '');
    if (base.isNotEmpty) return base;
    final tail = [
      (_booking?.city ?? '').trim(),
      (_booking?.state ?? '').trim(),
      (_booking?.pincode ?? '').trim(),
    ].where((v) => v.isNotEmpty).join(', ');
    return tail.isEmpty ? 'Mandap Address' : tail;
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final cam = _mapController.camera;
    _mapController.move(
      cam.center,
      (cam.zoom + delta).clamp(3.0, 18.0).toDouble(),
    );
  }

  void _centerOn(LatLng? target, double zoom) {
    if (!_mapReady || target == null) return;
    _lastCentered = target;
    _mapController.move(target, zoom);
  }

  void _fitRoute() {
    if (!_mapReady) return;
    final p = _panditTarget();
    final m = _mandapTarget();
    if (p == null || m == null) return;
    _lastCentered = p;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([p, m]),
        padding: const EdgeInsets.all(70),
      ),
    );
  }

  Future<void> _callAcharya() async {
    final phone = _acharyaPhone();
    if (phone == null) {
      showAppToast(
        context,
        'Acharya phone number is not available yet.',
        type: ToastType.warning,
        title: 'Call Acharya',
      );
      return;
    }
    final ok = await callNumber(phone);
    if (!ok && mounted) {
      showAppToast(
        context,
        'Unable to place the call. Please try again.',
        type: ToastType.error,
        title: 'Call Acharya',
      );
    }
  }

  Future<void> _whatsappAcharya() async {
    final phone = _acharyaPhone();
    if (phone == null) {
      showAppToast(
        context,
        'Acharya phone number is not available yet.',
        type: ToastType.warning,
        title: 'WhatsApp',
      );
      return;
    }
    final ceremony = (_booking?.ceremony ?? 'Puja').trim();
    final ok = await openWhatsApp(
      phone,
      message:
          'Namaste Ji, waiting for your arrival for our $ceremony.',
    );
    if (!ok && mounted) {
      showAppToast(
        context,
        'Unable to open WhatsApp. Please try again.',
        type: ToastType.error,
        title: 'WhatsApp',
      );
    }
  }

  Future<String?> _reverseGeocode(double lat, double lon) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2'
      '&lat=$lat&lon=$lon',
    );
    final res = await http
        .get(uri, headers: {'User-Agent': 'PanditIndia/1.0 (customer)'})
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final addr = data['address'] as Map<String, dynamic>? ?? {};
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = addr[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    final street = [
      pick(['building', 'house_number']),
      pick(['road', 'pedestrian', 'street']),
      pick(['suburb', 'neighbourhood', 'residential']),
    ].where((v) => v.isNotEmpty).join(', ');
    final display = (data['display_name'] as String? ?? '').trim();
    final line1 = street.isNotEmpty
        ? street
        : (display.isEmpty
              ? ''
              : display.split(',').take(2).join(',').trim());
    final city = pick([
      'city',
      'town',
      'village',
      'city_district',
      'county',
    ]);
    final state = pick(['state']);
    final postcode = pick(['postcode']).replaceAll(RegExp(r'\D'), '');
    final parts = [
      if (line1.isNotEmpty) line1,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (postcode.isNotEmpty) postcode,
    ];
    if (parts.isEmpty) return null;
    return postcode.isEmpty
        ? parts.join(', ')
        : '${parts.take(parts.length - 1).join(', ')} - $postcode';
  }

  Future<void> _updateMandapPin() async {
    if (_updatingPin) return;
    final trackedId = _bookingId;
    showAppToast(
      context,
      'Acquiring precise GPS coordinates...',
      type: ToastType.info,
      title: 'Mandap Pin',
    );
    setState(() => _updatingPin = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showAppToast(
            context,
            'Location services are disabled. Please enable GPS.',
            type: ToastType.error,
            title: 'Mandap Pin',
          );
        }
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        if (mounted) {
          showAppToast(
            context,
            'Location permission denied. Please allow GPS access.',
            type: ToastType.error,
            title: 'Mandap Pin',
          );
        }
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          showAppToast(
            context,
            'Location permission permanently denied. Enable it in app settings.',
            type: ToastType.error,
            title: 'Mandap Pin',
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      String? address;
      try {
        address = await _reverseGeocode(pos.latitude, pos.longitude);
      } catch (_) {
        address = null;
      }
      if (!mounted) return;
      if (Booking.normalizeIdString(trackedId) !=
          Booking.normalizeIdString(_bookingId)) {
        return; // the user switched bookings while GPS was acquiring
      }
      setState(() {
        _pinLat = pos.latitude;
        _pinLon = pos.longitude;
        if (address != null && address.isNotEmpty) _pinAddress = address;
      });
      _recenterIfNeeded();
      if (mounted) {
        showAppToast(
          context,
          address != null
              ? 'Venue detected: $address'
              : 'Location acquired (${pos.latitude.toStringAsFixed(4)}, '
                    '${pos.longitude.toStringAsFixed(4)})',
          type: ToastType.success,
          title: 'Mandap Pin',
        );
      }
    } catch (_) {
      if (mounted &&
          Booking.normalizeIdString(trackedId) ==
              Booking.normalizeIdString(_bookingId)) {
        showAppToast(
          context,
          'Unable to detect your location. Please try again.',
          type: ToastType.error,
          title: 'Mandap Pin',
        );
      }
    } finally {
      if (mounted) setState(() => _updatingPin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingProvider>().myBookings;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: GradientAppBar(title: 'Live Tracking'),
      body: _loading && _data == null && _booking == null
          ? const LoadingView(label: 'Fetching live location...')
          : _failed && _data == null && _booking == null
          ? EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Unable to load tracking',
              subtitle: 'Please check your connection and try again.',
              actionLabel: 'Retry',
              onAction: () {
                setState(() {
                  _loading = true;
                  _failed = false;
                });
                _load();
                _loadBooking();
              },
            )
          : _buildBody(bookings),
    );
  }

  Widget _buildBody(List<Booking> bookings) {
    final assigned = _hasPandit();
    // Spec Steps 1–3 + web parity: no map before assignment; from the
    // moment the Acharya is assigned the map opens with the pandit pin
    // (enriched coords), and once the journey streams the pin follows the
    // live fix. `_waitingGps()` only appears in the rare assigned-but-no-
    // coordinates-anywhere case. The customer's own mandap pin (set via the
    // Acharya card) still renders so pin edits stay visible.
    final showMap =
        _panditTarget() != null || (_pinLat != null && _pinLon != null);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _headerCard(bookings),
        if (!assigned) ...[
          const SizedBox(height: 12),
          _waitingAssignment(),
          const SizedBox(height: 12),
          _lifecycleCard(),
        ] else ...[
          if (_failed && _data != null) ...[
            const SizedBox(height: 12),
            _offlineStrip(),
          ],
          const SizedBox(height: 12),
          // Web parity: once the puja concludes the whole tracking window
          // becomes the "Sacred Ceremony Concluded & Blessed" view with the
          // rate / receipt / book-next actions — no dead banner or map.
          if (_isCompleted)
            _concludedCard()
          else ...[
            _statusBanner(),
            const SizedBox(height: 12),
            if (showMap) _mapCard() else _waitingGps(),
          ],
          const SizedBox(height: 12),
          _acharyaCard(),
          const SizedBox(height: 12),
          _lifecycleCard(),
        ],
      ],
    );
  }

  Widget _headerCard(List<Booking> bookings) {
    final done = _isCompleted;
    final pin = _numericPin();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _amber200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: done
                        ? const [Color(0xFF059669), Color(0xFF0D9488)]
                        : const [AppColors.accent, _amber400, Color(0xFFE07B00)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.podcasts_rounded,
                      size: 11,
                      color: done ? Colors.white : _rose700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      done
                          ? 'RITUAL CONCLUDED'
                          : (_liveStreamActive
                              ? 'LIVE TELEMETRY ACTIVE'
                              : 'STANDBY — AWAITING GPS'),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: done ? Colors.white : _darkBg,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _amber50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _amber200, width: 1.2),
                ),
                child: Text(
                  'Ref #$pin',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: _amber900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                done
                    ? Icons.verified_rounded
                    : Icons.podcasts_rounded,
                size: 16,
                color: done ? _emerald600 : _rose500,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  done
                      ? 'Sacred Ceremony Concluded & Blessed'
                      : 'Live Pandit & Ceremony GPS Tracking',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _slate900,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            done
                ? 'Sacred ceremony has concluded. Live map tracking is closed and divine blessings are fulfilled.'
                : 'Real-time GPS navigation, live transit ETA, and ceremony milestone updates.',
            style: const TextStyle(
              fontSize: 11.5,
              color: _slate600,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (bookings.isNotEmpty) ...[
            const SizedBox(height: 12),
            _bookingSwitcher(bookings),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _amber50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _amber200, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_note_rounded,
                        size: 13,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_booking?.displayId ?? '#PI-2026-3'} • '
                          '${_booking?.ceremony ?? 'Sacred Ceremony'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: _slate900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final ref = _booking?.displayId ?? '#PI-2026-8842';
                  final ceremony = _booking?.ceremony ?? 'Sacred Ceremony';
                  SharePlus.instance.share(
                    ShareParams(
                      text: 'Follow my PanditIndia ceremony live — '
                          '$ceremony ($ref).\n'
                          'Open the devotee dashboard: '
                          'https://panditindia.com/#/dashboard',
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _amber200, width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.share_rounded,
                        size: 13,
                        color: _blue600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: _slate900,
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
    );
  }

  /// Compact booking picker mirroring the `<select>` in the web tracking
  /// header (UserDashboardPage.jsx `selectedNavBookingId`). Like the web
  /// dashboard it stays visible even when only one booking exists.
  Widget _bookingSwitcher(List<Booking> bookings) {
    // Keyed by normalized id so the dropdown values stay unique (two bookings
    // without an id would otherwise trip DropdownButton's single-match assert).
    final unique = <String, Booking>{};
    for (final b in bookings) {
      unique[Booking.normalizeIdString(b.bookingId)] = b;
    }
    final current = Booking.normalizeIdString(_bookingId);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _amber50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amber200, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: unique.containsKey(current) ? current : null,
          isExpanded: true,
          isDense: true,
          icon: const Icon(
            Icons.expand_more_rounded,
            size: 20,
            color: _amber900,
          ),
          hint: const Text(
            'Select a booking to track',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: _slate500,
            ),
          ),
          items: [
            for (final entry in unique.entries)
              DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  '${entry.value.displayId} • '
                  '${entry.value.ceremony ?? 'Puja'}'
                  '${entry.value.isCompleted ? ' (Completed)' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: _slate900,
                  ),
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) _switchTo(v);
          },
        ),
      ),
    );
  }

  Widget _offlineStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connection issue — showing last known location',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Web "Sacred Ceremony Concluded & Blessed" panel — replaces the live
  /// banner and map once the puja completes, offering the same three
  /// post-ceremony actions as the web dashboard: Rate Acharya & Ceremony,
  /// Download PDF Receipt and Book Next Ceremony.
  Widget _concludedCard() {
    final b = _booking;
    if (b == null) return const SizedBox.shrink();
    final ceremony = b.ceremony ?? 'Sacred Ceremony';
    final gotram = (b.gothram ?? '').trim();

    Widget action({
      required String label,
      required IconData icon,
      required VoidCallback onTap,
      required Color fg,
      required Color bg,
      required Color border,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
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
            ceremony,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ritual concluded with complete sanctity • '
            '${b.priceDisplay}${gotram.isNotEmpty ? ' • Gotram: $gotram' : ''}',
            style: const TextStyle(
              color: Color(0xFFA7F3D0),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mandap: ${_venueAddress()}',
            style: const TextStyle(
              color: Color(0xFF6EE7B7),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Color(0xFF6EE7B7),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Live GPS tracking has concluded. You can rate the '
                    'Acharya or download your official receipt.',
                    style: TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
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
              action(
                label: 'Rate Acharya & Ceremony',
                icon: Icons.star_rounded,
                fg: AppColors.primary,
                bg: AppColors.accent,
                border: AppColors.accent,
                onTap: () => showReviewSheet(
                  context,
                  bookingId: b.bookingId ?? 0,
                  ceremonyName: ceremony,
                  panditName: b.assignedPandit,
                  devoteeName: b.fullName,
                ),
              ),
              action(
                label: 'Download PDF Receipt',
                icon: Icons.picture_as_pdf_rounded,
                fg: const Color(0xFF047857),
                bg: Colors.white,
                border: const Color(0xFFA7F3D0),
                onTap: () => ReceiptPdf.share(context, b),
              ),
              action(
                label: 'Book Next Ceremony',
                icon: Icons.add_circle_rounded,
                fg: Colors.white,
                bg: const Color(0xFF059669),
                border: const Color(0xFF059669),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PujaCatalogueScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBanner() {
    final stale = _isStale();
    final accuracy = _data?.accuracy;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_darkBg, _bannerMid, _darkBg],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amber400.withValues(alpha: 0.5), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accent, _amber400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_bannerIcon(), size: 22, color: _slate900),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          _bannerTitle(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: _amber300,
                          ),
                        ),
                        _livePill(stale, accuracy),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _bannerSubtitle(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: _slate300,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _amber400.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'SANKALPA PIN',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: _amber300,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _lastFourPin(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 3,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Scheduled Muhurat',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: _slate300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _muhurat(),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _bannerIcon() {
    final rawSt = _rawSt;
    if (rawSt.contains('complete')) return Icons.check_circle_rounded;
    if (rawSt.contains('arrived')) return Icons.celebration_rounded;
    if (rawSt.contains('progress') || rawSt.contains('aarti')) {
      return Icons.local_fire_department_rounded;
    }
    return _journeyLive ? Icons.directions_car_rounded : Icons.hourglass_top_rounded;
  }

  Widget _livePill(bool stale, double? accuracy) {
    final live = !stale;
    // Honest states: "Live GPS" only for a genuinely fresh stream; a
    // started-but-stale stream is updating; before the journey the GPS
    // simply hasn't begun.
    final label = live
        ? 'Live GPS${accuracy != null ? ' (±${accuracy.round()}m)' : ''}'
        : (_journeyLive ? 'Location updating...' : 'GPS starts at journey');
    final color = live ? const Color(0xFF34D399) : _amber400;
    final textColor = live ? _emerald300 : _amber300;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapCard() {
    final markers = <Marker>[];
    final pandit = _panditTarget();
    final mandap = _mandapTarget();
    if (pandit != null) {
      markers.add(
        Marker(
          point: pandit,
          width: 48,
          height: 48,
          child: const _MapPin(
            color: AppColors.accent,
            icon: Icons.person_pin_circle_rounded,
          ),
        ),
      );
    }
    if (mandap != null) {
      markers.add(
        Marker(
          point: mandap,
          width: 46,
          height: 46,
          child: const _MapPin(
            color: AppColors.primary,
            icon: Icons.home_rounded,
          ),
        ),
      );
    }
    final center = _target() ?? _fallbackCenter;
    final showFit = pandit != null && mandap != null;
    // Road route (OSRM) when fetched; dashed straight line as the fallback
    // so the pandit→mandap path is always visible like the web dashboard.
    final routeLines = <Polyline>[
      if (_routePoints != null && _routePoints!.length >= 2)
        Polyline(
          points: _routePoints!,
          strokeWidth: 4.5,
          color: AppColors.accent,
          pattern: const StrokePattern.solid(),
        )
      else if (pandit != null && mandap != null)
        Polyline(
          points: [pandit, mandap],
          strokeWidth: 3.5,
          color: AppColors.accent.withValues(alpha: 0.75),
          pattern: StrokePattern.dashed(segments: const [6, 8]),
        ),
    ];
    return Container(
      height: 460,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _amber300, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: pandit != null ? 15 : 12,
              onMapReady: () {
                _mapReady = true;
                _recenterIfNeeded();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.panditindia.customer',
                // Tiles pruned while the camera moves are aborted mid-flight;
                // on the web that surfaces as an unmapped DOMException
                // "AbortError" for every tile. Keep the map console-clean —
                // aborted/failed fetches simply render a transparent tile.
                tileProvider: NetworkTileProvider(silenceExceptions: true),
              ),
              PolylineLayer(polylines: routeLines),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Column(
              children: [
                _zoomButton(Icons.add_rounded, () => _zoomBy(1)),
                const SizedBox(height: 6),
                _zoomButton(Icons.remove_rounded, () => _zoomBy(-1)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '© OpenStreetMap',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: _slate500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (pandit != null)
                  _mapAction(
                    icon: Icons.my_location_rounded,
                    iconColor: _rose500,
                    label: 'Center on Pandit',
                    onTap: () => _centerOn(pandit, 16),
                  ),
                if (mandap != null) ...[
                  const SizedBox(height: 8),
                  _mapAction(
                    icon: Icons.home_rounded,
                    iconColor: _emerald600,
                    label: 'Center on Mandap',
                    onTap: () => _centerOn(mandap, 16),
                  ),
                ],
                if (showFit) ...[
                  const SizedBox(height: 8),
                  _mapAction(
                    icon: Icons.open_in_full_rounded,
                    iconColor: _blue600,
                    label: 'Full Route',
                    onTap: _fitRoute,
                  ),
                ],
              ],
            ),
          ),
          Positioned(left: 12, right: 12, bottom: 12, child: _hudStrip()),
        ],
      ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: _slate900),
      ),
    );
  }

  Widget _mapAction({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _slate200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: _slate900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hudStrip() {
    final eta = _etaMins();
    final dist = _distKm();
    final speed = _speedKmph();
    final coords = _panditCoords();
    final coordsText = coords != null
        ? '${coords.$2.toStringAsFixed(4)}, ${coords.$3.toStringAsFixed(4)}'
        : '—';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _darkBg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amber400.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _hudCell(
                label: 'Estimated Arrival',
                value: eta == null
                    ? '—'
                    : eta > 0
                    ? '$eta Mins'
                    : 'Arrived',
              ),
              _hudCell(
                label: 'Distance Remaining',
                value: dist != null ? '${dist.toStringAsFixed(1)} km' : '—',
              ),
              _hudCell(
                label: 'Transit Speed',
                value: speed != null
                    ? '${speed.toStringAsFixed(0)} km/h'
                    : '—',
                valueColor: const Color(0xFF34D399),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _hudCell(
                label: 'Pandit Lat / Lon',
                value: coordsText,
                mono: true,
                valueColor: _amber300,
                fontSize: 13,
              ),
              const SizedBox(width: 8),
              _hudCell(
                label: 'Telemetry Status',
                value: _statusText(),
                valueColor: _amber300,
                fontSize: 11.5,
                flex: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hudCell({
    required String label,
    required String value,
    Color valueColor = Colors.white,
    double fontSize = 14,
    bool mono = false,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: _amber400,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: mono ? FontWeight.w800 : FontWeight.w900,
              color: valueColor,
              height: 1.2,
              fontFeatures: mono
                  ? const [FontFeature.tabularFigures()]
                  : const [],
            ),
          ),
        ],
      ),
    );
  }

  Widget _acharyaCard() {
    final name = _acharyaName();
    final initials = name.isEmpty
        ? 'A'
        : name
              .split(' ')
              .where((p) => p.isNotEmpty)
              .take(2)
              .map((p) => p[0].toUpperCase())
              .join();
    final veda = (_booking?.panditVeda ?? '').trim();
    final photo = (_booking?.panditPhoto ?? '').trim();
    final exp = (_booking?.panditExperience ?? '').trim();
    final coords = _panditCoords();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _amber50.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _amber200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _amber100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent, width: 1.5),
                ),
                alignment: Alignment.center,
                child: photo.isNotEmpty
                    ? Image.network(
                        photo,
                        fit: BoxFit.cover,
                        width: 50,
                        height: 50,
                        errorBuilder: (_, _, _) => Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accentHover,
                          ),
                        ),
                      )
                    : Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accentHover,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ASSIGNED ACHARYA',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: _amber900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _slate900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Text(
                          'Verified Acharya',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _emerald600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '• ${veda.isEmpty ? 'Vedic Scholar' : veda}'
                            '${exp.isEmpty ? '' : ' • $exp'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: _slate600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (coords != null) ...[
            const SizedBox(height: 12),
            _coordsBox(coords),
          ],
          const SizedBox(height: 12),
          _ritualBox(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _callAcharya,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _amber200, width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 14,
                          color: _emerald700,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Call Acharya',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _slate900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _whatsappAcharya,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_emerald600, _teal600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _updateMandapPin,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: _blue50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _blue200, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_updatingPin)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _blue600,
                      ),
                    )
                  else
                    const Icon(
                      Icons.my_location_rounded,
                      size: 14,
                      color: _blue600,
                    ),
                  const SizedBox(width: 6),
                  const Text(
                    'Update Accurate Mandap Pin',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: _blue800,
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

  Widget _coordsBox((bool, double, double) coords) {
    final (live, lat, lon) = coords;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _amber100.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amber300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 12, color: _rose500),
                  SizedBox(width: 4),
                  Text(
                    'PANDIT COORDINATES:',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: _amber900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: live ? _emerald600 : _blue600,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  live ? 'Live GPS' : 'pandit_profile table',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _coordChip('Lat: ${lat.toStringAsFixed(5)}'),
              const SizedBox(width: 8),
              _coordChip('Lon: ${lon.toStringAsFixed(5)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coordChip(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _amber300),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _slate900,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _ritualBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amber100, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SACRED RITUAL:',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: _slate400,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _booking?.priceDisplay ?? '—',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: _emerald700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _booking?.ceremony ?? 'Vedic Ceremony',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: _slate900,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: _slate100),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 13,
                color: _rose500,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _venueAddress(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: _slate600,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lifecycleCard() {
    final stage = _stageIndex();
    final cancelled = stage < 0;
    final badgeLabel = cancelled
        ? 'Ceremony Cancelled'
        : 'Stage ${stage + 1} of 8: ${_stages[stage].title}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _amber100, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.checklist_rounded,
                size: 15,
                color: _emerald600,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '8-Stage Sacred Ritual Lifecycle',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: _slate900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: cancelled ? const Color(0xFFFEF2F2) : _amber100,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: cancelled ? const Color(0xFFFECACA) : _amber300,
                ),
              ),
              child: Text(
                badgeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: cancelled ? AppColors.danger : _amber900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.3,
            ),
            itemCount: _stages.length,
            itemBuilder: (context, i) => _stageCell(i, stage),
          ),
        ],
      ),
    );
  }

  Widget _stageCell(int i, int stage) {
    final s = _stages[i];
    final isPast = stage >= 0 && i < stage;
    final isCurrent = stage >= 0 && i == stage;
    final bg = isPast
        ? _emerald50
        : isCurrent
        ? _amber50
        : _slate50;
    final borderColor = isPast
        ? _emerald300
        : isCurrent
        ? _amber400
        : _slate200;
    final textColor = isPast
        ? _emerald800
        : isCurrent
        ? _amber900
        : _slate400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: isCurrent
            ? const [
                BoxShadow(
                  color: Color(0x29FBBF24),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${isPast ? '✓ ' : ''}${i + 1}. ${s.title}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            s.desc,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              color: textColor.withValues(alpha: 0.85),
              height: 1.2,
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, _amber400],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'CURRENT',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: _slate900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _waitingAssignment() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _amber50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _amber200, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _amber100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.hourglass_bottom_rounded,
              size: 34,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Waiting for Acharya Assignment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: _slate900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your sacred ceremony is booked successfully! We are currently '
                'assigning the best Vedic Acharya for you. The Acharya\'s '
                'profile, contact options and the 8-stage ritual lifecycle '
                'will appear here as soon as the assignment is made, and the '
                'Live GPS Tracking Map will activate once the Acharya starts '
                'the journey to your mandap.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _slate600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _waitingGps() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _amber50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _amber200, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.satellite_alt_rounded,
              size: 34,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Waiting for Live GPS Signal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: _slate900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Acharya ${_acharyaName()} is assigned for this ceremony. Live GPS coordinates, transit ETA and the route map will appear here as soon as the journey to your mandap begins.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: _slate600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
