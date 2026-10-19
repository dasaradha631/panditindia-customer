import 'package:shared_preferences/shared_preferences.dart';

class ReviewStore {
  ReviewStore._();

  static const String _promptedKey = 'review_prompted_ids';
  static const String _reviewedKey = 'review_reviewed_ids';

  static Future<Set<String>> _read(String key) async {
    final sp = await SharedPreferences.getInstance();
    return (sp.getStringList(key) ?? const <String>[]).toSet();
  }

  static Future<void> _write(String key, Set<String> ids) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(key, ids.toList());
  }

  static Future<bool> isPrompted(dynamic bookingId) async =>
      (await _read(_promptedKey)).contains('$bookingId');

  static Future<void> markPrompted(dynamic bookingId) async {
    final ids = await _read(_promptedKey)
      ..add('$bookingId');
    await _write(_promptedKey, ids);
  }

  static Future<bool> isReviewed(dynamic bookingId) async =>
      (await _read(_reviewedKey)).contains('$bookingId');

  static Future<void> markReviewed(dynamic bookingId) async {
    final prompted = await _read(_promptedKey)
      ..add('$bookingId');
    await _write(_promptedKey, prompted);
    final reviewed = await _read(_reviewedKey)
      ..add('$bookingId');
    await _write(_reviewedKey, reviewed);
  }
}
