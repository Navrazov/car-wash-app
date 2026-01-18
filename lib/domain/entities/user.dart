class User {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? carModel;
  final String? carNumber;
  final int totalVisits;
  final double totalSpent;

  const User({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.carModel,
    this.carNumber,
    this.totalVisits = 0,
    this.totalSpent = 0,
  });

  User copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? carModel,
    String? carNumber,
    int? totalVisits,
    double? totalSpent,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      carModel: carModel ?? this.carModel,
      carNumber: carNumber ?? this.carNumber,
      totalVisits: totalVisits ?? this.totalVisits,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }
}

