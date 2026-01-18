import '../../domain/entities/location.dart';

class LocationModel extends Location {
  const LocationModel({
    required super.id,
    required super.name,
    required super.address,
    super.phone,
    super.workingHours,
    super.description,
    super.isActive,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      workingHours: json['workingHours'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }
}

