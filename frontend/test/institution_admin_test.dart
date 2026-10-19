import 'dart:async';

import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/core/errors/failure_mapper.dart';
import 'package:avov_frontend/core/providers/providers.dart';
import 'package:avov_frontend/core/storage/secure_token_storage.dart';
import 'package:avov_frontend/features/admin/domain/user_directory_repository.dart';
import 'package:avov_frontend/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:avov_frontend/features/auth/domain/auth_repository.dart';
import 'package:avov_frontend/features/auth/domain/auth_tokens.dart';
import 'package:avov_frontend/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:avov_frontend/features/institution_admin/presentation/providers/institution_dashboard_provider.dart';
import 'package:avov_frontend/features/institution_admin/presentation/screens/counselor_create_screen.dart';
import 'package:avov_frontend/features/institution_admin/presentation/screens/institution_dashboard_screen.dart';
import 'package:avov_frontend/features/institutions/domain/institution.dart';
import 'package:avov_frontend/features/institutions/domain/institution_repository.dart';
import 'package:avov_frontend/features/students/domain/managed_student.dart';
import 'package:avov_frontend/features/students/domain/student_repository.dart';
import 'package:avov_frontend/features/students/presentation/providers/students_provider.dart';
import 'package:avov_frontend/features/students/presentation/screens/student_create_screen.dart';
import 'package:avov_frontend/features/students/presentation/screens/student_list_screen.dart';
import 'package:avov_frontend/features/users/domain/managed_user.dart';
import 'package:avov_frontend/features/users/domain/user_account_repository.dart';
import 'package:avov_frontend/features/users/presentation/providers/users_provider.dart';
import 'package:avov_frontend/main.dart';
import 'package:avov_frontend/router/app_router.dart';
import 'package:avov_frontend/router/role_destination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const profile = UserProfile(
    id: 8,
    email: 'rector@escuela.test',
    firstName: 'Rosa',
    lastName: 'Lima',
    role: 'INSTITUTION_ADMIN',
    status: 'ACTIVE',
    institutionId: 7,
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('las rutas /institution quedan reservadas al administrador institucional', () {
    expect(routeMatchesRole('/institution/dashboard', 'INSTITUTION_ADMIN'), isTrue);
    expect(routeMatchesRole('/institution/students', 'INSTITUTION_ADMIN'), isTrue);
    expect(routeMatchesRole('/institution/students/new', 'SUPER_ADMIN'), isFalse);
    expect(routeMatchesRole('/institution/counselors', 'COUNSELOR'), isFalse);
    expect(routeMatchesRole('/institution/counselors/3/edit', 'STUDENT'), isFalse);
    expect(routeMatchesRole('/admin/students', 'INSTITUTION_ADMIN'), isFalse);
    expect(destinationForRole('INSTITUTION_ADMIN'), '/institution/dashboard');
    expect(destinationForRole('SUPER_ADMIN'), '/admin/dashboard');
  });

  testWidgets('el administrador institucional entra a su panel', (tester) async {
    await _pumpApp(
      tester,
      role: 'INSTITUTION_ADMIN',
      profile: profile,
      students: _Students(total: 2),
      users: _Users(total: 1),
    );

    expect(find.text('Panel de la institución'), findsOneWidget);
    expect(find.text('Rosa Lima'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Gestionar estudiantes'), findsOneWidget);
    expect(find.text('Gestionar orientadores'), findsOneWidget);
    expect(find.text('Gestionar instituciones'), findsNothing);
  });

  testWidgets('otro rol no entra a las rutas institucionales', (tester) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      SecureTokenStorage.accessTokenKey: 'access-de-prueba',
      SecureTokenStorage.refreshTokenKey: 'refresh-de-prueba',
      SecureTokenStorage.userRoleKey: 'SUPER_ADMIN',
    });
    final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(
          _Auth(
            const UserProfile(
              id: 1,
              email: 'admin@escuela.test',
              firstName: 'Ana',
              lastName: 'Pérez',
              role: 'SUPER_ADMIN',
              status: 'ACTIVE',
            ),
          ),
        ),
        studentRepositoryProvider.overrideWithValue(_Students(total: 0)),
        userAccountRepositoryProvider.overrideWithValue(_Users(total: 0)),
        institutionRepositoryProvider.overrideWithValue(_Institutions()),
        userDirectoryRepositoryProvider.overrideWithValue(_Directory()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AvovApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    container.read(goRouterProvider).go('/institution/students');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('No tienes permisos para acceder a esta sección.'),
      findsOneWidget,
    );
  });

  testWidgets('una sesión sin autenticar vuelve al login', (tester) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(_Auth(profile)),
        studentRepositoryProvider.overrideWithValue(_Students(total: 0)),
        userAccountRepositoryProvider.overrideWithValue(_Users(total: 0)),
        institutionRepositoryProvider.overrideWithValue(_Institutions()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AvovApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    container.read(goRouterProvider).go('/institution/dashboard');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Panel de la institución'), findsNothing);
  });

  testWidgets('el panel muestra carga, error, reintento y totales en cero', (tester) async {
    final auth = _PendingAuth(profile);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          studentRepositoryProvider.overrideWithValue(_Students(total: 0)),
          userAccountRepositoryProvider.overrideWithValue(_Users(total: 0)),
          institutionRepositoryProvider.overrideWithValue(_Institutions()),
        ],
        child: const MaterialApp(home: InstitutionDashboardScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    auth.finish();
    await tester.pump();
    await tester.pump();

    expect(find.text('0'), findsNWidgets(2));
    expect(find.textContaining('identificador 7'), findsOneWidget);
    expect(find.textContaining('nombre no está disponible'), findsOneWidget);

    final students = _Students(total: 3, failFirst: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_Auth(profile)),
          studentRepositoryProvider.overrideWithValue(students),
          userAccountRepositoryProvider.overrideWithValue(_Users(total: 1)),
          institutionRepositoryProvider.overrideWithValue(_Institutions()),
        ],
        child: const MaterialApp(home: InstitutionDashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(FailureMapper.connectionMessage), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(students.calls, 2);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('401 y 403 se muestran sin detalle interno', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _Auth(profile, error: UnauthorizedException()),
          ),
          studentRepositoryProvider.overrideWithValue(_Students(total: 0)),
          userAccountRepositoryProvider.overrideWithValue(_Users(total: 0)),
          institutionRepositoryProvider.overrideWithValue(_Institutions()),
        ],
        child: const MaterialApp(home: InstitutionDashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Sesión expirada o no autorizada'), findsOneWidget);
    expect(find.textContaining('token'), findsNothing);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_Auth(profile)),
          studentRepositoryProvider.overrideWithValue(
            _Students(
              total: 0,
              error: AppException(FailureMapper.forbiddenMessage, statusCode: 403),
            ),
          ),
          userAccountRepositoryProvider.overrideWithValue(_Users(total: 0)),
          institutionRepositoryProvider.overrideWithValue(_Institutions()),
        ],
        child: const MaterialApp(home: InstitutionDashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(FailureMapper.forbiddenMessage), findsOneWidget);
  });

  testWidgets('las consultas de estudiantes no envían otra institución', (tester) async {
    final students = _Students(total: 1);
    final institutions = _Institutions();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_Auth(profile)),
        studentRepositoryProvider.overrideWithValue(students),
        userAccountRepositoryProvider.overrideWithValue(_Users(total: 0)),
        institutionRepositoryProvider.overrideWithValue(institutions),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: StudentListScreen()),
      ),
    );
    container.read(studentInstitutionFilterProvider.notifier).state = 99;
    await tester.pump();
    await tester.pump();

    expect(students.queries, isNotEmpty);
    expect(students.queries.every((query) => query.institutionId == null), isTrue);
    expect(institutions.calls, 0);
    expect(find.text('Crear estudiante'), findsOneWidget);
    expect(find.byKey(const Key('student-institution-filter')), findsNothing);
  });

  testWidgets('crear estudiante usa la institución de la sesión', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final students = _Students(total: 0);
    final institutions = _Institutions();
    final router = GoRouter(
      initialLocation: '/institution/students/new',
      routes: [
        GoRoute(
          path: '/institution/students',
          builder: (context, state) => const Scaffold(body: Text('Listado institucional')),
        ),
        GoRoute(
          path: '/institution/students/new',
          builder: (context, state) => const StudentCreateScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_Auth(profile)),
          studentRepositoryProvider.overrideWithValue(students),
          institutionRepositoryProvider.overrideWithValue(institutions),
          userAccountRepositoryProvider.overrideWithValue(_Users(total: 0)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('student-institution')), findsNothing);
    expect(find.textContaining('no se puede cambiar'), findsOneWidget);
    expect(institutions.calls, 0);

    await tester.enterText(find.byKey(const Key('student-first-name')), 'Luis');
    await tester.enterText(find.byKey(const Key('student-last-name')), 'Mora');
    await tester.enterText(find.byKey(const Key('student-email')), 'luis@escuela.test');
    await tester.enterText(find.byKey(const Key('student-password')), 'Clave.Segura1');
    await tester.enterText(find.byKey(const Key('student-identification')), '1712345678');
    await tester.enterText(find.byKey(const Key('student-birth-date')), '2010-04-12');
    await tester.enterText(find.byKey(const Key('student-grade')), '10');
    await tester.ensureVisible(find.text('Guardar estudiante'));
    await tester.tap(find.text('Guardar estudiante'));
    await tester.pump();
    await tester.pump();

    expect(students.created?.institutionId, 7);
    expect(students.created?.password, 'Clave.Segura1');
    expect(find.text('Clave.Segura1'), findsNothing);
  });

  testWidgets('el alta de orientador no cambia de rol ni de institución', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final users = _SlowUsers();
    final router = GoRouter(
      initialLocation: '/institution/counselors/new',
      routes: [
        GoRoute(
          path: '/institution/counselors',
          builder: (context, state) => const Scaffold(body: Text('Orientadores')),
        ),
        GoRoute(
          path: '/institution/counselors/new',
          builder: (context, state) => const CounselorCreateScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_Auth(profile)),
          userAccountRepositoryProvider.overrideWithValue(users),
          institutionRepositoryProvider.overrideWithValue(_Institutions()),
          institutionDashboardProvider.overrideWith(
            (ref) async => const InstitutionDashboardData(
              profile: profile,
              studentTotal: 0,
              counselorTotal: 0,
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Orientador'), findsWidgets);
    expect(find.byKey(const Key('user-institution')), findsNothing);
    await tester.enterText(find.byKey(const Key('user-first-name')), 'Nora');
    await tester.enterText(find.byKey(const Key('user-last-name')), 'Sol');
    await tester.enterText(find.byKey(const Key('user-email')), 'nora@escuela.test');
    await tester.enterText(find.byKey(const Key('user-password')), 'Clave.Segura1');
    await tester.ensureVisible(find.text('Guardar orientador'));
    await tester.tap(find.text('Guardar orientador'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(users.createCalls, 1);
    users.finish();
    await tester.pump();
    await tester.pump();

    expect(users.created?.role, 'COUNSELOR');
    expect(users.created?.institutionId, 7);
    expect(users.queries.every((query) => query.institutionId == null), isTrue);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required String role,
  required UserProfile profile,
  required _Students students,
  required _Users users,
}) async {
  FlutterSecureStorage.setMockInitialValues(<String, String>{
    SecureTokenStorage.accessTokenKey: 'access-de-prueba',
    SecureTokenStorage.refreshTokenKey: 'refresh-de-prueba',
    SecureTokenStorage.userRoleKey: role,
  });
  final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(_Auth(profile)),
        studentRepositoryProvider.overrideWithValue(students),
        userAccountRepositoryProvider.overrideWithValue(users),
        institutionRepositoryProvider.overrideWithValue(_Institutions()),
        userDirectoryRepositoryProvider.overrideWithValue(_Directory()),
      ],
      child: const AvovApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
}

class _Auth implements AuthRepository {
  _Auth(this.profile, {this.error});

  final UserProfile profile;
  final AppException? error;

  @override
  Future<UserProfile> currentProfile() async {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return profile;
  }

  @override
  Future<UserProfile> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> clearSession() async {}
}

class _PendingAuth extends _Auth {
  _PendingAuth(super.profile);

  final Completer<UserProfile> _pending = Completer<UserProfile>();

  void finish() {
    if (!_pending.isCompleted) {
      _pending.complete(profile);
    }
  }

  @override
  Future<UserProfile> currentProfile() => _pending.future;
}

class _Students implements StudentRepository {
  _Students({required this.total, this.failFirst = false, this.error});

  final int total;
  final bool failFirst;
  final AppException? error;
  final List<StudentListQuery> queries = [];
  StudentDraft? created;
  int calls = 0;

  @override
  Future<ManagedStudentPage> list(StudentListQuery query) async {
    calls += 1;
    queries.add(query);
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    if (failFirst && calls == 1) {
      throw NetworkException(FailureMapper.connectionMessage);
    }
    return ManagedStudentPage(
      items: const [],
      total: total,
      page: query.page,
      pages: total == 0 ? 0 : 1,
    );
  }

  @override
  Future<ManagedStudent> getById(int id) {
    throw UnimplementedError();
  }

  @override
  Future<ManagedStudent> create(StudentDraft draft) async {
    created = draft;
    return ManagedStudent(
      id: 1,
      userId: 2,
      institutionId: draft.institutionId,
      identification: draft.identification,
      birthDate: draft.birthDate,
      gender: draft.gender,
      grade: draft.grade,
      email: draft.email,
      firstName: draft.firstName,
      lastName: draft.lastName,
      status: draft.status,
    );
  }

  @override
  Future<ManagedStudent> update(int id, StudentDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<ManagedStudent> updateStatus(int id, String status) {
    throw UnimplementedError();
  }
}

class _Users implements UserAccountRepository {
  _Users({required this.total});

  final int total;
  final List<UserListQuery> queries = [];
  UserDraft? created;
  int createCalls = 0;

  @override
  Future<ManagedUserPage> list(UserListQuery query) async {
    queries.add(query);
    return ManagedUserPage(
      items: const [],
      total: total,
      page: query.page,
      pages: total == 0 ? 0 : 1,
    );
  }

  @override
  Future<ManagedUser> getById(int id) {
    throw UnimplementedError();
  }

  @override
  Future<ManagedUser> create(UserDraft draft) async {
    createCalls += 1;
    created = draft;
    return ManagedUser(
      id: 4,
      email: draft.email,
      firstName: draft.firstName,
      lastName: draft.lastName,
      role: draft.role,
      status: draft.status,
      institutionId: draft.institutionId,
    );
  }

  @override
  Future<ManagedUser> update(int id, UserDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<ManagedUser> updateStatus(int id, String status) {
    throw UnimplementedError();
  }
}

class _SlowUsers extends _Users {
  _SlowUsers() : super(total: 0);

  final Completer<ManagedUser> _pending = Completer<ManagedUser>();

  void finish() {
    if (!_pending.isCompleted) {
      _pending.complete(
        const ManagedUser(
          id: 4,
          email: 'nora@escuela.test',
          firstName: 'Nora',
          lastName: 'Sol',
          role: 'COUNSELOR',
          status: 'ACTIVE',
          institutionId: 7,
        ),
      );
    }
  }

  @override
  Future<ManagedUser> create(UserDraft draft) {
    createCalls += 1;
    created = draft;
    return _pending.future;
  }
}

class _Institutions implements InstitutionRepository {
  int calls = 0;

  @override
  Future<InstitutionPage> list({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    calls += 1;
    return const InstitutionPage(items: [], total: 0, page: 1, pages: 0);
  }

  @override
  Future<Institution> getById(int id) {
    throw UnimplementedError();
  }

  @override
  Future<Institution> create(InstitutionDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<Institution> update(int id, InstitutionDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<Institution> deactivate(int id) {
    throw UnimplementedError();
  }

  @override
  Future<Institution> activate(int id) {
    throw UnimplementedError();
  }
}

class _Directory implements UserDirectoryRepository {
  @override
  Future<int> count() async => 0;
}
