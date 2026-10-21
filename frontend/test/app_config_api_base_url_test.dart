import 'package:avov_frontend/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.resolveApiBaseUrl', () {
    test('prioriza API_BASE_URL explícita (E2E aislado)', () {
      const isolated = 'http://127.0.0.1:8001/api/v1';
      expect(
        AppConfig.resolveApiBaseUrl(
          envUrl: isolated,
          isWeb: true,
          platform: TargetPlatform.windows,
        ),
        isolated,
      );
    });

    test('sin dart-define en web usa el host de desarrollo :8000', () {
      expect(
        AppConfig.resolveApiBaseUrl(
          envUrl: '',
          isWeb: true,
          platform: TargetPlatform.windows,
        ),
        'http://127.0.0.1:8000/api/v1',
      );
    });

    test('Android emulador sin dart-define usa 10.0.2.2:8000', () {
      expect(
        AppConfig.resolveApiBaseUrl(
          envUrl: '   ',
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        'http://10.0.2.2:8000/api/v1',
      );
    });
  });
}
