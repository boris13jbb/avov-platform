import 'package:flutter_test/flutter_test.dart';

import 'package:avov_frontend/core/validators/app_validators.dart';

void main() {
  group('AppValidators', () {
    test('required devuelve mensaje si está vacío', () {
      expect(AppValidators.required(''), 'Este campo es obligatorio');
      expect(AppValidators.required(null), 'Este campo es obligatorio');
      expect(AppValidators.required('texto'), isNull);
    });

    test('email valida formato', () {
      expect(AppValidators.email('correo-invalido'), isNotNull);
      expect(AppValidators.email('usuario@ejemplo.com'), isNull);
    });

    test('password valida requisitos de seguridad', () {
      expect(AppValidators.password('abc'), isNotNull);
      expect(AppValidators.password('Segura123!'), isNull);
    });
  });
}
