class User {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? carModel;
  final String? carNumber;
  final int totalVisits;
  final double totalSpent;

  User({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.carModel,
    this.carNumber,
    this.totalVisits = 0,
    this.totalSpent = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
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
}

class Location {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? workingHours;
  final String? description;
  final bool isActive;

  Location({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.workingHours,
    this.description,
    this.isActive = true,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      workingHours: json['workingHours'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class Service {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int duration;
  final String? category;
  final bool isActive;

  Service({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.duration,
    this.category,
    this.isActive = true,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      duration: json['duration'],
      category: json['category'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class Booking {
  final String id;
  final String userId;
  final String locationId;
  final String serviceId;
  final String bookingDate;
  final String bookingTime;
  final String status;
  final double totalPrice;
  final double prepaymentAmount;
  final String prepaymentStatus;
  final String? paymentId;
  final String? paymentUrl;
  final String? notes;
  final Location? location;
  final Service? service;

  Booking({
    required this.id,
    required this.userId,
    required this.locationId,
    required this.serviceId,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    required this.totalPrice,
    required this.prepaymentAmount,
    required this.prepaymentStatus,
    this.paymentId,
    this.paymentUrl,
    this.notes,
    this.location,
    this.service,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'],
      userId: json['userId'] ?? '',
      locationId: json['locationId'] is String ? json['locationId'] : (json['locationId']?['_id'] ?? ''),
      serviceId: json['serviceId'] is String ? json['serviceId'] : (json['serviceId']?['_id'] ?? ''),
      bookingDate: json['bookingDate'] ?? '',
      bookingTime: json['bookingTime'] ?? '',
      status: json['status'] ?? 'pending',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      prepaymentAmount: (json['prepaymentAmount'] as num?)?.toDouble() ?? 100,
      prepaymentStatus: json['prepaymentStatus'] ?? 'pending',
      paymentId: json['paymentId'],
      paymentUrl: json['paymentUrl'],
      notes: json['notes'],
      location: json['locationId'] is Map ? Location.fromJson(json['locationId']) : null,
      service: json['serviceId'] is Map ? Service.fromJson(json['serviceId']) : null,
    );
  }
}

