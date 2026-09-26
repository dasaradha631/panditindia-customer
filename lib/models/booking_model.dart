/// Booking status values used across customer + pandit apps.
enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled;

  static BookingStatus fromName(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
      case 'inprogress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  String get label => switch (this) {
        BookingStatus.pending => 'Pending',
        BookingStatus.confirmed => 'Confirmed',
        BookingStatus.inProgress => 'In Progress',
        BookingStatus.completed => 'Completed',
        BookingStatus.cancelled => 'Cancelled',
      };
}

/// A customer pooja booking (PDF section 7 - models/booking_model.dart).
class BookingModel {
  const BookingModel({
    required this.id,
    required this.serviceTitle,
    required this.dateTime,
    this.panditName,
    this.status = BookingStatus.pending,
    this.address,
    this.amount,
    this.isPast = false,
  });

  final String id;
  final String serviceTitle;
  final DateTime dateTime;
  final String? panditName;
  final BookingStatus status;
  final String? address;
  final double? amount;
  final bool isPast;

  String get formattedDate {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const List<String> days = <String>[
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];
    final String day = days[dateTime.weekday - 1];
    return '$day, ${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String get formattedTime {
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final bool pm = dateTime.hour >= 12;
    final int hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    return '$hour12:$minute ${pm ? 'PM' : 'AM'}';
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: '${json['id'] ?? ''}',
        serviceTitle: '${json['service_title'] ?? ''}',
        dateTime: DateTime.parse('${json['date_time']}'),
        panditName: json['pandit_name'] as String?,
        status: BookingStatus.fromName(json['status'] as String?),
        address: json['address'] as String?,
        amount: (json['amount'] as num?)?.toDouble(),
        isPast: json['is_past'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'service_title': serviceTitle,
        'date_time': dateTime.toIso8601String(),
        'pandit_name': panditName,
        'status': status.name,
        'address': address,
        'amount': amount,
        'is_past': isPast,
      };
}
