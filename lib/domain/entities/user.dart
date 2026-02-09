import 'car.dart';

class User {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? carModel;
  final String? carNumber;
  final List<Car> cars;
  final int totalVisits;
  final double totalSpent;
  final int rating;

  const User({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.carModel,
    this.carNumber,
    this.cars = const [],
    this.totalVisits = 0,
    this.totalSpent = 0,
    this.rating = 100,
  });

  User copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? carModel,
    String? carNumber,
    List<Car>? cars,
    int? totalVisits,
    double? totalSpent,
    int? rating,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      carModel: carModel ?? this.carModel,
      carNumber: carNumber ?? this.carNumber,
      cars: cars ?? this.cars,
      totalVisits: totalVisits ?? this.totalVisits,
      totalSpent: totalSpent ?? this.totalSpent,
      rating: rating ?? this.rating,
    );
  }

  Car? get defaultCar => cars.isEmpty ? null : cars.firstWhere(
    (c) => c.isDefault,
    orElse: () => cars.first,
  );
}

