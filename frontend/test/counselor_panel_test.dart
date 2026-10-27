import 'dart:async';

import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/core/errors/failure_mapper.dart';
import 'package:avov_frontend/core/providers/providers.dart';
import 'package:avov_frontend/core/storage/secure_token_storage.dart';
import 'package:avov_frontend/features/admin/domain/user_directory_repository.dart';
import 'package:avov_frontend/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:avov_frontend/features/auth/domain/auth_repository.dart';
import 'support/auth_repository_stubs.dart';
import 'package:avov_frontend/features/auth/domain/auth_tokens.dart';
import 'package:avov_frontend/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:avov_frontend/features/counselor/presentation/screens/counselor_dashboard_screen.dart';
import 'package:avov_frontend/features/institutions/domain/institution.dart';
import 'package:avov_frontend/features/institutions/domain/institution_repository.dart';
import 'package:avov_frontend/features/students/domain/managed_student.dart';
import 'package:avov_frontend/features/students/domain/student_repository.dart';
import 'package:avov_frontend/features/students/presentation/providers/students_provider.dart';
import 'package:avov_frontend/features/students/presentation/screens/student_detail_screen.dart';
import 'package:avov_frontend/features/students/presentation/screens/student_list_screen.dart';
import 'package:avov_frontend/main.dart';
import 'package:avov_frontend/router/app_router.dart';
import 'package:avov_frontend/router/role_destination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const profile = UserProfile(
    id: 6,
    email: 'omar@escuela.test',
    firstName: 'Omar',
    lastName: 'León',
    role: 'COUNSELOR',
    status: 'ACTIVE',
    institutionId: 7,
  );

  const student = ManagedStudent(
    id: 4,
    userId: 9,
    institutionId: 7,
    identification: '0102030405',
    birthDate: '2010-04-12',
    gender: 'FEMALE',
    grade: '10',
    email: 'lucia@escuela.test',
    firstName: 'Lucía',
    lastName: 'Vega',
    status: 'ACTIVE',
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('las rutas /counselor quedan reservadas al orientador', () {
    expect(routeMatchesRole('/counselor/dashboard', 'COUNSELOR'), isTrue);
    expect(routeMatchesRole('/counselor/students', 'COUNSELOR'), isTrue);
    expect(routeMatchesRole('/counselor/students/4', 'SUPER_ADMIN'), isFalse);
    expect(routeMatchesRole('/counselor/students', 'INSTITUTION_ADMIN'), isFalse);
    expect(routeMatchesRole('/counselor/dashboard', 'STUDENT'), isFalse);
    expect(routeMatchesRole('/admin/students', 'COUNSELOR'), isFalse);
    expect(routeMatchesRole('/institution/students', 'COUNSELOR'), isFalse);
    expect(destinationForRole('COUNSELOR'), '/counselor/dashboard');
    expect(destinationForRole('STUDENT'), '/student/dashboard');
  });

  testWidgets('el orientador entra a su panel', (tester) async {
    final students = _Students(total: 2, items: const [student]);
    await _pumpApp(tester, role: 'COUNSELOR', profile: profile, students: students);

    expect(find.text('Panel del orientador'), findsOneWidget);
    expect(find.text('Omar León'), findsOneWidget);
    expect(find.text('omar@escuela.test'), findsOneWidget);
    expect(find.textContaining('identificador 7'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Ver estudiantes asignados'), findsOneWidget);
    expect(
      find.textContaining('Desde la ficha de cada estudiante asignado'),
      findsOneWidget,
    );
    expect(find.textContaining('test RIASEC'), findsOneWidget);
    expect(find.text('Crear estudiante'), findsNothing);
    expect(find.text('Gestionar instituciones'), findsNothing);
    expect(students.queries.single.pageSize, 1);
    expect(students.queries.single.institutionId, isNull);
  });

  testWidgets('un rol administrativo no entra al espacio del orientador', (tester) async {
    final container = await _appContainer(
      tester,
      role: 'INSTITUTION_ADMIN',
      profile: const UserProfile(
        id: 8,
        email: 'rosa@escuela.test',
        firstName: 'Rosa',
        lastName: 'Lima',
        role: 'INSTITUTION_ADMIN',
        status: 'ACTIVE',
        institutionId: 7,
      ),
      students: _Students(total: 0),
    );

    container.read(goRouterProvider).go('/counselor/students');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('No tienes permisos para acceder a esta sección.'),
      findsOneWidget,
    );
  });

  testWidgets('una sesión sin autenticar vuelve al login', (tester) async {
    final container = await _appContainer(
      tester,
      role: null,
      profile: profile,
      students: _Students(total: 0),
    );
    container.read(goRouterProvider).go('/counselor/dashboard');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Panel del orientador'), findsNothing);
  });

  testWidgets('el panel muestra carga, vacío, error y reintento', (tester) async {
    final pending = _PendingStudents();
    await tester.pumpWidget(_dashboard(profile, pending));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.finish(total: 0);
    await tester.pump();
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(find.textContaining('recomendación inventada'), findsNothing);

    final failing = _Students(total: 4, failFirst: true);
    await tester.pumpWidget(_dashboard(profile, failing));
    await tester.pump();
    await tester.pump();

    expect(find.text(FailureMapper.connectionMessage), findsOneWidget);
    expect(find.text('4'), findsNothing);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(failing.calls, 2);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('401, 403 y 404 se muestran sin detalle interno', (tester) async {
    await tester.pumpWidget(
      _dashboard(
        profile,
        _Students(total: 0),
        profileError: UnauthorizedException(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Sesión expirada o no autorizada'), findsOneWidget);
    expect(find.textContaining('token'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: StudentDetailScreen(studentId: 4),
      ).withRepos(
        profile,
        _Students(
          total: 0,
          detailError: AppException(FailureMapper.forbiddenMessage, statusCode: 403),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(FailureMapper.forbiddenMessage), findsOneWidget);
    expect(find.text('Editar'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: StudentDetailScreen(studentId: 99),
      ).withRepos(
        profile,
        _Students(
          total: 0,
          detailError: AppException('Estudiante no encontrado', statusCode: 404),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Estudiante no encontrado'), findsOneWidget);
  });

  testWidgets('el listado no amplía la institución y no ofrece escritura', (tester) async {
    final students = _Students(total: 1, items: const [student]);
    final institutions = _Institutions();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_Auth(profile)),
        studentRepositoryProvider.overrideWithValue(students),
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
    await tester.pump();

    expect(students.queries, isNotEmpty);
    expect(students.queries.every((query) => query.institutionId == null), isTrue);
    expect(institutions.calls, 0);
    expect(find.text('Lucía Vega'), findsOneWidget);
    expect(find.text('Ver'), findsOneWidget);
    expect(find.text('Crear estudiante'), findsNothing);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Desactivar'), findsNothing);
  });
}

Widget _dashboard(
  UserProfile profile,
  StudentRepository students, {
  AppException? profileError,
}) {
  return const MaterialApp(home: CounselorDashboardScreen()).withRepos(
    profile,
    students,
    profileError: profileError,
  );
}

extension on Widget {
  Widget withRepos(
    UserProfile profile,
    StudentRepository students, {
    AppException? profileError,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_Auth(profile, error: profileError)),
        studentRepositoryProvider.overrideWithValue(students),
        institutionRepositoryProvider.overrideWithValue(_Institutions()),
      ],
      child: this,
    );
  }
}

Future<ProviderContainer> _appContainer(
  WidgetTester tester, {
  required String? role,
  required UserProfile profile,
  required _Students students,
}) async {
  final values = <String, String>{};
  if (role != null) {
    values[SecureTokenStorage.accessTokenKey] = 'access-de-prueba';
    values[SecureTokenStorage.refreshTokenKey] = 'refresh-de-prueba';
    values[SecureTokenStorage.userRoleKey] = role;
  }
  FlutterSecureStorage.setMockInitialValues(values);
  final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(_Auth(profile)),
      studentRepositoryProvider.overrideWithValue(students),
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
  return container;
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required String role,
  required UserProfile profile,
  required _Students students,
}) async {
  await _appContainer(tester, role: role, profile: profile, students: students);
  await tester.pump();
  await tester.pump();
}

class _Auth with AuthRepositoryChangePasswordStub implements AuthRepository {
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

class _Students implements StudentRepository {
  _Students({
    required this.total,
    this.items = const [],
    this.failFirst = false,
    this.detailError,
  });

  final int total;
  final List<ManagedStudent> items;
  final bool failFirst;
  final AppException? detailError;
  final List<StudentListQuery> queries = [];
  int calls = 0;

  @override
  Future<ManagedStudentPage> list(StudentListQuery query) async {
    calls += 1;
    queries.add(query);
    if (failFirst && calls == 1) {
      throw NetworkException(FailureMapper.connectionMessage);
    }
    return ManagedStudentPage(
      items: query.pageSize == 1 ? const [] : items,
      total: total,
      page: query.page,
      pages: total == 0 ? 0 : 1,
    );
  }

  @override
  Future<ManagedStudent> getOwn() => throw UnimplementedError();

  @override
  Future<ManagedStudent> getById(int id) async {
    final failure = detailError;
    if (failure != null) {
      throw failure;
    }
    return items.firstWhere((item) => item.id == id);
  }

  @override
  Future<ManagedStudent> create(StudentDraft draft) => throw UnimplementedError();

  @override
  Future<ManagedStudent> update(int id, StudentDraft draft) => throw UnimplementedError();

  @override
  Future<ManagedStudent> updateStatus(int id, String status) => throw UnimplementedError();
}

class _PendingStudents extends _Students {
  _PendingStudents() : super(total: 0);

  final Completer<int> _total = Completer<int>();

  void finish({required int total}) {
    if (!_total.isCompleted) {
      _total.complete(total);
    }
  }

  @override
  Future<ManagedStudentPage> list(StudentListQuery query) async {
    calls += 1;
    queries.add(query);
    final total = await _total.future;
    return ManagedStudentPage(items: const [], total: total, page: 1, pages: 0);
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
  Future<Institution> getById(int id) => throw UnimplementedError();

  @override
  Future<Institution> create(InstitutionDraft draft) => throw UnimplementedError();

  @override
  Future<Institution> update(int id, InstitutionDraft draft) => throw UnimplementedError();

  @override
  Future<Institution> deactivate(int id) => throw UnimplementedError();

  @override
  Future<Institution> activate(int id) => throw UnimplementedError();
}

class _Directory implements UserDirectoryRepository {
  @override
  Future<int> count() async => 0;
}
