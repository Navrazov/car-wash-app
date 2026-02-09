import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/car.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SecureStorage _storage;

  AuthRepositoryImpl({
    ApiClient? apiClient,
    SecureStorage? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorage();

  @override
  Future<void> sendVerificationCode(String phone) async {
    await _apiClient.post(
      '/auth/send-code',
      body: {'phone': phone},
      auth: false,
    );
  }

  @override
  Future<User> verifyCode(String phone, String code) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/verify-code',
      body: {'phone': phone, 'code': code},
      auth: false,
    );

    await _storage.saveAccessToken(response['accessToken']);
    return UserModel.fromJson(response['user']);
  }

  @override
  Future<User> getProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/auth/profile');
    return UserModel.fromJson(response);
  }

  @override
  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/auth/profile',
      body: data,
    );
    return UserModel.fromJson(response['user']);
  }

  @override
  Future<void> logout() async {
    await _storage.clearTokens();
  }

  @override
  Future<bool> isLoggedIn() async {
    return _storage.hasToken();
  }

  @override
  Future<List<Car>> addCar(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/cars',
      body: data,
    );
    return (response['cars'] as List).map((c) => Car.fromJson(c)).toList();
  }

  @override
  Future<List<Car>> updateCar(String carId, Map<String, dynamic> data) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/auth/cars/$carId',
      body: data,
    );
    return (response['cars'] as List).map((c) => Car.fromJson(c)).toList();
  }

  @override
  Future<List<Car>> deleteCar(String carId) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      '/auth/cars/$carId',
    );
    return (response['cars'] as List).map((c) => Car.fromJson(c)).toList();
  }

  @override
  Future<List<Car>> setDefaultCar(String carId) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/auth/cars/$carId/default',
      body: {},
    );
    return (response['cars'] as List).map((c) => Car.fromJson(c)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getCarBrands() async {
    final response = await _apiClient.get('/public/car-brands', auth: false);
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Future<List<String>> getCarModels(String brand) async {
    final encoded = Uri.encodeComponent(brand);
    final response = await _apiClient.get('/public/car-brands/$encoded/models', auth: false);
    if (response is List) {
      return response.cast<String>();
    }
    return [];
  }
}

