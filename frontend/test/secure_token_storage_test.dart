import 'package:avov_frontend/core/storage/secure_token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureTokenStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    storage = SecureTokenStorage(storage: const FlutterSecureStorage());
  });

  test('guarda y recupera access token, refresh token y rol', () async {
    await storage.saveAccessToken('access-1');
    await storage.saveRefreshToken('refresh-1');
    await storage.saveUserRole('STUDENT');

    expect(await storage.getAccessToken(), 'access-1');
    expect(await storage.getRefreshToken(), 'refresh-1');
    expect(await storage.getUserRole(), 'STUDENT');
  });

  test('clearTokens borra solo las claves de AVOV', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      SecureTokenStorage.accessTokenKey: 'access-1',
      SecureTokenStorage.refreshTokenKey: 'refresh-1',
      SecureTokenStorage.userRoleKey: 'STUDENT',
      'otro_dato': 'conservar',
    });
    storage = SecureTokenStorage(storage: const FlutterSecureStorage());

    await storage.clearTokens();

    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(await storage.getUserRole(), isNull);
    expect(
      await const FlutterSecureStorage().read(key: 'otro_dato'),
      'conservar',
    );
  });
}
