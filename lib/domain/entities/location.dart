class Location {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? workingHours;
  final String? description;
  final bool isActive;

  const Location({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.workingHours,
    this.description,
    this.isActive = true,
  });
}

