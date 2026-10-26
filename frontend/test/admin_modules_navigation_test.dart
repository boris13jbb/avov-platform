import 'package:avov_frontend/core/providers/providers.dart';
import 'package:avov_frontend/core/storage/secure_token_storage.dart';
import 'package:avov_frontend/features/admin/domain/user_directory_repository.dart';
import 'package:avov_frontend/features/admin/domain/vector_admin_repository.dart';
import 'package:avov_frontend/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:avov_frontend/features/admin/presentation/providers/vector_admin_provider.dart';
import 'package:avov_frontend/features/audit/domain/audit_log.dart';
import 'package:avov_frontend/features/audit/domain/audit_repository.dart';
import 'package:avov_frontend/features/audit/presentation/providers/audit_provider.dart';
import 'package:avov_frontend/features/auth/domain/auth_repository.dart';
import 'package:avov_frontend/features/auth/domain/auth_tokens.dart';
import 'package:avov_frontend/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:avov_frontend/features/careers/domain/career.dart';
import 'package:avov_frontend/features/careers/domain/career_repository.dart';
import 'package:avov_frontend/features/careers/presentation/providers/career_provider.dart';
import 'package:avov_frontend/features/institutions/domain/institution.dart';
import 'package:avov_frontend/features/institutions/domain/institution_repository.dart';
import 'package:avov_frontend/features/questions/domain/question.dart';
import 'package:avov_frontend/features/questions/domain/question_repository.dart';
import 'package:avov_frontend/features/questions/presentation/providers/question_provider.dart';
import 'package:avov_frontend/features/students/domain/managed_student.dart';
import 'package:avov_frontend/features/students/domain/student_repository.dart';
import 'package:avov_frontend/features/students/presentation/providers/students_provider.dart';
import 'package:avov_frontend/features/users/domain/managed_user.dart';
import 'package:avov_frontend/features/users/domain/user_account_repository.dart';
import 'package:avov_frontend/features/users/presentation/providers/users_provider.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_repository.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_test.dart'
    hide VocationalQuestion;
import 'package:avov_frontend/features/vocational/presentation/providers/vocational_provider.dart';
import 'package:avov_frontend/main.dart';
import 'package:avov_frontend/router/app_router.dart';
import 'package:avov_frontend/router/route_names.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    // Igual que main.dart: debe activarse antes de crear el GoRouter.
    GoRouter.optionURLReflectsImperativeAPIs = true;
  });

  tearDown(() {
    GoRouter.optionURLReflectsImperativeAPIs = false;
  });

  testWidgets('el panel abre carreras, preguntas, vector y auditoría',
      (tester) async {
    final container = await _pumpAdmin(tester);
    final router = container.read(goRouterProvider);

    expect(find.textContaining('Módulos pendientes'), findsNothing);
    expect(find.text('Gestionar carreras'), findsOneWidget);
    expect(find.text('Gestionar preguntas RIASEC'), findsOneWidget);
    expect(find.text('Reconstruir índice vectorial'), findsOneWidget);
    expect(find.text('Auditoría del sistema'), findsOneWidget);

    await tester.ensureVisible(find.text('Gestionar carreras'));
    await tester.tap(find.text('Gestionar carreras'));
    await tester.pumpAndSettle();
    expect(find.text('Carreras'), findsOneWidget);
    expect(find.byTooltip('Volver'), findsOneWidget);
    expect(router.canPop(), isTrue);
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.adminCareers,
    );

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Panel de superadministrador'), findsOneWidget);

    await tester.ensureVisible(find.text('Gestionar preguntas RIASEC'));
    await tester.tap(find.text('Gestionar preguntas RIASEC'));
    await tester.pumpAndSettle();
    expect(find.text('Preguntas RIASEC'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.adminQuestions,
    );

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Reconstruir índice vectorial'));
    await tester.tap(find.text('Reconstruir índice vectorial'));
    await tester.pumpAndSettle();
    expect(find.text('Índice vectorial'), findsOneWidget);
    expect(find.textContaining('Reconstrucción de carreras'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.adminVectorRebuild,
    );

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Auditoría del sistema'));
    await tester.tap(find.text('Auditoría del sistema'));
    await tester.pumpAndSettle();
    expect(find.text('Auditoría del sistema'), findsWidgets);
    expect(
      find.textContaining('No hay registros con los filtros actuales'),
      findsOneWidget,
    );
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.adminAudit,
    );

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Panel de superadministrador'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.adminDashboard,
    );
  });

  testWidgets('un estudiante no entra a carreras ni auditoría', (tester) async {
    final container = await _pumpRole(
      tester,
      role: 'STUDENT',
      profile: const UserProfile(
        id: 9,
        email: 'lucia@escuela.test',
        firstName: 'Lucía',
        lastName: 'Vega',
        role: 'STUDENT',
        status: 'ACTIVE',
        institutionId: 7,
      ),
    );
    final router = container.read(goRouterProvider);

    router.go(RouteNames.adminCareers);
    await tester.pumpAndSettle();
    expect(find.text('Acceso no permitido'), findsOneWidget);

    router.go(RouteNames.adminAudit);
    await tester.pumpAndSettle();
    expect(find.text('Acceso no permitido'), findsOneWidget);
    expect(find.text('Carreras'), findsNothing);
  });
}

Future<ProviderContainer> _pumpAdmin(WidgetTester tester) {
  return _pumpRole(
    tester,
    role: 'SUPER_ADMIN',
    profile: const UserProfile(
      id: 1,
      email: 'admin@escuela.test',
      firstName: 'Ana',
      lastName: 'Pérez',
      role: 'SUPER_ADMIN',
      status: 'ACTIVE',
    ),
  );
}

Future<ProviderContainer> _pumpRole(
  WidgetTester tester, {
  required String role,
  required UserProfile profile,
}) async {
  FlutterSecureStorage.setMockInitialValues(<String, String>{
    SecureTokenStorage.accessTokenKey: 'access-de-prueba',
    SecureTokenStorage.refreshTokenKey: 'refresh-de-prueba',
    SecureTokenStorage.userRoleKey: role,
  });
  final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(_Auth(profile, storage)),
      institutionRepositoryProvider.overrideWithValue(_Institutions()),
      userDirectoryRepositoryProvider.overrideWithValue(_Directory()),
      userAccountRepositoryProvider.overrideWithValue(_Users()),
      studentRepositoryProvider.overrideWithValue(_Students()),
      vocationalRepositoryProvider.overrideWithValue(_Vocational()),
      careerRepositoryProvider.overrideWithValue(_Careers()),
      questionRepositoryProvider.overrideWithValue(_Questions()),
      auditRepositoryProvider.overrideWithValue(_Audit()),
      vectorAdminRepositoryProvider.overrideWithValue(_Vector()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AvovApp()),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return container;
}

class _Auth implements AuthRepository {
  _Auth(this.profile, [this.storage]);

  final UserProfile profile;
  final SecureTokenStorage? storage;

  @override
  Future<UserProfile> currentProfile() async => profile;

  @override
  Future<UserProfile> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    await storage?.clearTokens();
  }

  @override
  Future<void> clearSession() async {
    await storage?.clearTokens();
  }
}

class _Institutions implements InstitutionRepository {
  @override
  Future<InstitutionPage> list({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    return const InstitutionPage(
      items: [
        Institution(
          id: 3,
          name: 'Colegio Norte',
          code: 'CN-01',
          province: 'Pichincha',
          city: 'Quito',
          status: 'ACTIVE',
        ),
      ],
      total: 1,
      page: 1,
      pages: 1,
    );
  }

  @override
  Future<Institution> getById(int id) => throw UnimplementedError();

  @override
  Future<Institution> create(InstitutionDraft draft) =>
      throw UnimplementedError();

  @override
  Future<Institution> update(int id, InstitutionDraft draft) =>
      throw UnimplementedError();

  @override
  Future<Institution> deactivate(int id) => throw UnimplementedError();

  @override
  Future<Institution> activate(int id) => throw UnimplementedError();
}

class _Directory implements UserDirectoryRepository {
  @override
  Future<int> count() async => 4;
}

class _Users implements UserAccountRepository {
  @override
  Future<ManagedUserPage> list(UserListQuery query) async {
    return const ManagedUserPage(items: [], total: 0, page: 1, pages: 0);
  }

  @override
  Future<ManagedUser> getById(int id) => throw UnimplementedError();

  @override
  Future<ManagedUser> create(UserDraft draft) => throw UnimplementedError();

  @override
  Future<ManagedUser> update(int id, UserDraft draft) =>
      throw UnimplementedError();

  @override
  Future<ManagedUser> updateStatus(int id, String status) =>
      throw UnimplementedError();
}

class _Students implements StudentRepository {
  @override
  Future<ManagedStudentPage> list(StudentListQuery query) async {
    return const ManagedStudentPage(items: [], total: 0, page: 1, pages: 0);
  }

  @override
  Future<ManagedStudent> getOwn() async {
    return const ManagedStudent(
      id: 4,
      userId: 9,
      institutionId: 7,
      identification: 'ID-PROPIA',
      birthDate: '2008-05-15',
      gender: 'FEMALE',
      grade: '10',
      email: 'lucia@escuela.test',
      firstName: 'Lucía',
      lastName: 'Vega',
      status: 'ACTIVE',
    );
  }

  @override
  Future<ManagedStudent> getById(int id) => throw UnimplementedError();

  @override
  Future<ManagedStudent> create(StudentDraft draft) =>
      throw UnimplementedError();

  @override
  Future<ManagedStudent> update(int id, StudentDraft draft) =>
      throw UnimplementedError();

  @override
  Future<ManagedStudent> updateStatus(int id, String status) =>
      throw UnimplementedError();
}

class _Vocational implements VocationalRepository {
  @override
  Future<VocationalSessionPage> listSessions({
    int page = 1,
    int pageSize = 20,
  }) async {
    return const VocationalSessionPage(items: [], total: 0, page: 1, pages: 0);
  }

  @override
  Future<VocationalSession> start() => throw UnimplementedError();

  @override
  Future<VocationalQuestionnaire> questions(int sessionId) =>
      throw UnimplementedError();

  @override
  Future<void> saveAnswer({
    required int sessionId,
    required int questionId,
    required int answerValue,
  }) =>
      throw UnimplementedError();

  @override
  Future<VocationalResult> finish(int sessionId) => throw UnimplementedError();

  @override
  Future<VocationalResult> result(int sessionId) => throw UnimplementedError();
}

class _Careers implements CareerRepository {
  @override
  Future<CareerPage> list({
    required int page,
    required int pageSize,
    String? search,
    String? area,
    String? status,
  }) async {
    return const CareerPage(items: [], total: 0, page: 1, pages: 0);
  }

  @override
  Future<Career> getById(int id) => throw UnimplementedError();

  @override
  Future<Career> create(CareerDraft draft) => throw UnimplementedError();

  @override
  Future<Career> update(int id, CareerDraft draft) =>
      throw UnimplementedError();

  @override
  Future<Career> deactivate(int id) => throw UnimplementedError();
}

class _Questions implements QuestionRepository {
  @override
  Future<QuestionPage> list({
    required int page,
    required int pageSize,
    String? search,
    String? categoryCode,
    String? status,
  }) async {
    return const QuestionPage(items: [], total: 0, page: 1, pages: 0);
  }

  @override
  Future<VocationalQuestion> getById(int id) => throw UnimplementedError();

  @override
  Future<List<RiasecCategoryBrief>> discoverCategories() async => const [];

  @override
  Future<VocationalQuestion> create(QuestionDraft draft) =>
      throw UnimplementedError();

  @override
  Future<VocationalQuestion> update(int id, QuestionDraft draft) =>
      throw UnimplementedError();

  @override
  Future<VocationalQuestion> updateStatus({
    required int id,
    required String status,
  }) =>
      throw UnimplementedError();
}

class _Audit implements AuditRepository {
  @override
  Future<AuditLogPage> list(AuditLogQuery query) async {
    return const AuditLogPage(
      items: [],
      total: 0,
      page: 1,
      pageSize: 20,
      pages: 0,
    );
  }

  @override
  Future<AuditLogEntry> getById(int id) => throw UnimplementedError();
}

class _Vector implements VectorAdminRepository {
  @override
  Future<RebuildCareersResult> rebuildCareersIndex() =>
      throw UnimplementedError();
}
