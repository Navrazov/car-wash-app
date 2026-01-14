import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  // IP адрес вашего Mac для работы с реальным устройством
  static const String baseUrl = 'http://192.168.31.26:3001/api';
  
  String? _accessToken;

  // Получение токена
  Future<String?> getToken() async {
    if (_accessToken != null) return _accessToken;
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    return _accessToken;
  }

  // Сохранение токена
  Future<void> saveToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
  }

  // Удаление токена
  Future<void> clearToken() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
  }

  // Получение headers с авторизацией
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // SMS Авторизация - отправка кода
  Future<void> sendVerificationCode(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-code'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phone': phone}),
    );
    
    if (response.statusCode == 200) {
      return;
    }
    
    final error = json.decode(response.body);
    throw Exception(error['error'] ?? 'Ошибка отправки кода');
  }

  // SMS Авторизация - проверка кода
  Future<User> verifyCode(String phone, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phone': phone, 'code': code}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await saveToken(data['accessToken']);
      return User.fromJson(data['user']);
    }
    
    final error = json.decode(response.body);
    throw Exception(error['error'] ?? 'Неверный код');
  }

  // Получение профиля
  Future<User> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    }
    
    throw Exception('Ошибка загрузки профиля');
  }

  // Обновление профиля
  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return User.fromJson(responseData['user']);
    }
    
    throw Exception('Ошибка обновления профиля');
  }

  // Получение локаций
  Future<List<Location>> getLocations() async {
    final response = await http.get(Uri.parse('$baseUrl/public/locations'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Location.fromJson(json)).toList();
    }
    throw Exception('Ошибка загрузки локаций');
  }

  // Получение услуг
  Future<List<Service>> getServices() async {
    final response = await http.get(Uri.parse('$baseUrl/public/services'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Service.fromJson(json)).toList();
    }
    throw Exception('Ошибка загрузки услуг');
  }

  // Получение доступных слотов
  Future<Map<String, dynamic>> getAvailableSlots(String locationId, String date) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/available-slots?locationId=$locationId&date=$date'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Ошибка загрузки слотов');
  }

  // Получение бронирований пользователя
  Future<List<Booking>> getBookings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Booking.fromJson(json)).toList();
    }
    throw Exception('Ошибка загрузки бронирований');
  }

  // Создание бронирования (возвращает ссылку на оплату)
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    
    final error = json.decode(response.body);
    throw Exception(error['error'] ?? 'Ошибка создания бронирования');
  }

  // Проверка статуса оплаты
  Future<Map<String, dynamic>> checkPaymentStatus(String bookingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/$bookingId/payment-status'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Ошибка проверки статуса оплаты');
  }

  // Отмена бронирования
  Future<void> cancelBooking(String bookingId, String reason) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
      headers: await _getHeaders(),
      body: json.encode({'reason': reason}),
    );
    if (response.statusCode == 200) {
      return;
    }
    final error = json.decode(response.body);
    throw Exception(error['error'] ?? 'Ошибка отмены');
  }
}

