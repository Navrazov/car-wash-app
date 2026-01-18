class Box {
  final String id;
  final String locationId;
  final String name;
  final int number;
  final String? description;
  final bool isActive;

  Box({
    required this.id,
    required this.locationId,
    required this.name,
    required this.number,
    this.description,
    this.isActive = true,
  });

  factory Box.fromJson(Map<String, dynamic> json) {
    return Box(
      id: json['_id'] ?? json['id'] ?? '',
      locationId: json['locationId'] is String 
          ? json['locationId'] 
          : (json['locationId']?['_id'] ?? ''),
      name: json['name'] ?? '',
      number: json['number'] ?? 0,
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'locationId': locationId,
      'name': name,
      'number': number,
      'description': description,
      'isActive': isActive,
    };
  }
}

class BoxStatus {
  final String boxId;
  final String name;
  final int number;
  final bool isOccupied;
  final BoxCurrentBooking? currentBooking;
  final BoxNextBooking? nextBooking;

  BoxStatus({
    required this.boxId,
    required this.name,
    required this.number,
    required this.isOccupied,
    this.currentBooking,
    this.nextBooking,
  });

  factory BoxStatus.fromJson(Map<String, dynamic> json) {
    return BoxStatus(
      boxId: json['boxId'] ?? '',
      name: json['name'] ?? '',
      number: json['number'] ?? 0,
      isOccupied: json['isOccupied'] ?? false,
      currentBooking: json['currentBooking'] != null
          ? BoxCurrentBooking.fromJson(json['currentBooking'])
          : null,
      nextBooking: json['nextBooking'] != null
          ? BoxNextBooking.fromJson(json['nextBooking'])
          : null,
    );
  }
}

class BoxCurrentBooking {
  final String id;
  final String serviceName;
  final String customerName;
  final String startTime;
  final String endTime;

  BoxCurrentBooking({
    required this.id,
    required this.serviceName,
    required this.customerName,
    required this.startTime,
    required this.endTime,
  });

  factory BoxCurrentBooking.fromJson(Map<String, dynamic> json) {
    return BoxCurrentBooking(
      id: json['id'] ?? '',
      serviceName: json['serviceName'] ?? '',
      customerName: json['customerName'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }
}

class BoxNextBooking {
  final String id;
  final String startTime;

  BoxNextBooking({
    required this.id,
    required this.startTime,
  });

  factory BoxNextBooking.fromJson(Map<String, dynamic> json) {
    return BoxNextBooking(
      id: json['id'] ?? '',
      startTime: json['startTime'] ?? '',
    );
  }
}

