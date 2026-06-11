import '../../../core/models/user_role.dart';
import '../../../router/route_names.dart';

enum UserManagementScope {
  superAdmin,
  institutionCounselors,
}

class UserManagementConfig {
  const UserManagementConfig(this.scope);

  final UserManagementScope scope;

  static const superAdmin = UserManagementConfig(UserManagementScope.superAdmin);
  static const institutionCounselors =
      UserManagementConfig(UserManagementScope.institutionCounselors);

  String get listTitle {
    switch (scope) {
      case UserManagementScope.superAdmin:
        return 'Usuarios';
      case UserManagementScope.institutionCounselors:
        return 'Orientadores';
    }
  }

  String get newTitle {
    switch (scope) {
      case UserManagementScope.superAdmin:
        return 'Nuevo usuario';
      case UserManagementScope.institutionCounselors:
        return 'Nuevo orientador';
    }
  }

  String get editTitle {
    switch (scope) {
      case UserManagementScope.superAdmin:
        return 'Editar usuario';
      case UserManagementScope.institutionCounselors:
        return 'Editar orientador';
    }
  }

  String get detailTitle {
    switch (scope) {
      case UserManagementScope.superAdmin:
        return 'Detalle usuario';
      case UserManagementScope.institutionCounselors:
        return 'Detalle orientador';
    }
  }

  String get listRoute {
    switch (scope) {
      case UserManagementScope.superAdmin:
        return RouteNames.adminUsers;
      case UserManagementScope.institutionCounselors:
        return RouteNames.institutionCounselors;
    }
  }

  String newRoute() {
    switch (scope) {
      case UserManagementScope.superAdmin:
        return RouteNames.adminUserNew;
      case UserManagementScope.institutionCounselors:
        return RouteNames.institutionCounselorNew;
    }
  }

  String detailRoute(int id) {
    switch (scope) {
      case UserManagementScope.superAdmin:
        return RouteNames.adminUserDetail(id);
      case UserManagementScope.institutionCounselors:
        return RouteNames.institutionCounselorDetail(id);
    }
  }

  String editRoute(int id) {
    switch (scope) {
      case UserManagementScope.superAdmin:
        return RouteNames.adminUserEdit(id);
      case UserManagementScope.institutionCounselors:
        return RouteNames.institutionCounselorEdit(id);
    }
  }

  String? get fixedRoleFilter {
    switch (scope) {
      case UserManagementScope.superAdmin:
        return null;
      case UserManagementScope.institutionCounselors:
        return UserRole.counselor.apiValue;
    }
  }

  List<UserRole> get creatableRoles {
    switch (scope) {
      case UserManagementScope.superAdmin:
        return UserRole.values;
      case UserManagementScope.institutionCounselors:
        return const [UserRole.counselor];
    }
  }

  bool get showRoleFilter => scope == UserManagementScope.superAdmin;
  bool get showInstitutionFilter => scope == UserManagementScope.superAdmin;
  bool get showInstitutionPicker => scope == UserManagementScope.superAdmin;
}
