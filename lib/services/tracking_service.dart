import '../core/network/api_client.dart';
import '../models/booking.dart';
import '../models/tracking.dart';

class TrackingService {
  Future<LiveLocation?> getLiveLocation(dynamic id) async {
    final numeric = Booking.normalizeIdString(id);
    try {
      final res = await ApiClient.get('/api/bookings/$numeric/live-location');
      final body = res.body;
      if (body['success'] == true) return LiveLocation.fromJson(body);
      return null;
    } catch (_) {
      return null;
    }
  }
}
