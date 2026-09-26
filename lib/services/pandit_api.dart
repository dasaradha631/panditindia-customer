import '../core/config/app_config.dart';
import '../models/pandit_model.dart';
import 'api_service.dart';

/// Featured / searchable pandit directory (PDF section 7 - pandit_api.dart).
class PanditApi {
  PanditApi({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  static const List<PanditModel> _featured = <PanditModel>[
    PanditModel(
      id: 'pd_201',
      name: 'Acharya Ramesh Sharma',
      speciality: 'Griha Pravesh & Satyanarayan',
      experienceYears: 18,
      languages: <String>['Hindi', 'Telugu', 'Sanskrit'],
      rating: 4.9,
      reviewCount: 312,
      city: 'Hyderabad',
    ),
    PanditModel(
      id: 'pd_202',
      name: 'Pandit Srinivas Iyengar',
      speciality: 'Vivah & Naming Ceremonies',
      experienceYears: 24,
      languages: <String>['Tamil', 'Sanskrit', 'English'],
      rating: 4.8,
      reviewCount: 274,
      city: 'Hyderabad',
    ),
    PanditModel(
      id: 'pd_203',
      name: 'Acharya Kavya Mishra',
      speciality: 'Navagraha Havan & Astrology',
      experienceYears: 12,
      languages: <String>['Hindi', 'English'],
      rating: 4.9,
      reviewCount: 158,
      city: 'Secunderabad',
    ),
  ];

  Future<List<PanditModel>> featured() async {
    if (AppConfig.useMockApi) {
      return Future<List<PanditModel>>.delayed(
        const Duration(milliseconds: 300),
        () => _featured,
      );
    }
    final dynamic body = await _api.get('/pandits/featured');
    final List<dynamic> items = body is Map<String, dynamic>
        ? (body['data'] as List<dynamic>? ?? <dynamic>[])
        : (body as List<dynamic>? ?? <dynamic>[]);
    return items
        .whereType<Map<String, dynamic>>()
        .map(PanditModel.fromJson)
        .toList();
  }
}
