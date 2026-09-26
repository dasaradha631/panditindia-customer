import '../core/config/app_config.dart';
import 'api_service.dart';

/// Payment boundary (PDF section 7 - services/payment_api.dart).
///
/// Stage 5 wires the client's payment gateway SDK here; today it only
/// exposes the contract so the booking flow can be built against it.
class PaymentApi {
  PaymentApi({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  /// Creates a backend order/session for a booking.
  Future<String> createOrder({
    required String bookingId,
    required double amount,
    String currency = 'INR',
  }) async {
    if (AppConfig.useMockApi) {
      return Future<String>.delayed(
        const Duration(milliseconds: 400),
        () => 'mock_order_${bookingId}_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    final dynamic body = await _api.post('/payments/orders', data: <String, dynamic>{
      'booking_id': bookingId,
      'amount': amount,
      'currency': currency,
    });
    if (body is Map<String, dynamic>) {
      final dynamic data = body['data'] is Map<String, dynamic>
          ? body['data']
          : body;
      if (data is Map<String, dynamic>) return '${data['order_id'] ?? ''}';
    }
    return '';
  }

  Future<bool> verifyPayment({
    required String orderId,
    required Map<String, String> payload,
  }) async {
    if (AppConfig.useMockApi) {
      return Future<bool>.delayed(const Duration(milliseconds: 300), () => true);
    }
    final dynamic body = await _api.post('/payments/verify', data: <String, dynamic>{
      'order_id': orderId,
      'payload': payload,
    });
    if (body is Map<String, dynamic>) {
      final dynamic data = body['data'] is Map<String, dynamic> ? body['data'] : body;
      if (data is Map<String, dynamic>) return data['success'] == true;
    }
    return false;
  }
}
