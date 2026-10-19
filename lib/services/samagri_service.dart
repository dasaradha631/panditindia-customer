import '../core/network/api_client.dart';

class SamagriService {
  Future<List<Map<String, dynamic>>?> getOrders() async {
    try {
      final res = await ApiClient.get('/samagri/orders');
      final body = res.body;
      if (body['success'] != true) return null;
      final orders = body['orders'];
      if (orders is! List) return null;
      return orders.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return null;
    }
  }

  /// `POST /samagri/order` — web `samagriService.createOrder(orderPayload)`
  /// (UserDashboardPage.jsx `handleConfirmSamagriOrder`): delivery address,
  /// ISO date, optional notes, itemized cart and grand total.
  Future<bool> createOrder({
    required String deliveryAddress,
    required String deliveryDate,
    String? specialNotes,
    required List<Map<String, dynamic>> items,
    required num totalPrice,
  }) async {
    try {
      final res = await ApiClient.post(
        '/samagri/order',
        body: <String, dynamic>{
          'delivery_address': deliveryAddress,
          'delivery_date': deliveryDate,
          if ((specialNotes ?? '').trim().isNotEmpty)
            'special_notes': specialNotes!.trim(),
          'items': items,
          'total_price': totalPrice,
        },
      );
      final body = res.body;
      return body['success'] == true || body['order_id'] != null;
    } catch (_) {
      return false;
    }
  }
}
