class Car {
  final String? id;
  final String brand;
  final String model;
  final String plateNumber;
  final int? year;
  final bool isDefault;

  const Car({
    this.id,
    required this.brand,
    required this.model,
    required this.plateNumber,
    this.year,
    this.isDefault = false,
  });

  Car copyWith({
    String? id,
    String? brand,
    String? model,
    String? plateNumber,
    int? year,
    bool? isDefault,
  }) {
    return Car(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      plateNumber: plateNumber ?? this.plateNumber,
      year: year ?? this.year,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['_id'] ?? json['id'],
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      year: json['year'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      'plateNumber': plateNumber,
      if (year != null) 'year': year,
    };
  }

  String get displayName => '$brand $model';
}
