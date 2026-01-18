import '../entities/user.dart';

abstract class AuthRepository {
  Future<void> sendVerificationCode(String phone);
  Future<User> verifyCode(String phone, String code);
  Future<User> getProfile();
  Future<User> updateProfile(Map<String, dynamic> data);
  Future<void> logout();
  Future<bool> isLoggedIn();
}

