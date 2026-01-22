import 'location.dart';
import 'service.dart';

class Booking {
  final String id;
  final String userId;
  final String locationId;
  final String serviceId;
  final DateTime bookingDate;
  final String bookingTime;
  final String status;
  final double totalPrice;
  final double prepaymentAmount;
  final String prepaymentStatus;
  final String? paymentId;
  final String? paymentUrl;
  final String? notes;
  final Location? location;
  final Service? service;

  const Booking({
    required this.id,
    required this.userId,
    required this.locationId,
    required this.serviceId,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    required this.totalPrice,
    required this.prepaymentAmount,
    required this.prepaymentStatus,
    this.paymentId,
    this.paymentUrl,
    this.notes,
    this.location,
    this.service,
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
    DateTime? bookingDate,
    String? bookingTime,
    String? status,
    double? totalPrice,
    double? prepaymentAmount,
    String? prepaymentStatus,
    String? paymentId,
    String? paymentUrl,
    String? notes,
    Location? location,
    Service? service,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      locationId: locationId ?? this.locationId,
      serviceId: serviceId ?? this.serviceId,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      prepaymentAmount: prepaymentAmount ?? this.prepaymentAmount,
      prepaymentStatus: prepaymentStatus ?? this.prepaymentStatus,
      paymentId: paymentId ?? this.paymentId,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      service: service ?? this.service,
    );
  }
}

