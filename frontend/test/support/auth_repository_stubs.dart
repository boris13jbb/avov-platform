import 'package:avov_frontend/features/auth/domain/auth_repository.dart';

/// Stubs de contraseña para fakes de prueba (cambio + recuperación).
mixin AuthRepositoryChangePasswordStub implements AuthRepository {
  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async =>
      'Contraseña actualizada correctamente';

  @override
  Future<String> forgotPassword({required String email}) async =>
      'Si el correo está registrado, recibirás instrucciones para restablecer la contraseña';

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async =>
      'Contraseña restablecida correctamente';
}
