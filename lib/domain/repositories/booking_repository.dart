import '../entities/booking.dart';

abstract class BookingRepository {
  Future<List<Booking>> getBookings();
  Future<Booking> getBookingById(String id);
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data);
  Future<void> cancelBooking(String id, String reason);
  Future<Map<String, dynamic>> checkPaymentStatus(String id);
  Future<Map<String, dynamic>> getAvailableSlots(String locationId, String date);
}

