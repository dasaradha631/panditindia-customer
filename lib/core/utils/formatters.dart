/// Display helpers shared across features.
class Formatters {
  Formatters._();

  static const String countryCode = '+91';

  /// 9876543210 -> `+91 98765 43210`
  static String mobile(String value) {
    final String digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length != 10) return value;
    return '$countryCode ${digits.substring(0, 5)} ${digits.substring(5)}';
  }

  /// Raw digits out of any user input (strips the country code).
  static String digitsOnly(String value) {
    String digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    return digits;
  }

  static String initials(String name) {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  static String amount(double value) => '₹${value.toStringAsFixed(0)}';
}
