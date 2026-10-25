import 'package:avov_frontend/features/auth/domain/auth_repository.dart';

/// Stub de cambio de contraseña para fakes de prueba.
mixin AuthRepositoryChangePasswordStub implements AuthRepository {
  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async =>
      'Contraseña actualizada correctamente';
}
