import '../core/config/app_config.dart';
import '../models/booking_model.dart';
import 'api_service.dart';

/// Booking access for the customer app (PDF section 7 - booking_api.dart).
class BookingApi {
  BookingApi({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  static List<BookingModel> mockUpcoming() {
    final DateTime now = DateTime.now();
    return <BookingModel>[
      BookingModel(
        id: 'bkg_9001',
        serviceTitle: 'Satyanarayan Puja',
        dateTime: DateTime(now.year, now.month, now.day + 2, 7, 30),
        panditName: 'Acharya Ramesh Sharma',
        status: BookingStatus.confirmed,
        address: 'Flat 402, Lakeview Residency, Hyderabad',
        amount: 2100,
      ),
    ];
  }

  static List<BookingModel> mockPast() {
    final DateTime now = DateTime.now();
    return <BookingModel>[
      BookingModel(
        id: 'bkg_8874',
        serviceTitle: 'Navagraha Havan',
        dateTime: DateTime(now.year, now.month, now.day - 12, 10, 0),
        panditName: 'Acharya Kavya Mishra',
        status: BookingStatus.completed,
        amount: 2600,
        isPast: true,
      ),
      BookingModel(
        id: 'bkg_8790',
        serviceTitle: 'Kundali Matching',
        dateTime: DateTime(now.year, now.month, now.day - 30, 16, 0),
        panditName: 'Pandit Srinivas Iyengar',
        status: BookingStatus.completed,
        amount: 1100,
        isPast: true,
      ),
    ];
  }

  Future<List<BookingModel>> upcoming() async {
    if (AppConfig.useMockApi) {
      return Future<List<BookingModel>>.delayed(
        const Duration(milliseconds: 320),
        mockUpcoming,
      );
    }
    return _list(await _api.get('/bookings', query: <String, dynamic>{
      'status': 'upcoming',
    }));
  }

  Future<List<BookingModel>> past() async {
    if (AppConfig.useMockApi) {
      return Future<List<BookingModel>>.delayed(
        const Duration(milliseconds: 320),
        mockPast,
      );
    }
    return _list(await _api.get('/bookings', query: <String, dynamic>{
      'status': 'past',
    }));
  }

  List<BookingModel> _list(dynamic body) {
    final List<dynamic> items = body is Map<String, dynamic>
        ? (body['data'] as List<dynamic>? ?? <dynamic>[])
        : (body as List<dynamic>? ?? <dynamic>[]);
    return items
        .whereType<Map<String, dynamic>>()
        .map(BookingModel.fromJson)
        .toList();
  }
}
