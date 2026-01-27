class Location {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? workingHours;
  final String? description;
  final double rating; // Average rating 1-5
  final int totalReviews;
  final bool isActive;
  final double? latitude;
  final double? longitude;

  const Location({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.workingHours,
    this.description,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isActive = true,
    this.latitude,
    this.longitude,
  });
}

