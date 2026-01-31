import 'location.dart';
import 'service.dart';
import 'employee.dart';

class Booking {
  final String id;
  final String userId;
  final String locationId;
  final String serviceId;
  final String? employeeId;
  final DateTime bookingDate;
  final String bookingTime;
  final String status;
  final double totalPrice;
  final double prepaymentAmount;
  final String prepaymentStatus;
  final String? paymentId;
  final String? paymentUrl;
  final String? notes;
  final bool hasReview;
  final Location? location;
  final Service? service;
  final Employee? employee;

  const Booking({
    required this.id,
    required this.userId,
    required this.locationId,
    required this.serviceId,
    this.employeeId,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    required this.totalPrice,
    required this.prepaymentAmount,
    required this.prepaymentStatus,
    this.paymentId,
    this.paymentUrl,
    this.notes,
    this.hasReview = false,
    this.location,
    this.service,
    this.employee,
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get needsPayment => isPending && prepaymentStatus != 'paid';
  bool get canBeCancelled => !isCompleted && !isCancelled;

  Booking copyWith({
    String? id,
    String? userId,
    String? locationId,
    String? serviceId,
    String? employeeId,
    DateTime? bookingDate,
    String? bookingTime,
    String? status,
    double? totalPrice,
    double? prepaymentAmount,
    String? prepaymentStatus,
    String? paymentId,
    String? paymentUrl,
    String? notes,
    bool? hasReview,
    Location? location,
    Service? service,
    Employee? employee,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      locationId: locationId ?? this.locationId,
      serviceId: serviceId ?? this.serviceId,
      employeeId: employeeId ?? this.employeeId,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      prepaymentAmount: prepaymentAmount ?? this.prepaymentAmount,
      prepaymentStatus: prepaymentStatus ?? this.prepaymentStatus,
      paymentId: paymentId ?? this.paymentId,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      notes: notes ?? this.notes,
      hasReview: hasReview ?? this.hasReview,
      location: location ?? this.location,
      service: service ?? this.service,
      employee: employee ?? this.employee,
    );
  }
}

