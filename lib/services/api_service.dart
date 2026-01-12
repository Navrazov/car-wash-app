import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Измените на IP вашего компьютера для работы с реальным устройством
  static const String baseUrl = 'http://localhost:3001/api';

  Future<List<Location>> getLocations() async {
    final response = await http.get(Uri.parse('$baseUrl/locations'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Location.fromJson(json)).toList();
    }
    throw Exception('Ошибка загрузки локаций');
  }

  Future<List<Service>> getServices() async {
    final response = await http.get(Uri.parse('$baseUrl/services'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Service.fromJson(json)).toList();
    }
    throw Exception('Ошибка загрузки услуг');
  }

  Future<List<Booking>> getBookings(String customerId) async {
    final response = await http.get(Uri.parse('$baseUrl/bookings'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => Booking.fromJson(json))
          .where((b) => b.customerId == customerId)
          .toList();
    }
    throw Exception('Ошибка загрузки бронирований');
  }

  Future<Customer?> getCustomerByPhone(String phone) async {
    final response = await http.get(Uri.parse('$baseUrl/customers'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final customers = data.map((json) => Customer.fromJson(json)).toList();
      try {
        return customers.firstWhere((c) => c.phone == phone);
      } catch (e) {
        return null;
      }
    }
    throw Exception('Ошибка поиска клиента');
  }

  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return Customer.fromJson(json.decode(response.body));
    }
    throw Exception('Ошибка создания клиента');
  }

  Future<Booking> createBooking(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return Booking.fromJson(json.decode(response.body));
    }
    throw Exception('Ошибка создания бронирования');
  }
}

