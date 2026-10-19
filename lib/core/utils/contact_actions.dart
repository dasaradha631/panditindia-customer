import 'package:url_launcher/url_launcher.dart';

/// Opens the native dialer for [phone].
Future<bool> callNumber(String? phone) async {
  final raw = _clean(phone);
  if (raw.isEmpty) return false;
  try {
    return await launchUrl(Uri(scheme: 'tel', path: raw));
  } catch (_) {
    return false;
  }
}

/// Opens a WhatsApp chat for [phone] with an optional prefilled [message].
Future<bool> openWhatsApp(String? phone, {String? message}) async {
  final raw = _clean(phone);
  if (raw.isEmpty) return false;
  final text = (message ?? '').trim();
  final query = text.isEmpty ? '' : '?text=${Uri.encodeComponent(text)}';
  try {
    return await launchUrl(
      Uri.parse('https://wa.me/$raw$query'),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}

String _clean(String? value) => (value ?? '').replaceAll(RegExp(r'\D'), '');
