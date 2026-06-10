class RouteNames {
  RouteNames._();

  static const splash = '/';
  static const login = '/login';
  static const home = '/inicio';
  static const changePassword = '/change-password';
  static const profile = '/profile';
  static const unauthorized = '/unauthorized';
  static const notFound = '/not-found';
  static const maintenance = '/maintenance';

  static const adminDashboard = '/admin/dashboard';
  static const adminInstitutions = '/admin/institutions';
  static const adminInstitutionNew = '/admin/institutions/new';

  static String adminInstitutionDetail(int id) => '/admin/institutions/$id';
  static String adminInstitutionEdit(int id) => '/admin/institutions/$id/edit';

  static const adminUsers = '/admin/users';
  static const adminUserNew = '/admin/users/new';

  static String adminUserDetail(int id) => '/admin/users/$id';
  static String adminUserEdit(int id) => '/admin/users/$id/edit';

  static const adminCareers = '/admin/careers';
  static const adminCareerNew = '/admin/careers/new';

  static String adminCareerDetail(int id) => '/admin/careers/$id';
  static String adminCareerEdit(int id) => '/admin/careers/$id/edit';

  static const adminQuestions = '/admin/questions';
  static const adminQuestionNew = '/admin/questions/new';

  static String adminQuestionDetail(int id) => '/admin/questions/$id';
  static String adminQuestionEdit(int id) => '/admin/questions/$id/edit';
  static const adminVector = '/admin/vector';
  static const adminAudit = '/admin/audit';
  static String adminAuditDetail(int id) => '/admin/audit/$id';
  static const adminSettings = '/admin/settings';

  static const institutionDashboard = '/institution/dashboard';
  static const institutionCounselors = '/institution/counselors';
  static const institutionCounselorNew = '/institution/counselors/new';

  static String institutionCounselorDetail(int id) =>
      '/institution/counselors/$id';
  static String institutionCounselorEdit(int id) =>
      '/institution/counselors/$id/edit';

  static const institutionStudents = '/institution/students';
  static const institutionStudentNew = '/institution/students/new';

  static String institutionStudentDetail(int id) =>
      '/institution/students/$id';
  static String institutionStudentEdit(int id) =>
      '/institution/students/$id/edit';

  static const institutionReports = '/institution/reports';
  static const institutionExports = '/institution/exports';
  static const institutionSettings = '/institution/settings';

  static const counselorDashboard = '/counselor/dashboard';
  static const counselorStudents = '/counselor/students';

  static String counselorStudentResults(int id) => '/counselor/students/$id/results';
  static String counselorStudentObservation(int id) =>
      '/counselor/students/$id/observation';
  static const studentDashboard = '/student/dashboard';
  static const studentProfile = '/student/profile';
  static const studentTestInstructions = '/student/test/instructions';

  static String studentTestSession(int id) => '/student/test/session/$id';
  static String studentTestFinish(int id) => '/student/test/finish/$id';
  static const studentResults = '/student/results';
  static const studentRecommendations = '/student/recommendations';
  static const studentAssistant = '/student/assistant';
}
