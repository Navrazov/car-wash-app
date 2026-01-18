class Service {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int duration;
  final String? category;
  final bool isActive;

  const Service({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.duration,
    this.category,
    this.isActive = true,
  });
}

