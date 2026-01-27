class Employee {
  final String id;
  final String locationId;
  final String? boxId;
  final String name;
  final String? phone;
  final String? email;
  final String? position;
  final List<String> specialization;
  final double rating; // Average rating 1-5
  final int totalReviews;
  final bool isActive;

  const Employee({
    required this.id,
    required this.locationId,
    this.boxId,
    required this.name,
    this.phone,
    this.email,
    this.position,
    this.specialization = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isActive = true,
  });

  Employee copyWith({
    String? id,
    String? locationId,
    String? boxId,
    String? name,
    String? phone,
    String? email,
    String? position,
    List<String>? specialization,
    double? rating,
    int? totalReviews,
    bool? isActive,
  }) {
    return Employee(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      boxId: boxId ?? this.boxId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      position: position ?? this.position,
      specialization: specialization ?? this.specialization,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isActive: isActive ?? this.isActive,
    );
  }
}

