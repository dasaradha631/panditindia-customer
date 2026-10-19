class LiveLocation {
  const LiveLocation({
    required this.success,
    this.panditName,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.timestamp,
    this.isTracking = false,
    this.trackingStatus = 'not_started',
    this.bookingStatus = '',
    this.customerLat,
    this.customerLon,
    this.distanceKm,
    this.distance,
    this.etaMinutes,
    this.eta,
    this.panditCity,
    this.customerCity,
    this.message,
  });

  final bool success;
  final String? panditName;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final String? timestamp;
  final bool isTracking;
  final String trackingStatus;
  final String bookingStatus;
  final double? customerLat;
  final double? customerLon;
  final double? distanceKm;
  final String? distance;
  final int? etaMinutes;
  final String? eta;
  final String? panditCity;
  final String? customerCity;
  final String? message;

  bool get hasPanditCoords => latitude != null && longitude != null;
  bool get hasCustomerCoords => customerLat != null && customerLon != null;
  bool get hasAnyCoords => hasPanditCoords || hasCustomerCoords;

  static double? _d(dynamic v) => v is num ? v.toDouble() : null;
  static int? _i(dynamic v) => v is num ? v.toInt() : null;

  factory LiveLocation.fromJson(Map<String, dynamic> json) {
    return LiveLocation(
      success: json['success'] == true,
      panditName: json['panditName']?.toString(),
      latitude: _d(json['latitude']),
      longitude: _d(json['longitude']),
      accuracy: _d(json['accuracy']),
      speed: _d(json['speed']),
      heading: _d(json['heading']),
      timestamp: json['timestamp']?.toString(),
      isTracking: json['isTracking'] == true,
      trackingStatus: (json['trackingStatus'] ?? 'not_started').toString(),
      bookingStatus: (json['bookingStatus'] ?? '').toString(),
      customerLat: _d(json['customerLat']),
      customerLon: _d(json['customerLon']),
      distanceKm: _d(json['distanceKm']),
      distance: json['distance']?.toString(),
      etaMinutes: _i(json['etaMinutes']),
      eta: json['eta']?.toString(),
      panditCity: json['panditCity']?.toString(),
      customerCity: json['customerCity']?.toString(),
      message: json['message']?.toString(),
    );
  }
}
