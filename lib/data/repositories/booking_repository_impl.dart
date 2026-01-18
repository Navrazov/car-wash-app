import '../../core/network/api_client.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final ApiClient _apiClient;

  BookingRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Booking>> getBookings() async {
    final response = await _apiClient.get<List<dynamic>>('/bookings');
    return response.map((json) => BookingModel.fromJson(json)).toList();
  }

  @override
  Future<Booking> getBookingById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/bookings/$id');
    return BookingModel.fromJson(response);
  }

  @override
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    return _apiClient.post<Map<String, dynamic>>('/bookings', body: data);
  }

  @override
  Future<void> cancelBooking(String id, String reason) async {
    await _apiClient.post('/bookings/$id/cancel', body: {'reason': reason});
  }

  @override
  Future<Map<String, dynamic>> checkPaymentStatus(String id) async {
    return _apiClient.get<Map<String, dynamic>>('/bookings/$id/payment-status');
  }

  @override
  Future<Map<String, dynamic>> getAvailableSlots(String locationId, String date) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/bookings/available-slots?locationId=$locationId&date=$date',
    );
  }
}

