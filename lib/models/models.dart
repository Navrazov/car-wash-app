class Location {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? workingHours;
  final bool isActive;

  Location({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.workingHours,
    this.isActive = true,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      workingHours: json['working_hours'],
      isActive: json['is_active'] == 1,
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
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      duration: json['duration'],
      category: json['category'],
      isActive: json['is_active'] == 1,
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? carModel;
  final String? carNumber;
  final int totalVisits;
  final double totalSpent;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.carModel,
    this.carNumber,
    this.totalVisits = 0,
    this.totalSpent = 0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      carModel: json['car_model'],
      carNumber: json['car_number'],
      totalVisits: json['total_visits'] ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Booking {
  final String id;
  final String customerId;
  final String locationId;
  final String serviceId;
  final String bookingDate;
  final String bookingTime;
  final String status;
  final double totalPrice;
  final String? notes;
  final String? customerName;
  final String? locationName;
  final String? serviceName;

  Booking({
    required this.id,
    required this.customerId,
    required this.locationId,
    required this.serviceId,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    required this.totalPrice,
    this.notes,
    this.customerName,
    this.locationName,
    this.serviceName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      customerId: json['customer_id'],
      locationId: json['location_id'],
      serviceId: json['service_id'],
      bookingDate: json['booking_date'],
      bookingTime: json['booking_time'],
      status: json['status'],
      totalPrice: (json['total_price'] as num).toDouble(),
      notes: json['notes'],
      customerName: json['customer_name'],
      locationName: json['location_name'],
      serviceName: json['service_name'],
    );
  }
}

