import '../../domain/entities/location.dart';

class LocationModel extends Location {
  const LocationModel({
    required super.id,
    required super.name,
    required super.address,
    super.phone,
    super.workingHours,
    super.description,
    super.rating,
    super.totalReviews,
    super.isActive,
    super.latitude,
    super.longitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    // Handle coordinates from different formats
    double? latitude;
    double? longitude;
    
    if (json['coordinates'] != null) {
      latitude = json['coordinates']['latitude']?.toDouble();
      longitude = json['coordinates']['longitude']?.toDouble();
    } else {
      latitude = json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null;
      longitude = json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null;
    }

    return LocationModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      workingHours: json['workingHours'],
      description: json['description'],
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      isActive: json['isActive'] ?? true,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

