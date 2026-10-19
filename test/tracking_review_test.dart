import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/core/storage/review_store.dart';
import 'package:customer_app/models/tracking.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ReviewStore tracks prompted and reviewed bookings', () async {
    expect(await ReviewStore.isPrompted(8842), isFalse);
    expect(await ReviewStore.isReviewed(8842), isFalse);

    await ReviewStore.markPrompted(8842);
    expect(await ReviewStore.isPrompted(8842), isTrue);
    expect(await ReviewStore.isReviewed(8842), isFalse);

    await ReviewStore.markReviewed(8842);
    expect(await ReviewStore.isPrompted(8842), isTrue);
    expect(await ReviewStore.isReviewed(8842), isTrue);

    expect(await ReviewStore.isPrompted(9001), isFalse);
  });

  test('LiveLocation parses the live-location payload', () {
    final d = LiveLocation.fromJson(const {
      'success': true,
      'bookingId': 8842,
      'panditName': 'Acharya Verma',
      'latitude': 17.4,
      'longitude': 78.5,
      'accuracy': 8.0,
      'speed': 6.5,
      'heading': 210.0,
      'timestamp': '2026-10-01T10:00:00Z',
      'isTracking': true,
      'trackingStatus': 'en_route',
      'bookingStatus': 'en_route',
      'customerLat': 17.38,
      'customerLon': 78.48,
      'distanceKm': 4.2,
      'distance': '4.2 km',
      'etaMinutes': 12,
      'eta': '12 min',
      'panditCity': 'Hyderabad',
      'customerCity': 'Hyderabad',
    });

    expect(d.success, isTrue);
    expect(d.panditName, 'Acharya Verma');
    expect(d.hasPanditCoords, isTrue);
    expect(d.hasCustomerCoords, isTrue);
    expect(d.hasAnyCoords, isTrue);
    expect(d.isTracking, isTrue);
    expect(d.trackingStatus, 'en_route');
    expect(d.distanceKm, 4.2);
    expect(d.etaMinutes, 12);
    expect(d.speed, 6.5);
    expect(d.latitude, 17.4);
  });

  test('LiveLocation handles the not-started response', () {
    final d = LiveLocation.fromJson(const {
      'success': true,
      'isTracking': false,
      'trackingStatus': 'not_started',
      'message': 'Journey not started',
    });

    expect(d.hasPanditCoords, isFalse);
    expect(d.hasAnyCoords, isFalse);
    expect(d.latitude, isNull);
    expect(d.isTracking, isFalse);
    expect(d.message, 'Journey not started');
  });
}
