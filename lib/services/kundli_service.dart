import '../core/network/api_client.dart';

class KundliResult {
  KundliResult({required this.success, this.kundli, this.transits = const []});

  final bool success;
  final Map<String, dynamic>? kundli;
  final List<dynamic> transits;

  bool get isComplete => kundli?['is_complete'] == true;
}

class MuhurthamResult {
  MuhurthamResult({
    required this.success,
    this.ceremony,
    this.recommendations = const [],
    this.ceremonyRecommendations = const [],
    this.calendar,
    this.disclaimer,
  });

  final bool success;
  final String? ceremony;
  final List<Map<String, dynamic>> recommendations;

  /// One best upcoming date per ceremony (web `ceremony_recommendations`).
  final List<Map<String, dynamic>> ceremonyRecommendations;
  final Map<String, dynamic>? calendar;
  final String? disclaimer;
}

class GeoLookupResult {
  GeoLookupResult({
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.placeOfBirth,
    this.timezone,
  });

  factory GeoLookupResult.fromJson(Map<String, dynamic> json) => GeoLookupResult(
        city: json['city']?.toString(),
        state: json['state']?.toString(),
        latitude: double.tryParse('${json['latitude']}'),
        longitude: double.tryParse('${json['longitude']}'),
        placeOfBirth: json['place_of_birth']?.toString(),
        timezone: json['timezone']?.toString(),
      );

  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final String? placeOfBirth;
  final String? timezone;
}

class KundliService {
  /// `GET /kundli/me` — mirrors the web `kundliService.getMyKundli`:
  /// passes the devotee's saved profile as query params (dob/tob/place/
  /// lat/lon/tz/name) so the backend can compute even when the profile row
  /// itself is incomplete.
  Future<KundliResult?> getMyKundli({
    String? dob,
    String? tob,
    String? place,
    String? lat,
    String? lon,
    String? tz,
    String? name,
  }) async {
    try {
      final query = <String, String>{
        if (dob != null && dob.trim().isNotEmpty) 'dob': dob.trim(),
        if (tob != null && tob.trim().isNotEmpty) 'tob': tob.trim(),
        if (place != null && place.trim().isNotEmpty) 'place': place.trim(),
        if (lat != null && lat.trim().isNotEmpty) 'lat': lat.trim(),
        if (lon != null && lon.trim().isNotEmpty) 'lon': lon.trim(),
        if (tz != null && tz.trim().isNotEmpty) 'tz': tz.trim(),
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      };
      final res = await ApiClient.get('/kundli/me', query: query);
      final body = res.body;
      if (body['success'] != true) return null;
      final kundli = body['kundli'] is Map<String, dynamic>
          ? body['kundli'] as Map<String, dynamic>
          : null;
      final transits = body['transits_2026'] is List
          ? body['transits_2026'] as List
          : const [];
      return KundliResult(success: true, kundli: kundli, transits: transits);
    } catch (_) {
      return null;
    }
  }

  /// `POST /muhurtham/calculate` — location-aware recommendations plus the
  /// monthly auspicious calendar grid (same payload as the web dashboard).
  Future<MuhurthamResult?> calculateMuhurtham(Map<String, dynamic> payload) async {
    try {
      final res = await ApiClient.post('/muhurtham/calculate', body: payload);
      final body = res.body;
      if (body['success'] != true) return null;
      final recommendations = <Map<String, dynamic>>[];
      final raw = body['recommendations'];
      if (raw is List) {
        recommendations.addAll(raw.whereType<Map<String, dynamic>>());
      }
      final ceremonyMatches = <Map<String, dynamic>>[];
      final rawMatches = body['ceremony_recommendations'];
      if (rawMatches is List) {
        ceremonyMatches.addAll(rawMatches.whereType<Map<String, dynamic>>());
      }
      return MuhurthamResult(
        success: true,
        ceremony: body['ceremony']?.toString(),
        recommendations: recommendations,
        ceremonyRecommendations: ceremonyMatches,
        calendar: body['calendar'] is Map<String, dynamic>
            ? body['calendar'] as Map<String, dynamic>
            : null,
        disclaimer: body['disclaimer']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Resolves raw birth details into a kundli summary (nakshatra / rashi)
  /// used by the registration Spiritual Details step. Returns null whenever
  /// any lookup fails so callers can fall back to manual entry.
  Future<Map<String, dynamic>?> calculateBirthKundli({
    required String dateOfBirth,
    String timeOfBirth = '',
    String placeOfBirth = '',
  }) async {
    double? lat;
    double? lon;
    if (placeOfBirth.trim().isNotEmpty) {
      final geo = await geoLookup(place: placeOfBirth.trim());
      lat = geo?.latitude;
      lon = geo?.longitude;
    }
    try {
      final body = <String, dynamic>{
        'dateOfBirth': dateOfBirth,
        'timeOfBirth': timeOfBirth,
        'birthPlace': placeOfBirth,
      };
      if (lat != null) body['birthLatitude'] = lat;
      if (lon != null) body['birthLongitude'] = lon;
      final res = await ApiClient.post(
        '/muhurtham/calculate',
        body: body,
        auth: false,
      );
      final resBody = res.body;
      final summary = resBody['kundli_summary'];
      if (resBody['success'] != true || summary is! Map<String, dynamic>) {
        return null;
      }
      return summary;
    } catch (_) {
      return null;
    }
  }

  /// `GET /kundli/celestial-times` — Skyfield JPL DE421 ephemeris block used
  /// by the web booking step 2 (`StepMuhurat.jsx kundliService
  /// .getCelestialTimes`): sunrise / sunset / moonrise / moonset plus the
  /// precomputed Vedic Muhurat windows for a date + city. Returns the raw
  /// payload on success and `null` on any failure so the booking flow can
  /// fall back to the deterministic local solar arithmetic.
  Future<Map<String, dynamic>?> getCelestialTimes(
    String date, {
    String? city,
  }) async {
    try {
      final res = await ApiClient.get(
        '/kundli/celestial-times',
        query: {
          'date': date,
          if (city != null && city.isNotEmpty) 'city': city,
        },
        auth: false,
      );
      final body = res.body;
      if (body['success'] != true) return null;
      return body;
    } catch (_) {
      return null;
    }
  }

  /// `GET /kundli/geo-lookup` — resolves city/state/place to Vedic ephemeris
  /// coordinates, mirroring the web app's client-side `lookupCityCoords`.
  Future<GeoLookupResult?> geoLookup({
    String? city,
    String? state,
    String? place,
  }) async {
    try {
      final res = await ApiClient.get(
        '/kundli/geo-lookup',
        query: {
          if (city != null && city.isNotEmpty) 'city': city,
          if (state != null && state.isNotEmpty) 'state': state,
          if (place != null && place.isNotEmpty) 'place': place,
        },
        auth: false,
      );
      final body = res.body;
      if (body['success'] != true) return null;
      return GeoLookupResult.fromJson(body);
    } catch (_) {
      return null;
    }
  }
}
