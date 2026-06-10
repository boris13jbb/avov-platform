import 'package:go_router/go_router.dart';

import '../features/admin/presentation/screens/admin_settings_screen.dart';
import '../features/admin/presentation/screens/audit_detail_screen.dart';
import '../features/admin/presentation/screens/audit_list_screen.dart';
import '../features/admin/presentation/screens/career_detail_screen.dart';
import '../features/admin/presentation/screens/career_form_screen.dart';
import '../features/admin/presentation/screens/career_list_screen.dart';
import '../features/admin/presentation/screens/question_detail_screen.dart';
import '../features/admin/presentation/screens/question_form_screen.dart';
import '../features/admin/presentation/screens/question_list_screen.dart';
import '../features/admin/presentation/screens/vector_admin_screen.dart';
import '../features/auth/presentation/screens/change_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/maintenance_screen.dart';
import '../features/auth/presentation/screens/not_found_screen.dart';
import '../features/auth/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/screens/unauthorized_screen.dart';
import '../features/dashboard/presentation/screens/counselor_dashboard_screen.dart';
import '../features/dashboard/presentation/screens/institution_dashboard_screen.dart';
import '../features/dashboard/presentation/screens/student_dashboard_screen.dart';
import '../features/dashboard/presentation/screens/super_admin_dashboard_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/institution_reports/presentation/screens/institution_exports_screen.dart';
import '../features/institution_reports/presentation/screens/institution_reports_screen.dart';
import '../features/institutions/presentation/screens/institution_detail_screen.dart';
import '../features/institutions/presentation/screens/institution_form_screen.dart';
import '../features/institutions/presentation/screens/institution_list_screen.dart';
import '../features/institutions/presentation/screens/institution_settings_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/users/domain/user_management_config.dart';
import '../features/users/presentation/screens/user_detail_screen.dart';
import '../features/users/presentation/screens/user_form_screen.dart';
import '../features/students/domain/student_management_config.dart';
import '../features/students/presentation/screens/student_list_screen.dart';
import '../features/students/presentation/screens/student_detail_screen.dart';
import '../features/students/presentation/screens/student_form_screen.dart';
import '../features/students/presentation/screens/student_profile_screen.dart';
import '../features/users/presentation/screens/user_list_screen.dart';
import '../features/vocational_test/presentation/screens/test_finish_screen.dart';
import '../features/vocational_test/presentation/screens/test_instructions_screen.dart';
import '../features/assistant/presentation/screens/assistant_chat_screen.dart';
import '../features/counselor/presentation/screens/counselor_observation_screen.dart';
import '../features/counselor/presentation/screens/counselor_student_results_screen.dart';
import '../features/results/presentation/screens/student_recommendations_screen.dart';
import '../features/results/presentation/screens/student_results_screen.dart';
import '../features/vocational_test/presentation/screens/test_session_screen.dart';
import 'auth_guard.dart';
import 'route_names.dart';

class AppRouter {
  static final _authGuard = AuthGuard();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    redirect: _authGuard.redirect,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.maintenance,
        name: 'maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.unauthorized,
        name: 'unauthorized',
        builder: (context, state) => const UnauthorizedScreen(),
      ),
      GoRoute(
        path: RouteNames.notFound,
        name: 'not-found',
        builder: (context, state) => NotFoundScreen(path: state.uri.toString()),
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.changePassword,
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        name: 'admin-dashboard',
        builder: (context, state) => const SuperAdminDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.adminInstitutions,
        name: 'admin-institutions',
        builder: (context, state) => const InstitutionListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            name: 'admin-institution-new',
            builder: (context, state) => const InstitutionFormScreen(),
          ),
          GoRoute(
            path: ':id',
            name: 'admin-institution-detail',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return InstitutionDetailScreen(institutionId: id);
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: 'admin-institution-edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return InstitutionFormScreen(institutionId: id);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.adminUsers,
        name: 'admin-users',
        builder: (context, state) => const UserListScreen(
          config: UserManagementConfig.superAdmin,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'admin-user-new',
            builder: (context, state) => const UserFormScreen(
              config: UserManagementConfig.superAdmin,
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'admin-user-detail',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return UserDetailScreen(
                config: UserManagementConfig.superAdmin,
                userId: id,
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: 'admin-user-edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return UserFormScreen(
                    config: UserManagementConfig.superAdmin,
                    userId: id,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.adminCareers,
        name: 'admin-careers',
        builder: (context, state) => const CareerListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            name: 'admin-career-new',
            builder: (context, state) => const CareerFormScreen(),
          ),
          GoRoute(
            path: ':id',
            name: 'admin-career-detail',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CareerDetailScreen(careerId: id);
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: 'admin-career-edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return CareerFormScreen(careerId: id);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.adminQuestions,
        name: 'admin-questions',
        builder: (context, state) => const QuestionListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            name: 'admin-question-new',
            builder: (context, state) => const QuestionFormScreen(),
          ),
          GoRoute(
            path: ':id',
            name: 'admin-question-detail',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return QuestionDetailScreen(questionId: id);
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: 'admin-question-edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return QuestionFormScreen(questionId: id);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.adminVector,
        name: 'admin-vector',
        builder: (context, state) => const VectorAdminScreen(),
      ),
      GoRoute(
        path: RouteNames.adminAudit,
        name: 'admin-audit',
        builder: (context, state) => const AuditListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'admin-audit-detail',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return AuditDetailScreen(logId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.adminSettings,
        name: 'admin-settings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.institutionDashboard,
        name: 'institution-dashboard',
        builder: (context, state) => const InstitutionDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.institutionCounselors,
        name: 'institution-counselors',
        builder: (context, state) => const UserListScreen(
          config: UserManagementConfig.institutionCounselors,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'institution-counselor-new',
            builder: (context, state) => const UserFormScreen(
              config: UserManagementConfig.institutionCounselors,
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'institution-counselor-detail',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return UserDetailScreen(
                config: UserManagementConfig.institutionCounselors,
                userId: id,
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: 'institution-counselor-edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return UserFormScreen(
                    config: UserManagementConfig.institutionCounselors,
                    userId: id,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.institutionStudents,
        name: 'institution-students',
        builder: (context, state) => const StudentListScreen(
          config: StudentManagementConfig.institutionAdmin,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'institution-student-new',
            builder: (context, state) => const StudentFormScreen(
              config: StudentManagementConfig.institutionAdmin,
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'institution-student-detail',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return StudentDetailScreen(
                config: StudentManagementConfig.institutionAdmin,
                studentId: id,
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: 'institution-student-edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return StudentFormScreen(
                    config: StudentManagementConfig.institutionAdmin,
                    studentId: id,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.institutionReports,
        name: 'institution-reports',
        builder: (context, state) => const InstitutionReportsScreen(),
      ),
      GoRoute(
        path: RouteNames.institutionExports,
        name: 'institution-exports',
        builder: (context, state) => const InstitutionExportsScreen(),
      ),
      GoRoute(
        path: RouteNames.institutionSettings,
        name: 'institution-settings',
        builder: (context, state) => const InstitutionSettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.counselorDashboard,
        name: 'counselor-dashboard',
        builder: (context, state) => const CounselorDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.counselorStudents,
        name: 'counselor-students',
        builder: (context, state) => const StudentListScreen(
          config: StudentManagementConfig.counselor,
        ),
        routes: [
          GoRoute(
            path: ':id/results',
            name: 'counselor-student-results',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CounselorStudentResultsScreen(studentId: id);
            },
          ),
          GoRoute(
            path: ':id/observation',
            name: 'counselor-student-observation',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CounselorObservationScreen(studentId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.studentDashboard,
        name: 'student-dashboard',
        builder: (context, state) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.studentProfile,
        name: 'student-profile',
        builder: (context, state) => const StudentProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.studentTestInstructions,
        name: 'student-test-instructions',
        builder: (context, state) {
          final continueTest =
              state.uri.queryParameters['continue'] == 'true';
          return TestInstructionsScreen(continueTest: continueTest);
        },
      ),
      GoRoute(
        path: '/student/test/session/:id',
        name: 'student-test-session',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return TestSessionScreen(sessionId: id);
        },
      ),
      GoRoute(
        path: '/student/test/finish/:id',
        name: 'student-test-finish',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return TestFinishScreen(sessionId: id);
        },
      ),
      GoRoute(
        path: RouteNames.studentResults,
        name: 'student-results',
        builder: (context, state) => const StudentResultsScreen(),
      ),
      GoRoute(
        path: RouteNames.studentRecommendations,
        name: 'student-recommendations',
        builder: (context, state) => const StudentRecommendationsScreen(),
      ),
      GoRoute(
        path: RouteNames.studentAssistant,
        name: 'student-assistant',
        builder: (context, state) => const AssistantChatScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(path: state.uri.toString()),
  );
}
