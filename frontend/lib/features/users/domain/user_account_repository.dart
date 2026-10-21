import 'managed_user.dart';

/// Contrato de `/users`.
///
/// El backend no expone eliminación física ni un flujo para restablecer
/// o invitar por correo. La contraseña inicial solo viaja en la creación.
/// `avatar_url` existe en la actualización y queda fuera de este formulario.
abstract class UserAccountRepository {
  Future<ManagedUserPage> list(UserListQuery query);

  Future<ManagedUser> getById(int id);

  Future<ManagedUser> create(UserDraft draft);

  Future<ManagedUser> update(int id, UserDraft draft);

  Future<ManagedUser> updateStatus(int id, String status);
}
