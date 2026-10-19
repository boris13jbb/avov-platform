import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda la sesión de AVOV en el almacén seguro de cada plataforma.
///
/// Android usa EncryptedSharedPreferences. Windows, iOS, macOS, Linux y web
/// usan las opciones predeterminadas de `flutter_secure_storage` 9.x.
/// No almacena contraseñas y no escribe tokens en registros.
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const userRoleKey = 'user_role';

  final FlutterSecureStorage _storage;

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) {
    return _storage.write(key: refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() {
    return _storage.read(key: refreshTokenKey);
  }

  Future<void> saveUserRole(String role) {
    return _storage.write(key: userRoleKey, value: role);
  }

  Future<String?> getUserRole() {
    return _storage.read(key: userRoleKey);
  }

  /// Borra solo las tres claves de AVOV. No llama a `deleteAll`.
  Future<void> clearTokens() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
    await _storage.delete(key: userRoleKey);
  }
}
