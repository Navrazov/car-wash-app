import '../../domain/entities/employee.dart';

class EmployeeModel extends Employee {
  const EmployeeModel({
    required super.id,
    required super.locationId,
    super.boxId,
    required super.name,
    super.phone,
    super.email,
    super.position,
    super.specialization,
    super.rating,
    super.totalReviews,
    super.isActive,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['_id'] ?? json['id'],
      locationId: json['locationId'] is String 
          ? json['locationId'] 
          : (json['locationId']?['_id'] ?? ''),
      boxId: json['boxId'] is String 
          ? json['boxId'] 
          : (json['boxId']?['_id']),
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      position: json['position'],
      specialization: json['specialization'] != null 
          ? List<String>.from(json['specialization']) 
          : [],
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}

