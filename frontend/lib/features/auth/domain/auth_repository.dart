import 'auth_tokens.dart';

abstract class AuthRepository {
  Future<UserProfile> login({
    required String email,
    required String password,
  });

  Future<UserProfile> currentProfile();

  Future<void> logout();

  Future<void> clearSession();
}
