class RouteNames {
  RouteNames._();

  static const splash = '/';
  static const login = '/login';
  static const home = '/inicio';
  static const changePassword = '/change-password';
  static const profile = '/profile';
  static const unauthorized = '/unauthorized';
  static const notFound = '/not-found';

  static const adminPrefix = '/admin';
  static const adminDashboard = '/admin/dashboard';
  static const adminInstitutions = '/admin/institutions';
  static const adminInstitutionNew = '/admin/institutions/new';

  static String adminInstitutionEdit(int id) => '/admin/institutions/$id';
  static const adminUsers = '/admin/users';
  static const adminUserNew = '/admin/users/new';

  static String adminUserEdit(int id) => '/admin/users/$id';
  static const adminStudents = '/admin/students';
  static const adminStudentNew = '/admin/students/new';

  static String adminStudentDetail(int id) => '/admin/students/$id';

  static String adminStudentEdit(int id) => '/admin/students/$id/edit';

  static const institutionPrefix = '/institution';
  static const institutionDashboard = '/institution/dashboard';
  static const institutionStudents = '/institution/students';
  static const institutionStudentNew = '/institution/students/new';

  static String institutionStudentDetail(int id) => '/institution/students/$id';

  static String institutionStudentEdit(int id) => '/institution/students/$id/edit';
  static const institutionCounselors = '/institution/counselors';
  static const institutionCounselorNew = '/institution/counselors/new';

  static String institutionCounselorEdit(int id) =>
      '/institution/counselors/$id/edit';
  static const counselorPrefix = '/counselor';
  static const counselorDashboard = '/counselor/dashboard';
  static const counselorStudents = '/counselor/students';

  static String counselorStudentDetail(int id) => '/counselor/students/$id';
  static const studentPrefix = '/student';
  static const studentDashboard = '/student/dashboard';
  static const studentProfile = '/student/profile';

  static String studentTest(int sessionId) => '/student/test/$sessionId';

  static String studentTestResult(int sessionId) => '/student/test/$sessionId/result';
}

/// Rutas del módulo de estudiantes según el rol que ya devolvió el backend.
class StudentAreaRoutes {
  const StudentAreaRoutes({
    required this.list,
    required this.create,
    required this.detail,
    required this.edit,
  });

  final String list;
  final String create;
  final String Function(int id) detail;
  final String Function(int id) edit;

  static StudentAreaRoutes? forRole(String? role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return const StudentAreaRoutes(
          list: RouteNames.adminStudents,
          create: RouteNames.adminStudentNew,
          detail: RouteNames.adminStudentDetail,
          edit: RouteNames.adminStudentEdit,
        );
      case 'INSTITUTION_ADMIN':
        return const StudentAreaRoutes(
          list: RouteNames.institutionStudents,
          create: RouteNames.institutionStudentNew,
          detail: RouteNames.institutionStudentDetail,
          edit: RouteNames.institutionStudentEdit,
        );
      case 'COUNSELOR':
        return const StudentAreaRoutes(
          list: RouteNames.counselorStudents,
          create: RouteNames.counselorStudents,
          detail: RouteNames.counselorStudentDetail,
          edit: RouteNames.counselorStudentDetail,
        );
      default:
        return null;
    }
  }
}
