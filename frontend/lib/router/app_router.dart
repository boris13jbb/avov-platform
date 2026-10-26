import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/providers.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/vector_rebuild_screen.dart';
import '../features/audit/presentation/screens/audit_log_detail_screen.dart';
import '../features/audit/presentation/screens/audit_log_list_screen.dart';
import '../features/careers/presentation/screens/career_create_screen.dart';
import '../features/careers/presentation/screens/career_edit_screen.dart';
import '../features/careers/presentation/screens/career_list_screen.dart';
import '../features/questions/presentation/screens/question_create_screen.dart';
import '../features/questions/presentation/screens/question_edit_screen.dart';
import '../features/questions/presentation/screens/question_list_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/unauthorized_screen.dart';
import '../features/counselor/presentation/screens/counselor_dashboard_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/assignments/presentation/screens/assignment_create_screen.dart';
import '../features/assignments/presentation/screens/assignment_list_screen.dart';
import '../features/institution_admin/presentation/screens/counselor_create_screen.dart';
import '../features/institution_admin/presentation/screens/counselor_edit_screen.dart';
import '../features/institution_admin/presentation/screens/counselor_list_screen.dart';
import '../features/institution_admin/presentation/screens/institution_dashboard_screen.dart';
import '../features/observations/presentation/screens/counselor_session_review_screen.dart';
import '../features/institutions/presentation/screens/institution_create_screen.dart';
import '../features/institutions/presentation/screens/institution_edit_screen.dart';
import '../features/institutions/presentation/screens/institution_list_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/assistant/presentation/screens/assistant_chat_screen.dart';
import '../features/student/presentation/screens/student_dashboard_screen.dart';
import '../features/student/presentation/screens/student_profile_screen.dart';
import '../features/student/presentation/screens/student_results_screen.dart';
import '../features/student/presentation/screens/student_test_home_screen.dart';
import '../features/vocational/presentation/screens/vocational_result_screen.dart';
import '../features/vocational/presentation/screens/vocational_test_screen.dart';
import '../features/vocational/presentation/vocational_test_leave_guard.dart';
import '../features/students/presentation/screens/student_create_screen.dart';
import '../features/students/presentation/screens/student_detail_screen.dart';
import '../features/students/presentation/screens/student_edit_screen.dart';
import '../features/students/presentation/screens/student_list_screen.dart';
import '../features/users/presentation/screens/user_create_screen.dart';
import '../features/users/presentation/screens/user_edit_screen.dart';
import '../features/users/presentation/screens/user_list_screen.dart';
import 'auth_guard.dart';
import 'route_names.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final session = ref.watch(sessionListenableProvider);
  final guard = AuthGuard(tokenStorage: storage);
  final router = GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: session,
    redirect: guard.redirect,
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
        path: RouteNames.adminDashboard,
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.adminInstitutions,
        name: 'admin-institutions',
        builder: (context, state) => const InstitutionListScreen(),
      ),
      GoRoute(
        path: RouteNames.adminInstitutionNew,
        name: 'admin-institution-new',
        builder: (context, state) => const InstitutionCreateScreen(),
      ),
      GoRoute(
        path: RouteNames.adminStudents,
        name: 'admin-students',
        builder: (context, state) => const StudentListScreen(),
      ),
      GoRoute(
        path: RouteNames.adminStudentNew,
        name: 'admin-student-new',
        builder: (context, state) => const StudentCreateScreen(),
      ),
      GoRoute(
        path: '/admin/students/:studentId/edit',
        name: 'admin-student-edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['studentId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Estudiante no encontrado')),
            );
          }
          return StudentEditScreen(studentId: id);
        },
      ),
      GoRoute(
        path: '/admin/students/:studentId',
        name: 'admin-student-detail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['studentId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Estudiante no encontrado')),
            );
          }
          return StudentDetailScreen(studentId: id);
        },
      ),
      GoRoute(
        path: RouteNames.adminAudit,
        name: 'admin-audit',
        builder: (context, state) => const AuditLogListScreen(
          detailRouteBuilder: RouteNames.adminAuditDetail,
        ),
      ),
      GoRoute(
        path: '/admin/audit/:logId',
        name: 'admin-audit-detail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['logId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Registro no encontrado')),
            );
          }
          return AuditLogDetailScreen(logId: id);
        },
      ),
      GoRoute(
        path: RouteNames.adminAssignments,
        name: 'admin-assignments',
        builder: (context, state) => const AssignmentListScreen(),
      ),
      GoRoute(
        path: RouteNames.adminAssignmentNew,
        name: 'admin-assignment-new',
        builder: (context, state) {
          final raw = state.uri.queryParameters['studentId'];
          final studentId = raw == null ? null : int.tryParse(raw);
          return AssignmentCreateScreen(preselectedStudentId: studentId);
        },
      ),
      GoRoute(
        path: RouteNames.adminCareers,
        name: 'admin-careers',
        builder: (context, state) => const CareerListScreen(),
      ),
      GoRoute(
        path: RouteNames.adminCareerNew,
        name: 'admin-career-new',
        builder: (context, state) => const CareerCreateScreen(),
      ),
      GoRoute(
        path: '/admin/careers/:careerId',
        name: 'admin-career-edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['careerId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Carrera no encontrada')),
            );
          }
          return CareerEditScreen(careerId: id);
        },
      ),
      GoRoute(
        path: RouteNames.adminQuestions,
        name: 'admin-questions',
        builder: (context, state) => const QuestionListScreen(),
      ),
      GoRoute(
        path: RouteNames.adminQuestionNew,
        name: 'admin-question-new',
        builder: (context, state) => const QuestionCreateScreen(),
      ),
      GoRoute(
        path: '/admin/questions/:questionId',
        name: 'admin-question-edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['questionId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Pregunta no encontrada')),
            );
          }
          return QuestionEditScreen(questionId: id);
        },
      ),
      GoRoute(
        path: RouteNames.adminVectorRebuild,
        name: 'admin-vector-rebuild',
        builder: (context, state) => const VectorRebuildScreen(),
      ),
      GoRoute(
        path: RouteNames.adminUsers,
        name: 'admin-users',
        builder: (context, state) => const UserListScreen(),
      ),
      GoRoute(
        path: RouteNames.adminUserNew,
        name: 'admin-user-new',
        builder: (context, state) => const UserCreateScreen(),
      ),
      GoRoute(
        path: '/admin/users/:userId',
        name: 'admin-user-edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['userId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Usuario no encontrado')),
            );
          }
          return UserEditScreen(userId: id);
        },
      ),
      GoRoute(
        path: '/admin/institutions/:institutionId',
        name: 'admin-institution-edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['institutionId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Institución no encontrada')),
            );
          }
          return InstitutionEditScreen(institutionId: id);
        },
      ),
      GoRoute(
        path: RouteNames.institutionDashboard,
        name: 'institution-dashboard',
        builder: (context, state) => const InstitutionDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.institutionStudents,
        name: 'institution-students',
        builder: (context, state) => const StudentListScreen(),
      ),
      GoRoute(
        path: RouteNames.institutionStudentNew,
        name: 'institution-student-new',
        builder: (context, state) => const StudentCreateScreen(),
      ),
      GoRoute(
        path: '/institution/students/:studentId/edit',
        name: 'institution-student-edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['studentId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Estudiante no encontrado')),
            );
          }
          return StudentEditScreen(studentId: id);
        },
      ),
      GoRoute(
        path: '/institution/students/:studentId',
        name: 'institution-student-detail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['studentId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Estudiante no encontrado')),
            );
          }
          return StudentDetailScreen(studentId: id);
        },
      ),
      GoRoute(
        path: RouteNames.institutionCounselors,
        name: 'institution-counselors',
        builder: (context, state) => const CounselorListScreen(),
      ),
      GoRoute(
        path: RouteNames.institutionCounselorNew,
        name: 'institution-counselor-new',
        builder: (context, state) => const CounselorCreateScreen(),
      ),
      GoRoute(
        path: '/institution/counselors/:userId/edit',
        name: 'institution-counselor-edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['userId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Orientador no encontrado')),
            );
          }
          return CounselorEditScreen(userId: id);
        },
      ),
      GoRoute(
        path: RouteNames.institutionAssignments,
        name: 'institution-assignments',
        builder: (context, state) => const AssignmentListScreen(),
      ),
      GoRoute(
        path: RouteNames.institutionAssignmentNew,
        name: 'institution-assignment-new',
        builder: (context, state) {
          final raw = state.uri.queryParameters['studentId'];
          final studentId = raw == null ? null : int.tryParse(raw);
          return AssignmentCreateScreen(preselectedStudentId: studentId);
        },
      ),
      GoRoute(
        path: RouteNames.counselorDashboard,
        name: 'counselor-dashboard',
        builder: (context, state) => const CounselorDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.counselorStudents,
        name: 'counselor-students',
        builder: (context, state) => const StudentListScreen(),
      ),
      GoRoute(
        path: '/counselor/students/:studentId',
        name: 'counselor-student-detail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['studentId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Estudiante no encontrado')),
            );
          }
          return StudentDetailScreen(studentId: id);
        },
      ),
      GoRoute(
        path: '/counselor/students/:studentId/sessions/:sessionId',
        name: 'counselor-student-session-review',
        builder: (context, state) {
          final studentId = int.tryParse(state.pathParameters['studentId'] ?? '');
          final sessionId = int.tryParse(state.pathParameters['sessionId'] ?? '');
          if (studentId == null || sessionId == null) {
            return const Scaffold(
              body: Center(child: Text('Sesión no encontrada')),
            );
          }
          return CounselorSessionReviewScreen(
            studentId: studentId,
            sessionId: sessionId,
          );
        },
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
        path: RouteNames.studentTestHome,
        name: 'student-test-home',
        builder: (context, state) => const StudentTestHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.studentResults,
        name: 'student-results',
        builder: (context, state) => const StudentResultsScreen(),
      ),
      GoRoute(
        path: RouteNames.studentAssistant,
        name: 'student-assistant',
        builder: (context, state) {
          final raw = state.uri.queryParameters['sessionId'];
          final sessionId = raw == null ? null : int.tryParse(raw);
          return AssistantChatScreen(testSessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/student/test/:sessionId/result',
        name: 'student-test-result',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['sessionId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Evaluación no encontrada')),
            );
          }
          return VocationalResultScreen(sessionId: id);
        },
      ),
      GoRoute(
        path: '/student/test/:sessionId',
        name: 'student-test',
        onExit: (context, state) async {
          final id = int.tryParse(state.pathParameters['sessionId'] ?? '');
          if (id == null) {
            return true;
          }
          return VocationalTestLeaveGuard.allowLeave(id);
        },
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['sessionId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Evaluación no encontrada')),
            );
          }
          return VocationalTestScreen(sessionId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(
        child: Text('Ruta no encontrada'),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
