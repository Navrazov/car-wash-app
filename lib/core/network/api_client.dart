import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final SecureStorage _storage;
  final String _baseUrl = AppConstants.apiBaseUrl;

  ApiClient({SecureStorage? storage}) : _storage = storage ?? SecureStorage();

  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    
    if (auth) {
      final token = await _storage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  Future<T> get<T>(
    String endpoint, {
    bool auth = true,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _getHeaders(auth: auth),
    );

    return _handleResponse(response, fromJson: fromJson);
  }

  Future<T> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _getHeaders(auth: auth),
      body: body != null ? json.encode(body) : null,
    );

    return _handleResponse(response, fromJson: fromJson);
  }

  Future<T> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _getHeaders(auth: auth),
      body: body != null ? json.encode(body) : null,
    );

    return _handleResponse(response, fromJson: fromJson);
  }

  Future<T> delete<T>(
    String endpoint, {
    bool auth = true,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _getHeaders(auth: auth),
    );

    return _handleResponse(response, fromJson: fromJson);
  }

  T _handleResponse<T>(
    http.Response response, {
    T Function(dynamic)? fromJson,
  }) {
    final data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (fromJson != null) {
        return fromJson(data);
      }
      return data as T;
    }

    throw ApiException(
      data['error'] ?? 'Ошибка запроса',
      statusCode: response.statusCode,
    );
  }
}

