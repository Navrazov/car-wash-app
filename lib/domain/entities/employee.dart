class Employee {
  final String id;
  final String locationId;
  final String name;
  final String? phone;
  final String? email;
  final String? position;
  final List<String> specialization;
  final bool isActive;

  const Employee({
    required this.id,
    required this.locationId,
    required this.name,
    this.phone,
    this.email,
    this.position,
    this.specialization = const [],
    this.isActive = true,
  });

  Employee copyWith({
    String? id,
    String? locationId,
    String? name,
    String? phone,
    String? email,
    String? position,
    List<String>? specialization,
    bool? isActive,
  }) {
    return Employee(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      position: position ?? this.position,
      specialization: specialization ?? this.specialization,
      isActive: isActive ?? this.isActive,
    );
  }
}

