import '../../../../core/models/managed_user.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepository {
  UserRepository({required UserRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  final UserRemoteDatasource _remoteDatasource;

  Future<PaginatedUsers> listUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? role,
    int? institutionId,
    String? status,
  }) {
    return _remoteDatasource.listUsers(
      page: page,
      pageSize: pageSize,
      search: search,
      role: role,
      institutionId: institutionId,
      status: status,
    );
  }

  Future<ManagedUser> getUser(int id) => _remoteDatasource.getUser(id);

  Future<ManagedUser> createUser(ManagedUser user, {required String password}) =>
      _remoteDatasource.createUser(user.toCreateJson(password: password));

  Future<ManagedUser> updateUser(ManagedUser user) =>
      _remoteDatasource.updateUser(user.id, user.toUpdateJson());

  Future<ManagedUser> updateUserStatus(int id, String status) =>
      _remoteDatasource.updateUserStatus(id, status);
}
