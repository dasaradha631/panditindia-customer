import '../core/network/api_client.dart';
import '../models/booking.dart';

class CreateBookingResult {
  CreateBookingResult({
    required this.success,
    this.bookingId,
    this.message,
    this.raw,
  });

  final bool success;
  final int? bookingId;
  final String? message;
  final Map<String, dynamic>? raw;
}

class BookingService {
  Future<CreateBookingResult> createBooking(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await ApiClient.post('/bookings', body: payload);
      final body = res.body;
      final id = body['booking_id'] is int
          ? body['booking_id'] as int
          : int.tryParse('${body['booking_id']}');
      return CreateBookingResult(
        success: body['success'] == true,
        bookingId: id,
        message: body['message']?.toString(),
        raw: body,
      );
    } on ApiException catch (e) {
      return CreateBookingResult(success: false, message: e.message);
    }
  }

  Future<List<Booking>> getMyBookings() async {
    try {
      final res = await ApiClient.get('/bookings/my');
      final body = res.body;
      final list = body['bookings'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(Booking.fromJson)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Booking?> getBooking(dynamic id) async {
    final numeric = Booking.normalizeIdString(id);
    try {
      final res = await ApiClient.get('/bookings/$numeric', auth: false);
      final body = res.body;
      final b = body['booking'];
      if (b is Map<String, dynamic>) return Booking.fromJson(b);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> cancelBooking(dynamic id) async {
    final numeric = Booking.normalizeIdString(id);
    try {
      await ApiClient.delete('/bookings/$numeric');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> rescheduleOptions(dynamic id) async {
    final numeric = Booking.normalizeIdString(id);
    try {
      final res = await ApiClient.get('/bookings/$numeric/reschedule-options');
      return res.body;
    } catch (_) {
      return null;
    }
  }

  Future<bool> reschedule(
    dynamic id, {
    required String date,
    required String timeSlot,
  }) async {
    final numeric = Booking.normalizeIdString(id);
    try {
      final res = await ApiClient.patch(
        '/bookings/$numeric/reschedule',
        // The backend update whitelist only accepts `date` (bookings.py:2040).
        body: {'date': date, 'time_slot': timeSlot},
      );
      return res.body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> submitReview(
    dynamic id, {
    required int rating,
    String? title,
    String? text,
    bool isAnonymous = false,
  }) async {
    final numeric = Booking.normalizeIdString(id);
    try {
      final res = await ApiClient.post(
        '/bookings/$numeric/review',
        body: {
          'rating': rating,
          'review_title': title,
          'review_text': text,
          'is_anonymous': isAnonymous,
        },
      );
      if (res.body['success'] == true) return null;
      return res.body['message']?.toString() ?? 'Unable to submit the review.';
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
