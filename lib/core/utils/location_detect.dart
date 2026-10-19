import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// GPS fix plus the reverse-geocoded address pieces it resolved.
class DetectedLocation {
  const DetectedLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.pincode,
    this.addressLine,
  });

  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? pincode;
  final String? addressLine;
}

/// Acquires the device GPS fix and reverse geocodes it (Nominatim) into
/// city / state / pincode / street — the customer-app mirror of the pandit
/// app's "Detect My Current GPS Location". Every failure path explains
/// itself with a toast; returns null so callers keep whatever the user
/// already typed.
Future<DetectedLocation?> detectCurrentLocation(
  BuildContext context, {
  String title = 'Detect My Location',
}) async {
  Future<DetectedLocation?> fail(String message) async {
    if (context.mounted) {
      showAppToast(
        context,
        message,
        type: ToastType.error,
        title: title,
      );
    }
    return null;
  }

  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return fail('Location services are disabled. Please enable GPS.');
  }
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied) {
    return fail('Location permission denied. Please allow GPS access.');
  }
  if (perm == LocationPermission.deniedForever) {
    return fail(
      'Location permission permanently denied. Enable it in app settings.',
    );
  }

  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    final geo = await _reverseGeocode(pos.latitude, pos.longitude);
    if (!context.mounted) return null;
    if (geo == null) {
      return await fail(
        'GPS fix captured (${pos.latitude.toStringAsFixed(4)}, '
        '${pos.longitude.toStringAsFixed(4)}) but the address lookup failed. '
        'Check your internet and try again.',
      );
    }
    return geo;
  } catch (_) {
    return await fail('Unable to detect your location. Please try again.');
  }
}

Future<DetectedLocation?> _reverseGeocode(double lat, double lon) async {
  try {
    // Web parity (`StepDevotee.handleDetectLocation`): same zoom/layer so
    // the address payload matches what the web booking form receives.
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2'
      '&lat=$lat&lon=$lon&zoom=18&layer=address',
    );
    final res = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'PanditIndiaApp/1.0 (https://panditindia.com)',
          },
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) return null;
    final address = body['address'];
    if (address is! Map) return null;

    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = address[k]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }

    final city = pick(const [
      'city', 'town', 'village', 'municipality', 'suburb', 'county',
    ]);
    final state = pick(const ['state', 'state_district', 'region', 'province']);
    final displayName = body['display_name']?.toString().trim() ?? '';

    // Web parity: Nominatim frequently omits `address.postcode` in India
    // while the 6-digit PIN still sits inside `display_name` — extract it
    // with the same \b\d{6}\b rule the web booking form applies, so the
    // pincode field is never left blank after a successful detection.
    final pinRegex = RegExp(r'\b\d{6}\b');
    final rawPost = pick(const ['postcode', 'postal_code']);
    String? pincode;
    if (rawPost != null && pinRegex.hasMatch(rawPost)) {
      pincode = pinRegex.firstMatch(rawPost)?.group(0);
    }
    pincode ??= pinRegex.firstMatch(displayName)?.group(0);

    // Web parity (`StepDevotee.handleDetectLocation`): the venue address is
    // the full reverse-geocoded display name with the exact GPS fix appended,
    // e.g. "NH565, Variguntapadu, …, Andhra Pradesh, 524227, India
    // (Exact GPS: 14.99960000, 79.41970000)". City / state / pincode are
    // still surfaced as their own fields.
    final String? addressLine = displayName.isEmpty
        ? null
        : '$displayName (Exact GPS: '
            '${lat.toStringAsFixed(8)}, ${lon.toStringAsFixed(8)})';

    if ((city ?? '').isEmpty &&
        (state ?? '').isEmpty &&
        (pincode ?? '').isEmpty &&
        (addressLine ?? '').isEmpty) {
      return null;
    }
    return DetectedLocation(
      latitude: lat,
      longitude: lon,
      city: city,
      state: state,
      pincode: pincode,
      addressLine: addressLine,
    );
  } catch (_) {
    return null;
  }
}

/// Compact outlined "Detect My Location" action shared by every address
/// form (ceremony address, saved addresses, profile). Manages its own
/// busy state and hands the resolved location to [onDetected].
class DetectLocationButton extends StatefulWidget {
  const DetectLocationButton({
    super.key,
    required this.onDetected,
    this.title = 'Detect My Location',
  });

  final ValueChanged<DetectedLocation> onDetected;
  final String title;

  @override
  State<DetectLocationButton> createState() => _DetectLocationButtonState();
}

class _DetectLocationButtonState extends State<DetectLocationButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    final loc = await detectCurrentLocation(context, title: widget.title);
    if (!mounted) return;
    setState(() => _busy = false);
    if (loc == null) return;
    widget.onDetected(loc);
    final hasPin = (loc.pincode ?? '').isNotEmpty;
    final parts = <String>[
      if ((loc.city ?? '').isNotEmpty) 'City: ${loc.city}',
      if ((loc.state ?? '').isNotEmpty) 'State: ${loc.state}',
      if (hasPin) 'Pincode: ${loc.pincode}',
      if (!hasPin)
        'No pincode found — please enter the 6-digit pincode manually.',
    ];
    showAppToast(
      context,
      parts.join(' • '),
      type: hasPin ? ToastType.success : ToastType.warning,
      title: widget.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const ValueKey<String>('detect-location'),
        onPressed: _busy ? null : _run,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          backgroundColor: AppColors.accentLight,
          side: const BorderSide(color: AppColors.accent, width: 1.3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        icon: _busy
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            : const Icon(Icons.my_location_rounded, size: 16),
        label: Text(
          _busy ? 'Detecting location…' : widget.title,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
