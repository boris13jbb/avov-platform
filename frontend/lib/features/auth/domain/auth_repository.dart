import 'auth_tokens.dart';

abstract class AuthRepository {
  Future<UserProfile> login({
    required String email,
    required String password,
  });

  Future<UserProfile> currentProfile();

  Future<void> logout();

  Future<void> clearSession();

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<String> forgotPassword({required String email});

  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  });
}
