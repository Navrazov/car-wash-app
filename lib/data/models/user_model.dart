import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.phone,
    super.name,
    super.email,
    super.carModel,
    super.carNumber,
    super.totalVisits,
    super.totalSpent,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'],
      phone: json['phone'],
      name: json['name'],
      email: json['email'],
      carModel: json['carModel'],
      carNumber: json['carNumber'],
      totalVisits: json['totalVisits'] ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'carModel': carModel,
      'carNumber': carNumber,
    };
  }
}

