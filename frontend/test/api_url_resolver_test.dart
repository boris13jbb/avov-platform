import 'package:avov_frontend/core/utils/api_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiUrlResolver', () {
    const apiBaseUrl = 'http://192.168.100.140:8000/api/v1';

    test('resuelve rutas relativas de medios', () {
      expect(
        ApiUrlResolver.resolveMediaUrl(
          apiBaseUrl,
          '/api/v1/media/logos/institution_1_abcd.png',
        ),
        'http://192.168.100.140:8000/api/v1/media/logos/institution_1_abcd.png',
      );
    });

    test('reescribe localhost al origen actual de la API', () {
      expect(
        ApiUrlResolver.resolveMediaUrl(
          apiBaseUrl,
          'http://localhost:8000/api/v1/media/logos/institution_1_abcd.png',
        ),
        'http://192.168.100.140:8000/api/v1/media/logos/institution_1_abcd.png',
      );
    });

    test('reescribe 127.0.0.1 al origen actual de la API', () {
      expect(
        ApiUrlResolver.resolveMediaUrl(
          apiBaseUrl,
          'http://127.0.0.1:8000/api/v1/media/logos/institution_3_abcd.webp',
        ),
        'http://192.168.100.140:8000/api/v1/media/logos/institution_3_abcd.webp',
      );
    });

    test('conserva URLs externas', () {
      expect(
        ApiUrlResolver.resolveMediaUrl(
          apiBaseUrl,
          'https://cdn.example.com/logo.png',
        ),
        'https://cdn.example.com/logo.png',
      );
    });

    test('devuelve vacío para valores nulos o vacíos', () {
      expect(ApiUrlResolver.resolveMediaUrl(apiBaseUrl, null), '');
      expect(ApiUrlResolver.resolveMediaUrl(apiBaseUrl, ''), '');
    });
  });
}
