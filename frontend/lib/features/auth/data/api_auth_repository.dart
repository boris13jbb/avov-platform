import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_tokens.dart';
import 'auth_remote_datasource.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required Dio dio,
    required SecureTokenStorage storage,
    AuthRemoteDatasource? remote,
  })  : _remote = remote ?? AuthRemoteDatasource(dio),
        _storage = storage;

  final AuthRemoteDatasource _remote;
  final SecureTokenStorage _storage;

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final tokens = await _remote.login(email: email, password: password);
    try {
      await _storage.saveAccessToken(tokens.accessToken);
      await _storage.saveRefreshToken(tokens.refreshToken);
      final profile = await _remote.currentUser();
      await _storage.saveUserRole(profile.role);
      return profile;
    } catch (error) {
      await _storage.clearTokens();
      if (error is AppException) {
        rethrow;
      }
      throw AppException(FailureMapper.unexpectedMessage);
    }
  }

  @override
  Future<UserProfile> currentProfile() async {
    final profile = await _remote.currentUser();
    await _storage.saveUserRole(profile.role);
    return profile;
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _remote.logout(refreshToken: refreshToken);
      }
    } finally {
      await _storage.clearTokens();
    }
  }

  @override
  Future<void> clearSession() {
    return _storage.clearTokens();
  }

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _remote.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  @override
  Future<String> forgotPassword({required String email}) {
    return _remote.forgotPassword(email: email);
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _remote.resetPassword(
      token: token,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}
