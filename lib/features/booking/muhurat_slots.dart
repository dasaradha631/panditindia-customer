import 'dart:math' as math;

/// Pure-Dart port of the web booking step-2 Muhurat engine —
/// `frontend/src/components/booking/StepMuhurat.jsx`
/// (`getCalculatedSolarTimes`, `getNightMoonriseTiming`, `parseTimeToDecimal`,
/// `formatDecimalToTime`, the `ceremonySlots` memo and the slot-selection
/// `useEffect`), so the mobile app re-computes the exact same nine Vedic
/// windows for every date/city combination the web flow offers.

/// One ephemeris-backed ceremony window (the nine `ceremonySlots` entries).
class MuhuratSlot {
  const MuhuratSlot({
    required this.id,
    required this.category,
    required this.title,
    required this.timeWindow,
    required this.slotName,
    required this.badge,
    required this.desc,
    required this.recommendedFor,
    this.isPopular = false,
    this.isSupreme = false,
  });

  final String id;
  final String category; // morning | afternoon | evening
  final String title;
  final String timeWindow;
  final String slotName;
  final String badge;
  final String desc;
  final String recommendedFor;
  final bool isPopular;
  final bool isSupreme;
}

/// Night Moonrise window (web `getNightMoonriseTiming`).
class MoonWindow {
  const MoonWindow({required this.time, required this.badge, required this.desc});

  final String time;
  final String badge;
  final String desc;
}

/// High-precision solar window for one date + city (web
/// `getCalculatedSolarTimes`): decimal IST hours for sunrise / sunset plus
/// the coordinates the calculation used.
class SolarWindow {
  const SolarWindow({
    required this.sunriseHour,
    required this.sunsetHour,
    required this.dayDuration,
    required this.latitude,
    required this.longitude,
    required this.dateObj,
  });

  final double sunriseHour;
  final double sunsetHour;
  final double dayDuration;
  final double latitude;
  final double longitude;
  final DateTime dateObj;
}

/// `'06:12 AM'` → decimal hours (web `parseTimeToDecimal`; 19.5 fallback).
double parseTimeToDecimal(String? timeStr) {
  if (timeStr == null || timeStr.isEmpty) return 19.5;
  final m = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false)
      .firstMatch(timeStr);
  if (m == null) return 19.5;
  var h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  final ampm = (m.group(3) ?? '').toUpperCase();
  if (ampm == 'PM' && h < 12) h += 12;
  if (ampm == 'AM' && h == 12) h = 0;
  return h + min / 60.0;
}

/// Decimal hours → `'06:12 AM'` (web `formatDecimalToTime`).
String formatDecimalToTime(double dec) {
  var totalMin = (dec * 60).round();
  totalMin = ((totalMin % 1440) + 1440) % 1440;
  var h = totalMin ~/ 60;
  final m = totalMin % 60;
  final ampm = h >= 12 ? 'PM' : 'AM';
  h = h % 12;
  if (h == 0) h = 12;
  final hh = h.toString().padLeft(2, '0');
  final mm = m.toString().padLeft(2, '0');
  return '$hh:$mm $ampm';
}

/// Solar times for any date + Indian city — port of the web helper with the
/// identical latitude/longitude table so both platforms pick identical
/// windows even when the Skyfield endpoint is unavailable.
SolarWindow getCalculatedSolarTimes(String dateStr, [String cityStr = '']) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(dateStr);
  if (match == null) {
    final now = DateTime.now();
    return SolarWindow(
      sunriseHour: 6.15,
      sunsetHour: 18.15,
      dayDuration: 12.0,
      latitude: 17.385,
      longitude: 78.4867,
      dateObj: DateTime(now.year, now.month, now.day),
    );
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final dateObj = DateTime(year, month, day);

  final dayOfYear = dateObj.difference(DateTime(year, 1, 1)).inDays + 1;

  var lat = 17.385;
  var lon = 78.4867;
  final lowerCity = cityStr.toLowerCase();
  if (lowerCity.contains('delhi') ||
      lowerCity.contains('noida') ||
      lowerCity.contains('gurugram')) {
    lat = 28.6139;
    lon = 77.209;
  } else if (lowerCity.contains('mumbai') || lowerCity.contains('pune')) {
    lat = 19.076;
    lon = 72.8777;
  } else if (lowerCity.contains('bengaluru') || lowerCity.contains('bangalore')) {
    lat = 12.9716;
    lon = 77.5946;
  } else if (lowerCity.contains('chennai')) {
    lat = 13.0827;
    lon = 80.2707;
  } else if (lowerCity.contains('kolkata')) {
    lat = 22.5726;
    lon = 88.3639;
  } else if (lowerCity.contains('varanasi') || lowerCity.contains('lucknow')) {
    lat = 25.3176;
    lon = 82.9739;
  } else if (lowerCity.contains('ahmedabad')) {
    lat = 23.0225;
    lon = 72.5714;
  } else if (lowerCity.contains('andhra') ||
      lowerCity.contains('vijayawada') ||
      lowerCity.contains('visakhapatnam')) {
    lat = 16.5062;
    lon = 80.648;
  }

  final declination =
      23.44 * math.sin((2 * math.pi / 365.25) * (dayOfYear - 81));
  final decRad = declination * math.pi / 180;
  final latRad = lat * math.pi / 180;

  final cosH = (math.sin(-0.833 * math.pi / 180) -
          math.sin(latRad) * math.sin(decRad)) /
      (math.cos(latRad) * math.cos(decRad));
  final clampedCosH = cosH.clamp(-1.0, 1.0);
  final hHours = math.acos(clampedCosH) * 180 / (math.pi * 15);

  final b = (2 * math.pi / 365) * (dayOfYear - 81);
  final eot = 9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b);

  final solarNoon = 12.0 - (lon - 82.5) * (4.0 / 60.0) - eot / 60.0;
  final sunriseHour = solarNoon - hHours;
  final sunsetHour = solarNoon + hHours;
  final dayDuration = (sunsetHour - sunriseHour).clamp(10.0, 14.0);

  return SolarWindow(
    sunriseHour: sunriseHour,
    sunsetHour: sunsetHour,
    dayDuration: dayDuration,
    latitude: lat,
    longitude: lon,
    dateObj: dateObj,
  );
}

/// Night Chandrodaya window — port of web `getNightMoonriseTiming`.
MoonWindow nightMoonrise(Map<String, dynamic>? celestial) {
  if (celestial == null) {
    return const MoonWindow(
      time: '07:30 PM',
      badge: 'Night Chandrodaya',
      desc: 'Auspicious evening & night timing for Chandra Puja',
    );
  }

  final moonrise = celestial['moonrise']?.toString();
  final sunset = celestial['sunset']?.toString();
  final nightMoonriseRaw = celestial['night_moonrise']?.toString();
  final nightBadge = celestial['night_moonrise_badge']?.toString();

  // 1. Backend-computed night moonrise in PM.
  if (nightMoonriseRaw != null && nightMoonriseRaw.contains('PM')) {
    return MoonWindow(
      time: nightMoonriseRaw,
      badge: (nightBadge == null || nightBadge.isEmpty)
          ? 'Night Chandrodaya'
          : nightBadge,
      desc: 'Sacred evening Chandrodaya for night devotion, vratams & puja',
    );
  }

  // 2. Raw ephemeris moonrise already in the evening/night (05:30–11:59 PM).
  if (moonrise != null && moonrise.contains('PM')) {
    final m = RegExp(r'(\d{1,2}):(\d{2})\s*PM', caseSensitive: false)
        .firstMatch(moonrise);
    if (m != null) {
      final h = int.parse(m.group(1)!);
      if (h >= 5 || h == 12) {
        return MoonWindow(
          time: moonrise,
          badge: 'Night Chandrodaya',
          desc:
              'Sacred evening Chandrodaya for night devotion, vratams & puja',
        );
      }
    }
  }

  // 3. Morning/afternoon moonrise → sacred Ratri Chandrodaya ~75 min
  //    after sunset (Pradosham / Ratri Kaal).
  if (sunset != null && sunset.contains('PM')) {
    final s = RegExp(r'(\d{1,2}):(\d{2})\s*PM', caseSensitive: false)
        .firstMatch(sunset);
    if (s != null) {
      var h = int.parse(s.group(1)!);
      var min = int.parse(s.group(2)!) + 75;
      if (min >= 60) {
        h += min ~/ 60;
        min = min % 60;
      }
      final hh = h.toString().padLeft(2, '0');
      final mm = min.toString().padLeft(2, '0');
      return MoonWindow(
        time: '$hh:$mm PM',
        badge: 'Ratri Chandrodaya',
        desc:
            'Auspicious night timing for Chandra Puja, Sankashti & Vratam Aradhana',
      );
    }
  }

  return const MoonWindow(
    time: '07:30 PM',
    badge: 'Ratri Chandrodaya',
    desc: 'Prime night timing for Chandra Puja, Vratams & evening rituals',
  );
}

bool _hasTime(Map<String, dynamic>? celestial, String key) {
  final v = celestial?[key]?.toString();
  return v != null && v.isNotEmpty && v != 'N/A';
}

String? _slotOf(Map<String, dynamic>? celestial, String key) {
  final block = celestial?[key];
  if (block is Map) {
    final slot = block['slot']?.toString();
    if (slot != null && slot.isNotEmpty) return slot;
  }
  return null;
}

/// The nine Vedic Muhurat windows for [dateStr] + [cityStr] — direct port of
/// the web `ceremonySlots` memo. Backend Skyfield windows win whenever
/// [celestial] carries them; the deterministic solar arithmetic fills the rest.
List<MuhuratSlot> computeMuhuratSlots({
  required String dateStr,
  required String cityStr,
  Map<String, dynamic>? celestial,
}) {
  final solar = getCalculatedSolarTimes(dateStr, cityStr);

  final sunrise = _hasTime(celestial, 'sunrise')
      ? parseTimeToDecimal(celestial!['sunrise'].toString())
      : solar.sunriseHour;
  final sunset = _hasTime(celestial, 'sunset')
      ? parseTimeToDecimal(celestial!['sunset'].toString())
      : solar.sunsetHour;
  final dayDuration = (sunset - sunrise).clamp(10.0, 14.0);
  final muhuratLength = dayDuration / 15;

  // Weekday-driven Choghadiya offsets for morning Amrit & Labha.
  final dayOfWeek = solar.dateObj.weekday % 7; // Sun=0 … Sat=6 (web parity)
  const amritOffsets = <List<double>>[
    [2.3, 3.5], // Sun
    [2.0, 3.2], // Mon
    [2.4, 3.6], // Tue
    [1.7, 2.9], // Wed
    [2.1, 3.3], // Thu
    [2.5, 3.7], // Fri
    [1.8, 3.0], // Sat
  ];
  const labhaOffsets = <List<double>>[
    [3.6, 4.9], // Sun
    [3.4, 4.8], // Mon
    [3.7, 5.0], // Tue
    [3.1, 4.6], // Wed
    [3.5, 4.9], // Thu
    [3.9, 5.2], // Fri
    [3.2, 4.7], // Sat
  ];
  final amrit = amritOffsets[dayOfWeek];
  final labha = labhaOffsets[dayOfWeek];

  final nightMoon = nightMoonrise(celestial);

  final brahmaSlot = _slotOf(celestial, 'brahma_muhurat') ??
      '${formatDecimalToTime(sunrise - 1.6)} - ${formatDecimalToTime(sunrise - 0.8)}';
  final pratahSlot = _slotOf(celestial, 'pratah_muhurat') ??
      '${formatDecimalToTime(sunrise)} - ${formatDecimalToTime(sunrise + 1.5)}';
  final morningAmritSlot = _slotOf(celestial, 'morning_amrit_muhurat') ??
      '${formatDecimalToTime(sunrise + amrit[0])} - ${formatDecimalToTime(sunrise + amrit[1])}';
  final morningLabhaSlot = _slotOf(celestial, 'morning_labha_muhurat') ??
      '${formatDecimalToTime(sunrise + labha[0])} - ${formatDecimalToTime(sunrise + labha[1])}';
  final abhijitSlot = _slotOf(celestial, 'abhijit_muhurat') ??
      '${formatDecimalToTime(sunrise + 7 * muhuratLength)} - ${formatDecimalToTime(sunrise + 8 * muhuratLength)}';
  final vijayaSlot = _slotOf(celestial, 'vijaya_muhurat') ??
      '${formatDecimalToTime(sunrise + 10 * muhuratLength)} - ${formatDecimalToTime(sunrise + 11 * muhuratLength)}';
  final sayankalSlot = _slotOf(celestial, 'sayankal_muhurat') ??
      '${formatDecimalToTime(sunset - 1.5)} - ${formatDecimalToTime(sunset - 0.33)}';
  final godhuliSlot = _slotOf(celestial, 'godhuli_muhurat') ??
      '${formatDecimalToTime(sunset - 0.4)} - ${formatDecimalToTime(sunset + 0.4)}';
  final moonTime = nightMoon.time;
  final moonDec = parseTimeToDecimal(moonTime);
  final ratriSlot = '$moonTime - ${formatDecimalToTime(moonDec + 1.75)}';

  MuhuratSlot slot({
    required String id,
    required String category,
    required String title,
    required String badge,
    required String desc,
    required String recommendedFor,
    required String window,
    bool isPopular = false,
    bool isSupreme = false,
  }) =>
      MuhuratSlot(
        id: id,
        category: category,
        title: title,
        timeWindow: window,
        slotName: '$title ($window)',
        badge: badge,
        desc: desc,
        recommendedFor: recommendedFor,
        isPopular: isPopular,
        isSupreme: isSupreme,
      );

  return [
    slot(
      id: 'brahma',
      category: 'morning',
      title: 'Brahma Muhurat (Early Dawn)',
      badge: 'Spiritual Awakening',
      desc:
          'Sacred pre-dawn juncture for Pranayama, Ushakala pujas & Divine Sankalpam.',
      recommendedFor: 'Maha Rudrabhishekam, Ganapathi Homam',
      window: brahmaSlot,
    ),
    slot(
      id: 'pratah-shubh',
      category: 'morning',
      title: 'Pratah Shubh Muhurat',
      badge: 'Surya Udaya',
      desc:
          'Sunrise vitality ideal for Surya Namaskar, Ganapathi Puja & Mangala Snanam.',
      recommendedFor: 'Griha Pravesh, Ganapathi Homam',
      window: pratahSlot,
    ),
    slot(
      id: 'morning-amrit',
      category: 'morning',
      title: 'Morning Amrit & Shubh Muhurat',
      badge: '⭐ Devotee Favorite (Recommended)',
      desc:
          'Prime auspicious golden window for home entry, vratams, vivaha rituals & new milestones.',
      recommendedFor: 'Griha Pravesh, Satyanarayana Vratam, Vivaha',
      isPopular: true,
      window: morningAmritSlot,
    ),
    slot(
      id: 'morning-labha',
      category: 'morning',
      title: 'Morning Labha Muhurat',
      badge: 'Labha (Prosperity)',
      desc:
          'Optimal for business growth, wealth pujas, havan ceremonies & new agreements.',
      recommendedFor: 'Lakshmi Kubera Homam, Chandi Parayanam',
      window: morningLabhaSlot,
    ),
    slot(
      id: 'abhijit',
      category: 'afternoon',
      title: 'Golden Abhijit Muhurat',
      badge: '👑 Supreme Muhurat (Lord Vishnu Blessed)',
      desc:
          'The 8th Muhurat of the day that destroys all doshas. Flawless for all auspicious beginnings.',
      recommendedFor: 'All 18 Pujas & Ceremonies',
      isSupreme: true,
      window: abhijitSlot,
    ),
    slot(
      id: 'vijaya',
      category: 'afternoon',
      title: 'Aparahna Vijaya Muhurat',
      badge: 'Vijaya (Victory & Success)',
      desc:
          'Auspicious for overcoming hurdles, business milestones & Navagraha Shanti.',
      recommendedFor: 'Navagraha Dosha Shanti, Rudrabhishekam',
      window: vijayaSlot,
    ),
    slot(
      id: 'sayankal-shubh',
      category: 'evening',
      title: 'Sayankal Shubh Muhurat',
      badge: 'Pre-Sunset Shubh',
      desc:
          'Pre-dusk window ideal for Sundarakanda Parayanam, Hanuman Puja & Evening Havans.',
      recommendedFor: 'Sundarakanda, Hanuman Puja',
      window: sayankalSlot,
    ),
    slot(
      id: 'godhuli-pradosham',
      category: 'evening',
      title: 'Godhuli & Sandhya Pradosha Muhurat',
      badge: '🔱 Shiva & Lakshmi Pradosham',
      desc:
          'Sunset sacred juncture optimal for Shiva Puja, Sandhyavandanam, Lakshmi Deepam & Aarti.',
      recommendedFor: 'Maha Rudrabhishekam, Deepavali Lakshmi Puja',
      window: godhuliSlot,
    ),
    slot(
      id: 'ratri-chandrodaya',
      category: 'evening',
      title: 'Ratri Chandrodaya Muhurat',
      badge: 'Devotional Night',
      desc:
          'Night peace window ideal for Satyanarayana Katha recitation, Lalitha Sahasranama & Vratams.',
      recommendedFor: 'Satyanarayana Vratam, Devi Puja',
      window: ratriSlot,
    ),
  ];
}

/// Port of the web slot-synchronization `useEffect`: keeps the devotee's
/// chosen slot tied to the currently displayed date/city windows.
///
/// Returns the replacement `slotName`, or `null` when the current selection
/// must be kept untouched (custom astrologer slots / exact match / unmatched
/// free-text) or when no slot was chosen yet (caller then falls back to the
/// popular default, exactly like the web memo does).
String? syncSelectedSlot(String current, List<MuhuratSlot> slots) {
  if (current.isEmpty) {
    for (final s in slots) {
      if (s.isPopular) return s.slotName;
    }
    return slots.isNotEmpty ? slots.first.slotName : null;
  }

  // Custom astrologer prescribed / raw ephemeris markers stay untouched.
  if (current.startsWith('Custom Astrologer Muhurat') ||
      current.startsWith('Sunrise (') ||
      current.startsWith('Sunset (') ||
      current.startsWith('Moonrise (')) {
    return null;
  }

  MuhuratSlot? match;
  for (final s in slots) {
    if (s.slotName == current ||
        current.startsWith(s.title) ||
        (s.id == 'brahma' && RegExp('brahma', caseSensitive: false).hasMatch(current)) ||
        (s.id == 'pratah-shubh' && RegExp('pratah', caseSensitive: false).hasMatch(current)) ||
        (s.id == 'morning-amrit' && RegExp('amrit', caseSensitive: false).hasMatch(current)) ||
        (s.id == 'morning-labha' && RegExp('labha', caseSensitive: false).hasMatch(current)) ||
        (s.id == 'abhijit' && RegExp('abhijit', caseSensitive: false).hasMatch(current)) ||
        (s.id == 'vijaya' && RegExp('vijaya', caseSensitive: false).hasMatch(current)) ||
        (s.id == 'sayankal-shubh' && RegExp('sayankal', caseSensitive: false).hasMatch(current)) ||
        (s.id == 'godhuli-pradosham' &&
            (RegExp('godhuli', caseSensitive: false).hasMatch(current) ||
                RegExp('sandhya', caseSensitive: false).hasMatch(current) ||
                RegExp('pradosha', caseSensitive: false).hasMatch(current))) ||
        (s.id == 'ratri-chandrodaya' &&
            (RegExp('chandrodaya', caseSensitive: false).hasMatch(current) ||
                RegExp('ratri', caseSensitive: false).hasMatch(current)))) {
      match = s;
      break;
    }
  }
  if (match == null || match.slotName == current) return null;
  return match.slotName;
}
