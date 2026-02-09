import '../entities/user.dart';
import '../entities/car.dart';

abstract class AuthRepository {
  Future<void> sendVerificationCode(String phone);
  Future<User> verifyCode(String phone, String code);
  Future<User> getProfile();
  Future<User> updateProfile(Map<String, dynamic> data);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<List<Car>> addCar(Map<String, dynamic> data);
  Future<List<Car>> updateCar(String carId, Map<String, dynamic> data);
  Future<List<Car>> deleteCar(String carId);
  Future<List<Car>> setDefaultCar(String carId);
  Future<List<Map<String, dynamic>>> getCarBrands();
  Future<List<String>> getCarModels(String brand);
}

