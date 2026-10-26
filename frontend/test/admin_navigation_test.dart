import 'package:avov_frontend/core/providers/providers.dart';
import 'package:avov_frontend/core/storage/secure_token_storage.dart';
import 'package:avov_frontend/features/admin/domain/user_directory_repository.dart';
import 'package:avov_frontend/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:avov_frontend/features/auth/domain/auth_repository.dart';
import 'package:avov_frontend/features/auth/domain/auth_tokens.dart';
import 'package:avov_frontend/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:avov_frontend/features/institutions/domain/institution.dart';
import 'package:avov_frontend/features/institutions/domain/institution_repository.dart';
import 'package:avov_frontend/features/students/domain/managed_student.dart';
import 'package:avov_frontend/features/students/domain/student_repository.dart';
import 'package:avov_frontend/features/students/presentation/providers/students_provider.dart';
import 'package:avov_frontend/features/users/domain/managed_user.dart';
import 'package:avov_frontend/features/users/domain/user_account_repository.dart';
import 'package:avov_frontend/features/users/presentation/providers/users_provider.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_repository.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_test.dart';
import 'package:avov_frontend/features/vocational/presentation/providers/vocational_provider.dart';
import 'package:avov_frontend/main.dart';
import 'package:avov_frontend/router/app_navigation.dart';
import 'package:avov_frontend/router/app_router.dart';
import 'package:avov_frontend/router/route_names.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  testWidgets('Instituciones muestra Volver y regresa al panel admin',
      (tester) async {
    final container = await _pumpAdmin(tester);
    final router = container.read(goRouterProvider);

    expect(find.text('Panel de superadministrador'), findsOneWidget);
    expect(find.byTooltip('Volver'), findsNothing);

    await tester.tap(find.text('Gestionar instituciones'));
    await tester.pumpAndSettle();

    expect(find.text('Instituciones'), findsOneWidget);
    expect(find.byTooltip('Volver'), findsOneWidget);
    expect(router.canPop(), isTrue);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(find.text('Panel de superadministrador'), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      RouteNames.adminDashboard,
    );
  });

  testWidgets('Atrás del sistema desde Instituciones no cierra la app',
      (tester) async {
    final container = await _pumpAdmin(tester);
    final router = container.read(goRouterProvider);

    await tester.tap(find.text('Gestionar instituciones'));
    await tester.pumpAndSettle();
    expect(find.text('Instituciones'), findsOneWidget);

    await _systemBack(tester);
    await tester.pumpAndSettle();

    expect(find.text('Panel de superadministrador'), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      RouteNames.adminDashboard,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin historial, Volver usa el panel del rol', (tester) async {
    final container = await _pumpAdmin(tester);
    final router = container.read(goRouterProvider);

    router.go(RouteNames.adminInstitutions);
    await tester.pumpAndSettle();
    expect(find.text('Instituciones'), findsOneWidget);
    expect(router.canPop(), isFalse);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(find.text('Panel de superadministrador'), findsOneWidget);
  });

  testWidgets('Atrás del sistema sin historial vuelve al panel', (tester) async {
    final container = await _pumpAdmin(tester);
    container.read(goRouterProvider).go(RouteNames.adminInstitutions);
    await tester.pumpAndSettle();

    await _systemBack(tester);
    await tester.pumpAndSettle();

    expect(find.text('Panel de superadministrador'), findsOneWidget);
  });

  testWidgets('en el panel raíz Atrás pide confirmación y no sale al cancelar',
      (tester) async {
    await _pumpAdmin(tester);
    expect(find.text('Panel de superadministrador'), findsOneWidget);

    await _systemBack(tester);
    await tester.pumpAndSettle();

    expect(find.text('Salir de AVOV'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Panel de superadministrador'), findsOneWidget);
    expect(find.text('Salir de AVOV'), findsNothing);
  });

  testWidgets('open no apila de nuevo si ya estás en Instituciones',
      (tester) async {
    final container = await _pumpAdmin(tester);
    final router = container.read(goRouterProvider);

    await tester.tap(find.text('Gestionar instituciones'));
    await tester.pumpAndSettle();
    final afterFirst = _stackDepth(router);

    final context = tester.element(find.byTooltip('Volver'));
    AppNavigation.open(context, RouteNames.adminInstitutions);
    await tester.pumpAndSettle();

    expect(_stackDepth(router), afterFirst);
    expect(find.text('Instituciones'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Panel de superadministrador'), findsOneWidget);
  });
  testWidgets('sin sesión no se puede entrar a Instituciones', (tester) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(_Auth(_adminProfile)),
        institutionRepositoryProvider.overrideWithValue(_Institutions()),
        userDirectoryRepositoryProvider.overrideWithValue(_Directory()),
        userAccountRepositoryProvider.overrideWithValue(_Users()),
        studentRepositoryProvider.overrideWithValue(_Students()),
        vocationalRepositoryProvider.overrideWithValue(_Vocational()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AvovApp()),
    );
    await tester.pump();
    container.read(goRouterProvider).go(RouteNames.adminInstitutions);
    await tester.pumpAndSettle();

    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Instituciones'), findsNothing);
  });

  testWidgets('un estudiante no recupera Instituciones con Atrás',
      (tester) async {
    final container = await _pumpRole(tester, role: 'STUDENT', profile: _studentProfile);
    final router = container.read(goRouterProvider);

    expect(find.text('Panel del estudiante'), findsOneWidget);
    router.go(RouteNames.adminInstitutions);
    await tester.pumpAndSettle();

    expect(find.text('Acceso no permitido'), findsOneWidget);
    expect(find.text('Instituciones'), findsNothing);
  });
}

Future<void> _systemBack(WidgetTester tester) async {
  final dispatcher = tester.binding.defaultBinaryMessenger;
  await dispatcher.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(
      const MethodCall('popRoute'),
    ),
    (_) {},
  );
}

int _stackDepth(GoRouter router) {
  return router.routerDelegate.currentConfiguration.matches.length;
}

Future<ProviderContainer> _pumpAdmin(WidgetTester tester) {
  return _pumpRole(tester, role: 'SUPER_ADMIN', profile: _adminProfile);
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

const _adminProfile = UserProfile(
  id: 1,
  email: 'admin@escuela.test',
  firstName: 'Ana',
  lastName: 'Pérez',
  role: 'SUPER_ADMIN',
  status: 'ACTIVE',
);

const _studentProfile = UserProfile(
  id: 9,
  email: 'lucia@escuela.test',
  firstName: 'Lucía',
  lastName: 'Vega',
  role: 'STUDENT',
  status: 'ACTIVE',
  institutionId: 7,
);

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
