import '../../../router/route_names.dart';

enum StudentManagementScope {
  institutionAdmin,
  counselor,
}

class StudentManagementConfig {
  const StudentManagementConfig(this.scope);

  final StudentManagementScope scope;

  static const institutionAdmin =
      StudentManagementConfig(StudentManagementScope.institutionAdmin);

  static const counselor =
      StudentManagementConfig(StudentManagementScope.counselor);

  String get listTitle => scope == StudentManagementScope.counselor
      ? 'Estudiantes asignados'
      : 'Estudiantes';

  String get newTitle => 'Nuevo estudiante';
  String get editTitle => 'Editar estudiante';

  String get detailTitle => scope == StudentManagementScope.counselor
      ? 'Resultado vocacional'
      : 'Perfil estudiante';

  String get listRoute => scope == StudentManagementScope.counselor
      ? RouteNames.counselorStudents
      : RouteNames.institutionStudents;

  String newRoute() => RouteNames.institutionStudentNew;

  String detailRoute(int id) => scope == StudentManagementScope.counselor
      ? RouteNames.counselorStudentResults(id)
      : RouteNames.institutionStudentDetail(id);

  String editRoute(int id) => RouteNames.institutionStudentEdit(id);

  String observationRoute(int id) => RouteNames.counselorStudentObservation(id);

  bool get canCreate => scope == StudentManagementScope.institutionAdmin;
  bool get canEdit => scope == StudentManagementScope.institutionAdmin;
  bool get canChangeStatus => scope == StudentManagementScope.institutionAdmin;
  bool get canAssignCounselor => scope == StudentManagementScope.institutionAdmin;
  bool get showInstitutionFilter => false;
}
