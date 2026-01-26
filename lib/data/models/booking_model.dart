import '../../domain/entities/booking.dart';
import 'location_model.dart';
import 'service_model.dart';
import 'employee_model.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.locationId,
    required super.serviceId,
    super.employeeId,
    required super.bookingDate,
    required super.bookingTime,
    required super.status,
    required super.totalPrice,
    required super.prepaymentAmount,
    required super.prepaymentStatus,
    super.paymentId,
    super.paymentUrl,
    super.notes,
    super.location,
    super.service,
    super.employee,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id'] ?? json['id'],
      userId: json['userId'] is String 
          ? json['userId'] 
          : (json['userId']?['_id'] ?? ''),
      locationId: json['locationId'] is String 
          ? json['locationId'] 
          : (json['locationId']?['_id'] ?? ''),
      serviceId: json['serviceId'] is String 
          ? json['serviceId'] 
          : (json['serviceId']?['_id'] ?? ''),
      employeeId: json['employeeId'] is String 
          ? json['employeeId'] 
          : (json['employeeId']?['_id']),
      bookingDate: DateTime.parse(json['bookingDate']),
      bookingTime: json['bookingTime'] ?? '',
      status: json['status'] ?? 'pending',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      prepaymentAmount: (json['prepaymentAmount'] as num?)?.toDouble() ?? 100,
      prepaymentStatus: json['prepaymentStatus'] ?? 'pending',
      paymentId: json['paymentId'],
      paymentUrl: json['paymentUrl'],
      notes: json['notes'],
      location: json['locationId'] is Map 
          ? LocationModel.fromJson(json['locationId']) 
          : null,
      service: json['serviceId'] is Map 
          ? ServiceModel.fromJson(json['serviceId']) 
          : null,
      employee: json['employeeId'] is Map 
          ? EmployeeModel.fromJson(json['employeeId']) 
          : null,
    );
  }
}

