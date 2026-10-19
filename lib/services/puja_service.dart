import '../core/network/api_client.dart';
import '../models/ceremony.dart';

/// Ceremony catalogue backed by the production `GET /pujas` endpoint — the
/// same source the web booking flow loads (`pujaService.getAllPujas`).
class PujaService {
  /// `GET /pujas` — all active ceremonies with live offer pricing
  /// (`original_price`, `discount_price`, `discount_pct`, `offer_active`).
  Future<List<Ceremony>> getAllPujas() async {
    final res = await ApiClient.get('/pujas', auth: false);
    final data = res.data;
    if (data is! List) {
      throw ApiException('The puja service returned an invalid ceremony list.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(Ceremony.fromJson)
        .toList();
  }

  /// `GET /pujas/{id}` — a single ceremony's full record (including
  /// `long_description` and the offer validity window).
  Future<Ceremony?> getPuja(int id) async {
    final res = await ApiClient.get('/pujas/$id', auth: false);
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;
    return Ceremony.fromJson(data);
  }
}
