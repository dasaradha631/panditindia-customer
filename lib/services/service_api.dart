import '../core/config/app_config.dart';
import '../models/service_model.dart';
import 'api_service.dart';

/// Service catalogue access (PDF section 7 - services/service_api.dart).
///
/// Mock payload today, HTTP payload once `USE_MOCK_API=false`.
class ServiceApi {
  ServiceApi({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  static const List<ServiceModel> _featured = <ServiceModel>[
    ServiceModel(
      id: 'srv_satyanarayan',
      title: 'Satyanarayan Puja',
      subtitle: 'Family prosperity & blessings',
      icon: 'temple',
      priceFrom: 2100,
      duration: '2 hrs',
      category: 'Puja',
      rating: 4.9,
      reviewCount: 428,
      languages: <String>['Hindi', 'Sanskrit', 'Telugu'],
    ),
    ServiceModel(
      id: 'srv_griha_pravesh',
      title: 'Griha Pravesh',
      subtitle: 'Auspicious new home ceremony',
      icon: 'home',
      priceFrom: 3500,
      duration: '3 hrs',
      category: 'Puja',
      rating: 4.8,
      reviewCount: 261,
      languages: <String>['Hindi', 'Kannada', 'English'],
    ),
    ServiceModel(
      id: 'srv_havan',
      title: 'Navagraha Havan',
      subtitle: 'Remove planetary obstacles',
      icon: 'fire',
      priceFrom: 2600,
      duration: '90 mins',
      category: 'Havan',
      rating: 4.8,
      reviewCount: 189,
      languages: <String>['Sanskrit', 'Hindi'],
    ),
    ServiceModel(
      id: 'srv_kundali',
      title: 'Kundali Matching',
      subtitle: 'Horoscope matching for marriage',
      icon: 'stars',
      priceFrom: 1100,
      duration: '45 mins',
      category: 'Astrology',
      rating: 4.9,
      reviewCount: 512,
      languages: <String>['Hindi', 'English'],
    ),
  ];

  static const List<ServiceModel> _categories = <ServiceModel>[
    ServiceModel(id: 'cat_puja', title: 'Puja', subtitle: '12 services', icon: 'temple'),
    ServiceModel(id: 'cat_homam', title: 'Homam', subtitle: '8 services', icon: 'fire'),
    ServiceModel(id: 'cat_wedding', title: 'Wedding', subtitle: '6 services', icon: 'rings'),
    ServiceModel(id: 'cat_griha', title: 'Griha Pravesh', subtitle: '5 services', icon: 'home'),
    ServiceModel(id: 'cat_astrology', title: 'Astrology', subtitle: '9 services', icon: 'stars'),
    ServiceModel(id: 'cat_vastu', title: 'Vastu', subtitle: '4 services', icon: 'compass'),
    ServiceModel(id: 'cat_festivals', title: 'Festivals', subtitle: '7 services', icon: 'festival'),
    ServiceModel(id: 'cat_all', title: 'All Services', subtitle: '48 services', icon: 'grid'),
  ];

  Future<List<ServiceModel>> featured() async {
    if (AppConfig.useMockApi) {
      return Future<List<ServiceModel>>.delayed(
        const Duration(milliseconds: 300),
        () => _featured,
      );
    }
    final dynamic body = await _api.get('/services/featured');
    return _asList(body);
  }

  Future<List<ServiceModel>> categories() async {
    if (AppConfig.useMockApi) {
      return Future<List<ServiceModel>>.delayed(
        const Duration(milliseconds: 250),
        () => _categories,
      );
    }
    final dynamic body = await _api.get('/services/categories');
    return _asList(body);
  }

  List<ServiceModel> _asList(dynamic body) {
    final List<dynamic> items = body is Map<String, dynamic>
        ? (body['data'] as List<dynamic>? ?? <dynamic>[])
        : (body as List<dynamic>? ?? <dynamic>[]);
    return items
        .whereType<Map<String, dynamic>>()
        .map(ServiceModel.fromJson)
        .toList();
  }
}
