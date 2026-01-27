import '../../core/network/api_client.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ApiClient _apiClient;

  ReviewRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Review> createReview(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/public/reviews',
      body: data,
    );
    return Review.fromJson(response);
  }

  @override
  Future<Review?> getReviewByBooking(String bookingId) async {
    try {
      final response = await _apiClient.get('/public/reviews/booking/$bookingId');
      return response != null ? Review.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Review>> getReviewsByEmployee(String employeeId, {int limit = 10}) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/public/reviews/employee/$employeeId?limit=$limit',
      auth: false,
    );
    return response.map((json) => Review.fromJson(json)).toList();
  }

  @override
  Future<List<Review>> getReviewsByLocation(String locationId, {int limit = 10}) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/public/reviews/location/$locationId?limit=$limit',
      auth: false,
    );
    return response.map((json) => Review.fromJson(json)).toList();
  }

  @override
  Future<ReviewStats> getEmployeeStats(String employeeId) async {
    final response = await _apiClient.get(
      '/public/reviews/employee/$employeeId/stats',
      auth: false,
    );
    return ReviewStats.fromJson(response);
  }

  @override
  Future<ReviewStats> getLocationStats(String locationId) async {
    final response = await _apiClient.get(
      '/public/reviews/location/$locationId/stats',
      auth: false,
    );
    return ReviewStats.fromJson(response);
  }
}
