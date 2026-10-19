import 'dart:math' as math;

import '../../services/kundli_service.dart';

/// Today's values for the home "Panchang & Tithi" strip — the mobile
/// counterpart of the web dashboard state (`panchangTithi`, `todayAbhijit`,
/// `todayRahuKaal` at `UserDashboardPage.jsx:194-197`).
class PanchangToday {
  const PanchangToday({this.tithi, this.abhijitMuhurat, this.rahuKaal});

  /// Full tithi name, e.g. `Shukla Paksha Ekadashi`.
  final String? tithi;

  /// Midday window, e.g. `11:52 AM - 12:44 PM`.
  final String? abhijitMuhurat;

  /// Inauspicious eighth of the day, e.g. `04:30 PM - 06:00 PM`.
  final String? rahuKaal;

  /// Field-wise merge: values from [override] win, this instance fills the
  /// gaps so a partial backend payload never blanks a known window.
  PanchangToday mergedWith(PanchangToday override) => PanchangToday(
        tithi: override.tithi ?? tithi,
        abhijitMuhurat: override.abhijitMuhurat ?? abhijitMuhurat,
        rahuKaal: override.rahuKaal ?? rahuKaal,
      );
}

/// Data source for the home panchang strip.
///
/// Web computes the bar client-side on a 1s interval
/// (`UserDashboardPage.jsx:770-803`). Mobile prefers the backend panchanga
/// the customer app already calls — `POST /muhurtham/calculate` returns the
/// monthly calendar whose every day carries a full `panchanga` block
/// (`generate_2026_auspicious_calendar` in `astrology_engine.py`, surfaced to
/// the app by `KundliService.calculateMuhurtham` and read by
/// `auspicious_calendar.dart`) — and falls back to the very same arithmetic
/// ported locally so the strip still renders offline or before sign-in.
class PanchangService {
  /// Backend default ceremony location coordinates (`kundli.py:229`).
  static const double defaultLatitude = 17.385;
  static const double defaultLongitude = 78.4867;

  /// Wall-clock source — the header pill shows minute precision, so tests
  /// reassign this to a fixed time to keep golden captures stable.
  static DateTime Function() now = DateTime.now;

  static const double _rad = math.pi / 180.0;

  static const List<String> _tithis = <String>[
    'Prathama',
    'Dwitiya',
    'Tritiya',
    'Chaturthi',
    'Panchami',
    'Shashthi',
    'Saptami',
    'Ashtami',
    'Navami',
    'Dashami',
    'Ekadashi',
    'Dwadashi',
    'Trayodashi',
    'Chaturdashi',
    'Purnima / Amavasya',
  ];

  /// Rahu Kaal slot (0-indexed eighth of the day) for Monday … Sunday —
  /// the `rahu_parts` table of `astrology_engine.calculate_daily_panchanga`.
  static const List<int> _rahuParts = <int>[1, 6, 4, 5, 3, 2, 7];

  /// Meeus Ch. 47 lunar series terms `(D, M, M', F, coefficient)` — the
  /// `moon_longitude_tropical` table of `astrology_engine.py`.
  static const List<List<int>> _moonTerms = <List<int>>[
    <int>[0, 0, 1, 0, 6288774],
    <int>[2, 0, -1, 0, 1274027],
    <int>[2, 0, 0, 0, 658314],
    <int>[0, 0, 2, 0, 213618],
    <int>[0, 1, 0, 0, -185116],
    <int>[0, 0, 0, 2, -114332],
    <int>[2, 0, -2, 0, 58793],
    <int>[2, -1, -1, 0, 57066],
    <int>[2, 0, 1, 0, 53322],
    <int>[2, -1, 0, 0, 45758],
    <int>[0, 1, -1, 0, -40923],
    <int>[1, 0, 0, 0, -34720],
    <int>[0, 1, 1, 0, -30383],
    <int>[2, 0, 0, -2, 15327],
    <int>[0, 0, 1, 2, -12528],
    <int>[0, 0, 1, -2, 10980],
    <int>[4, 0, -1, 0, 10675],
    <int>[0, 0, 3, 0, 10034],
    <int>[4, 0, -2, 0, 8548],
    <int>[2, 1, -1, 0, -7888],
    <int>[2, 1, 0, 0, -6766],
    <int>[1, 0, -1, 0, -5163],
    <int>[1, 1, 0, 0, 4987],
    <int>[2, -1, 1, 0, 4036],
    <int>[2, 0, 2, 0, 3994],
    <int>[4, 0, 0, 0, 3861],
    <int>[2, 0, -3, 0, 3665],
  ];

  final KundliService _kundli = KundliService();

  /// Today's panchanga from the backend calendar, or null whenever the call
  /// fails / the devotee's birth details are incomplete — callers keep the
  /// locally computed values in that case.
  Future<PanchangToday?> fetchFromCalendar({String? location}) async {
    try {
      final trimmed = (location ?? '').trim();
      final res = await _kundli.calculateMuhurtham({
        'ceremonyType': 'Griha Pravesh',
        'ceremonyLocation':
            trimmed.isEmpty ? 'Hyderabad, Telangana' : trimmed,
      });
      final days = res?.calendar?['days'];
      if (days is! List) return null;
      final today = _isoDate(ist(now()));
      for (final raw in days) {
        if (raw is! Map || raw['date']?.toString() != today) continue;
        final p = raw['panchanga'];
        if (p is! Map) return null;
        final tithi = p['tithi']?.toString();
        final abhijit = p['abhijit_muhurat']?.toString();
        final rahu = p['rahu_kaal']?.toString();
        if (tithi == null && abhijit == null && rahu == null) return null;
        return PanchangToday(
          tithi: tithi,
          abhijitMuhurat: abhijit,
          rahuKaal: rahu,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Offline port of `astrology_engine.calculate_daily_panchanga`: tithi from
  /// the Meeus lunar series, Abhijit as solar noon ± 24 min and Rahu Kaal as
  /// the eighth-part day slot after sunrise. Never throws — a failure yields
  /// an empty record the strip hides piece by piece.
  static PanchangToday computeLocal({
    DateTime? now,
    double? latitude,
    double? longitude,
  }) {
    try {
      final t = ist(now ?? PanchangService.now());
      final lat = latitude ?? defaultLatitude;
      final lon = longitude ?? defaultLongitude;

      final jd = _julianDay(t.year, t.month, t.day + 0.5 - (5.5 / 24.0));
      final cent = (jd - 2451545.0) / 36525.0;
      final elong = _norm360(_moonTropical(cent) - _sunTropical(cent));
      final tithiNum = (elong / 12).floor() + 1;

      final (sunrise, sunset) =
          _sunriseSunset(t.year, t.month, t.day, lat, lon);
      final part = (sunset - sunrise) / 8;
      final rahuStart = sunrise + _rahuParts[t.weekday - 1] * part;
      final solarNoon = (sunrise + sunset) / 2;

      return PanchangToday(
        tithi: _tithiName(tithiNum),
        abhijitMuhurat:
            '${_fmtHours(solarNoon - 0.4)} - ${_fmtHours(solarNoon + 0.4)}',
        rahuKaal:
            '${_fmtHours(rahuStart)} - ${_fmtHours(rahuStart + part)}',
      );
    } catch (_) {
      return const PanchangToday();
    }
  }

  /// IST wall clock (the web strip pins itself to `Asia/Kolkata`).
  static DateTime ist(DateTime time) =>
      time.toUtc().add(const Duration(hours: 5, minutes: 30));

  /// `04:32 PM IST` — minute precision for the lightweight ticker.
  static String clockLabel(DateTime time) {
    final t = ist(time);
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')} $period IST';
  }

  /// Web `panchangTithi` layout —
  /// `Bhanuvara (Sun) • Ashvina Masa • Shukla Paksha Ekadashi • Vikrama Samvat 2083`
  /// (`UserDashboardPage.jsx:777,795-798`).
  static String tithiLine(DateTime time, String? tithi) {
    const days = <String>[
      'Bhanuvara (Sun)',
      'Somavara (Mon)',
      'Mangalavara (Tue)',
      'Budhavara (Wed)',
      'Guruvara (Thu)',
      'Shukravara (Fri)',
      'Shanivara (Sat)',
    ];
    const months = <String>[
      'Chaitra',
      'Vaishakha',
      'Jyeshtha',
      'Ashadha',
      'Shravana',
      'Bhadrapada',
      'Ashvina',
      'Kartika',
      'Margashirsha',
      'Pausha',
      'Magha',
      'Phalguna',
    ];
    final t = ist(time);
    final parts = <String>[
      days[t.weekday % 7],
      '${months[(t.month + 9) % 12]} Masa',
      if (tithi != null && tithi.isNotEmpty) tithi,
      'Vikrama Samvat ${t.year + 57}',
    ];
    return parts.join(' • ');
  }

  static String _isoDate(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  static String _tithiName(int tithiNum) {
    if (tithiNum == 15) return 'Shukla Purnima (Full Moon)';
    if (tithiNum == 30) return 'Krishna Amavasya (New Moon)';
    final paksha = tithiNum <= 15 ? 'Shukla' : 'Krishna';
    // "Paksha" kept in the label — web's dashboard fallback renders
    // `Shukla Paksha Ekadashi` (UserDashboardPage.jsx:770-803).
    return '$paksha Paksha ${_tithis[(tithiNum - 1) % 15]}';
  }

  static String _fmtHours(double h) {
    var hour = h.truncate() % 24;
    var minute = ((h - h.truncate()) * 60).round();
    if (minute >= 60) {
      hour += 1;
      minute = 0;
    }
    final period = hour < 12 ? 'AM' : 'PM';
    final display = (hour == 0 || hour == 12) ? hour : hour % 12;
    return '${display.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')} $period';
  }

  static double _norm360(double deg) {
    final r = deg % 360.0;
    return r < 0 ? r + 360.0 : r;
  }

  /// Meeus Ch. 7 — [dayFraction] is the local date plus a fractional day.
  static double _julianDay(int year, int month, double dayFraction) {
    var y = year;
    var m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floorToDouble() +
        (30.6001 * (m + 1)).floorToDouble() +
        dayFraction +
        b -
        1524.5;
  }

  /// Sun's apparent tropical longitude — `sun_longitude_tropical`.
  static double _sunTropical(double t) {
    final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
    final m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
    final c = (1.914602 - 0.004817 * t - 0.000014 * t * t) *
            math.sin(m * _rad) +
        (0.019993 - 0.000101 * t) * math.sin(2 * m * _rad) +
        0.000289 * math.sin(3 * m * _rad);
    final omega = 125.04 - 1934.136 * t;
    return _norm360(l0 + c - 0.00569 - 0.00478 * math.sin(omega * _rad));
  }

  /// Moon's tropical longitude — `moon_longitude_tropical`.
  static double _moonTropical(double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    final t4 = t3 * t;
    final l1 = 218.3164477 +
        481267.88123421 * t -
        0.0015786 * t2 +
        t3 / 538841.0 -
        t4 / 65194000.0;
    final d = 297.8501921 +
        445267.1114034 * t -
        0.0018819 * t2 +
        t3 / 545868.0 -
        t4 / 113065000.0;
    final m = 357.5291092 +
        35999.0502909 * t -
        0.0001536 * t2 +
        t3 / 24490000.0;
    final mp = 134.9633964 +
        477198.8675055 * t +
        0.0087414 * t2 +
        t3 / 69699.0 -
        t4 / 14712000.0;
    final f = 93.272095 +
        483202.0175233 * t -
        0.0036539 * t2 -
        t3 / 3526000.0 +
        t4 / 863310000.0;
    final a1 = 119.75 + 131.849 * t;
    final a2 = 53.09 + 479264.29 * t;
    final e = 1.0 - 0.002516 * t - 0.0000074 * t * t;
    final e2 = e * e;

    var sum = 0.0;
    for (final term in _moonTerms) {
      final dc = term[0];
      final mc = term[1];
      final mpc = term[2];
      final fc = term[3];
      final arg = (dc * d + mc * m + mpc * mp + fc * f) * _rad;
      var coeff = term[4].toDouble();
      if (mc.abs() == 1) {
        coeff *= e;
      } else if (mc.abs() == 2) {
        coeff *= e2;
      }
      sum += coeff * math.sin(arg);
    }
    sum += 3958.0 * math.sin(a1 * _rad) +
        1962.0 * math.sin((l1 - f) * _rad) +
        318.0 * math.sin(a2 * _rad);
    return _norm360(l1 + sum / 1e6);
  }

  /// Sunrise / sunset in decimal IST hours — `compute_sunrise_sunset`.
  static (double, double) _sunriseSunset(
    int year,
    int month,
    int day,
    double lat,
    double lon,
  ) {
    final jd = _julianDay(year, month, day + 0.5);
    final t = (jd - 2451545.0) / 36525.0;
    final l0 = _norm360(280.46646 + 36000.76983 * t);
    final m = _norm360(357.52911 + 35999.05029 * t);
    final c = 1.914602 * math.sin(m * _rad) + 0.019993 * math.sin(2 * m * _rad);
    final sunTrue = l0 + c;
    final eps = (23.4392911 - 0.0130042 * t) * _rad;
    final sinDec = (math.sin(eps) * math.sin(sunTrue * _rad)).clamp(-1.0, 1.0);
    final dec = math.asin(sinDec);
    final zenith = 90.833 * _rad;
    final phi = lat * _rad;
    final cosH = ((math.cos(zenith) - math.sin(phi) * math.sin(dec)) /
            (math.cos(phi) * math.cos(dec)))
        .clamp(-1.0, 1.0);
    final hDeg = math.acos(cosH) / _rad;
    final timeDiff = (82.5 - lon) * (4.0 / 60.0);
    final y = math.pow(math.tan(eps / 2.0), 2).toDouble();
    final eqTime = (y * math.sin(2 * l0 * _rad) -
            2 * 0.0167 * math.sin(m * _rad)) *
        (12.0 / math.pi);
    final solarNoon = 12.0 + timeDiff - eqTime;
    final sunrise = solarNoon - (hDeg / 15.0);
    final sunset = solarNoon + (hDeg / 15.0);
    return (
      math.max(5.0, math.min(7.0, sunrise)),
      math.max(17.5, math.min(19.5, sunset)),
    );
  }
}
