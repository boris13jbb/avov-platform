import '../../../../core/models/user_profile.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepository {
  AuthRepository({
    required AuthRemoteDatasource remoteDatasource,
    required SecureTokenStorage tokenStorage,
  })  : _remoteDatasource = remoteDatasource,
        _tokenStorage = tokenStorage;

  final AuthRemoteDatasource _remoteDatasource;
  final SecureTokenStorage _tokenStorage;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final tokens = await _remoteDatasource.login(
      email: email,
      password: password,
    );

    final accessToken = tokens['access_token'] as String?;
    final refreshToken = tokens['refresh_token'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw Exception('Tokens de autenticación incompletos');
    }

    await _tokenStorage.saveAccessToken(accessToken);
    await _tokenStorage.saveRefreshToken(refreshToken);

    final profile = await getCurrentUser();
    await _tokenStorage.saveUserRole(profile.role.apiValue);
  }

  Future<UserProfile> getCurrentUser() async {
    final data = await _remoteDatasource.getMe();
    return UserProfile.fromJson(data);
  }

  Future<String?> getStoredRole() => _tokenStorage.getUserRole();

  Future<void> logout() => _tokenStorage.clearTokens();

  Future<String> requestPasswordReset(String email) =>
      _remoteDatasource.requestPasswordReset(email: email);

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _remoteDatasource.resetPassword(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _remoteDatasource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
