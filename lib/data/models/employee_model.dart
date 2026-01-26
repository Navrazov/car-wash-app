import '../../domain/entities/employee.dart';

class EmployeeModel extends Employee {
  const EmployeeModel({
    required super.id,
    required super.locationId,
    required super.name,
    super.phone,
    super.email,
    super.position,
    super.specialization,
    super.isActive,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['_id'] ?? json['id'],
      locationId: json['locationId'] is String 
          ? json['locationId'] 
          : (json['locationId']?['_id'] ?? ''),
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      position: json['position'],
      specialization: json['specialization'] != null 
          ? List<String>.from(json['specialization']) 
          : [],
      isActive: json['isActive'] ?? true,
    );
  }
}

