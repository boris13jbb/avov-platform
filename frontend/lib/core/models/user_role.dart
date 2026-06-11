enum UserRole {
  superAdmin('SUPER_ADMIN'),
  institutionAdmin('INSTITUTION_ADMIN'),
  counselor('COUNSELOR'),
  student('STUDENT');

  const UserRole(this.apiValue);

  final String apiValue;

  static UserRole? fromApi(String? value) {
    if (value == null) return null;
    for (final role in UserRole.values) {
      if (role.apiValue == value) return role;
    }
    return null;
  }

  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Administrador';
      case UserRole.institutionAdmin:
        return 'Administrador Institucional';
      case UserRole.counselor:
        return 'Orientador';
      case UserRole.student:
        return 'Estudiante';
    }
  }
}
