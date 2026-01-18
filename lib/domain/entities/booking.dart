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
}

