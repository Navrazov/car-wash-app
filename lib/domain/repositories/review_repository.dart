import '../entities/review.dart';

abstract class ReviewRepository {
  Future<Review> createReview(Map<String, dynamic> data);
  Future<Review?> getReviewByBooking(String bookingId);
  Future<List<Review>> getReviewsByEmployee(String employeeId, {int limit = 10});
  Future<List<Review>> getReviewsByLocation(String locationId, {int limit = 10});
  Future<ReviewStats> getEmployeeStats(String employeeId);
  Future<ReviewStats> getLocationStats(String locationId);
}
