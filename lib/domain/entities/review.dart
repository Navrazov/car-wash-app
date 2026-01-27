class Review {
  final String id;
  final String userId;
  final String? userName; // Populated user name
  final String bookingId;
  final String? employeeId;
  final String? employeeName; // Populated employee name
  final String locationId;
  final String? locationName; // Populated location name
  final int? employeeRating; // 1-5
  final int locationRating; // 1-5
  final String? employeeComment;
  final String? locationComment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    this.userName,
    required this.bookingId,
    this.employeeId,
    this.employeeName,
    required this.locationId,
    this.locationName,
    this.employeeRating,
    required this.locationRating,
    this.employeeComment,
    this.locationComment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final userIdObj = json['userId'];
    final employeeIdObj = json['employeeId'];
    final locationIdObj = json['locationId'];
    
    return Review(
      id: json['_id'] ?? json['id'] ?? '',
      userId: userIdObj is String 
          ? userIdObj 
          : (userIdObj?['_id'] ?? ''),
      userName: userIdObj is Map ? (userIdObj['name'] ?? userIdObj['phone']) : null,
      bookingId: json['bookingId'] is String 
          ? json['bookingId'] 
          : (json['bookingId']?['_id'] ?? ''),
      employeeId: employeeIdObj is String 
          ? employeeIdObj 
          : (employeeIdObj?['_id']),
      employeeName: employeeIdObj is Map ? employeeIdObj['name'] : null,
      locationId: locationIdObj is String 
          ? locationIdObj 
          : (locationIdObj?['_id'] ?? ''),
      locationName: locationIdObj is Map ? locationIdObj['name'] : null,
      employeeRating: json['employeeRating'],
      locationRating: json['locationRating'] ?? 0,
      employeeComment: json['employeeComment'],
      locationComment: json['locationComment'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'employeeRating': employeeRating,
      'locationRating': locationRating,
      'employeeComment': employeeComment,
      'locationComment': locationComment,
    };
  }
}

class ReviewStats {
  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingCounts; // rating -> count

  const ReviewStats({
    required this.totalReviews,
    required this.averageRating,
    required this.ratingCounts,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      totalReviews: json['totalReviews'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      ratingCounts: json['ratingCounts'] != null
          ? Map<int, int>.from(json['ratingCounts'])
          : {},
    );
  }
}
