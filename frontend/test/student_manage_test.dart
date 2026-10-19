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
import 'package:avov_frontend/features/institutions/domain/institution.dart';
import 'package:avov_frontend/features/institutions/domain/institution_repository.dart';
import 'package:avov_frontend/features/students/domain/managed_student.dart';
import 'package:avov_frontend/features/students/domain/student_repository.dart';
import 'package:avov_frontend/features/students/presentation/providers/students_provider.dart';
import 'package:avov_frontend/features/students/presentation/screens/student_create_screen.dart';
import 'package:avov_frontend/features/students/presentation/screens/student_detail_screen.dart';
import 'package:avov_frontend/features/students/presentation/screens/student_edit_screen.dart';
import 'package:avov_frontend/features/students/presentation/screens/student_list_screen.dart';
import 'package:avov_frontend/main.dart';
import 'package:avov_frontend/router/app_router.dart';
import 'package:avov_frontend/router/route_names.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sample = ManagedStudent(
    id: 4,
    userId: 9,
    institutionId: 3,
    identification: '0102030405',
    birthDate: '2010-04-12',
    gender: 'FEMALE',
    grade: '10',
    email: 'lucia@escuela.test',
    firstName: 'Lucía',
    lastName: 'Vega',
    status: 'ACTIVE',
  );

  const operator = UserProfile(
    id: 1,
    email: 'admin@escuela.test',
    firstName: 'Ada',
    lastName: 'Admin',
    role: 'SUPER_ADMIN',
    status: 'ACTIVE',
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('401, 403 y 422 no exponen el detalle interno', () {
    expect(
      FailureMapper.fromDioException(_error(401, 'token secreto')).message,
      FailureMapper.sessionExpiredMessage,
    );
    expect(
      FailureMapper.fromDioException(_error(403, 'traza sql')).message,
      FailureMapper.forbiddenMessage,
    );
    expect(
      FailureMapper.fromDioException(_error(422, 'El correo electrónico ya está registrado'))
          .message,
      'El correo electrónico ya está registrado',
    );
  });

  testWidgets('el listado muestra nombre, correo, institución y estado', (tester) async {
    await tester.pumpWidget(_scope(students: _Students(items: const [sample])));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Lucía Vega'), findsOneWidget);
    expect(find.textContaining('lucia@escuela.test'), findsOneWidget);
    expect(find.textContaining('Colegio Norte'), findsWidgets);
    expect(find.text('Activa'), findsWidgets);
  });

  testWidgets('el listado vacío ofrece crear un estudiante', (tester) async {
    await tester.pumpWidget(_scope(students: _Students()));
    await tester.pump();
    await tester.pump();

    expect(find.text('Todavía no hay estudiantes.'), findsOneWidget);
    expect(find.text('Crear estudiante'), findsOneWidget);
  });

  testWidgets('un error de carga se puede reintentar', (tester) async {
    final students = _Students(items: const [sample], failFirstList: true);
    await tester.pumpWidget(_scope(students: students));
    await tester.pump();
    await tester.pump();

    expect(find.text(FailureMapper.connectionMessage), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(students.listCalls, 2);
    expect(find.text('Lucía Vega'), findsOneWidget);
  });

  testWidgets('la búsqueda, los filtros y la página se envían a la consulta',
      (tester) async {
    final students = _Students(items: const [sample], pages: 2);
    await tester.pumpWidget(_scope(students: students));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byKey(const Key('student-search')), 'lucia');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump();
    expect(students.lastQuery?.search, 'lucia');

    await tester.tap(find.byKey(const Key('student-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activa').last);
    await tester.pump();
    await tester.pump();
    expect(students.lastQuery?.status, 'ACTIVE');

    await tester.tap(find.byKey(const Key('student-institution-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Colegio Norte').last);
    await tester.pump();
    await tester.pump();
    expect(students.lastQuery?.institutionId, 3);

    await tester.enterText(find.byKey(const Key('student-grade-filter')), '10');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump();
    expect(students.lastQuery?.grade, '10');

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    await tester.pump();
    expect(students.lastQuery?.page, 2);
  });

  testWidgets('el formulario exige los campos obligatorios', (tester) async {
    final students = _Students();
    await tester.pumpWidget(
      _scope(students: students, home: const StudentCreateScreen()),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.text('Guardar estudiante'));
    await tester.tap(find.text('Guardar estudiante'));
    await tester.pump();

    expect(find.text('El campo nombre es obligatorio'), findsOneWidget);
    expect(find.text('El correo electrónico es obligatorio'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
    expect(find.text('El campo identificación es obligatorio'), findsOneWidget);
    expect(find.text('El campo fecha de nacimiento es obligatorio'), findsOneWidget);
    expect(find.text('El campo curso es obligatorio'), findsOneWidget);
    expect(find.text('La institución es obligatoria'), findsOneWidget);
    expect(students.createCalls, 0);
  });

  testWidgets('una creación válida vuelve al listado sin mostrar la contraseña',
      (tester) async {
    final students = _Students();
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_scope(students: students, router: router));
    await tester.pump();
    await tester.pump();

    await _fillCreateForm(tester);
    await tester.ensureVisible(find.text('Guardar estudiante'));
    await tester.tap(find.text('Guardar estudiante'));
    await tester.pumpAndSettle();

    expect(find.text('Luis Mora'), findsOneWidget);
    expect(find.text('Clave.Segura1'), findsNothing);
    expect(find.byKey(const Key('student-password')), findsNothing);
    expect(students.createdDraft?.password, 'Clave.Segura1');
    expect(students.createdDraft?.institutionId, 3);
  });

  testWidgets('un 422 de correo duplicado no se presenta como alta exitosa',
      (tester) async {
    final students = _Students(
      createError: ValidationException(
        'El correo electrónico ya está registrado',
        fieldErrors: const ['email: El correo electrónico ya está registrado'],
      ),
    );
    await tester.pumpWidget(
      _scope(students: students, home: const StudentCreateScreen()),
    );
    await tester.pump();
    await tester.pump();

    await _fillCreateForm(tester);
    await tester.ensureVisible(find.text('Guardar estudiante'));
    await tester.tap(find.text('Guardar estudiante'));
    await tester.pump();
    await tester.pump();

    expect(find.text('El correo electrónico ya está registrado'), findsWidgets);
    expect(find.text('Estudiantes'), findsNothing);
    expect(students.items, isEmpty);
  });

  testWidgets('el detalle muestra los datos y un estudiante inexistente avisa',
      (tester) async {
    await tester.pumpWidget(
      _scope(
        students: _Students(items: const [sample]),
        home: const StudentDetailScreen(studentId: 4),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Lucía Vega'), findsOneWidget);
    expect(find.textContaining('Colegio Norte'), findsOneWidget);
    expect(find.textContaining('0102030405'), findsOneWidget);

    await tester.pumpWidget(
      _scope(
        students: _Students(missing: true),
        home: const StudentDetailScreen(studentId: 99),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Estudiante no encontrado'), findsOneWidget);
  });

  testWidgets('la edición guarda el curso y no envía contraseña', (tester) async {
    final students = _Students(items: const [sample]);
    final router = GoRouter(
      initialLocation: '/admin/students/4/edit',
      routes: [
        GoRoute(
          path: RouteNames.adminStudents,
          builder: (context, state) => const StudentListScreen(),
        ),
        GoRoute(
          path: '/admin/students/:studentId/edit',
          builder: (context, state) => StudentEditScreen(
            studentId: int.parse(state.pathParameters['studentId']!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_scope(students: students, router: router));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('student-password')), findsNothing);
    await tester.enterText(find.byKey(const Key('student-grade')), '11');
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();
    await tester.pump();

    expect(students.updatedGrade, '11');
    expect(students.updatedPassword, isNull);
  });

  testWidgets('desactivar pide confirmación y no actúa si se cancela', (tester) async {
    final students = _Students(items: const [sample]);
    await tester.pumpWidget(_scope(students: students));
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.text('Desactivar'));
    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no podrá iniciar sesión'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(students.statusCalls, 0);

    await tester.ensureVisible(find.text('Desactivar'));
    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Desactivar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(students.statusCalls, 1);
    expect(students.lastStatus, 'INACTIVE');
    expect(find.text('Inactiva'), findsOneWidget);
  });

  testWidgets('el botón de alta ignora un segundo envío', (tester) async {
    final students = _SlowStudents();
    await tester.pumpWidget(
      _scope(students: students, home: const StudentCreateScreen()),
    );
    await tester.pump();
    await tester.pump();

    await _fillCreateForm(tester);
    await tester.ensureVisible(find.text('Guardar estudiante'));
    await tester.tap(find.text('Guardar estudiante'));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    expect(students.createCalls, 1);

    students.finish();
    await tester.pumpAndSettle();
  });

  testWidgets('un orientador no ve acciones de escritura', (tester) async {
    const counselor = UserProfile(
      id: 6,
      email: 'orienta@escuela.test',
      firstName: 'Omar',
      lastName: 'León',
      role: 'COUNSELOR',
      status: 'ACTIVE',
    );
    await tester.pumpWidget(
      _scope(
        students: _Students(items: const [sample]),
        profile: counselor,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Lucía Vega'), findsOneWidget);
    expect(find.text('Ver'), findsOneWidget);
    expect(find.text('Crear estudiante'), findsNothing);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Desactivar'), findsNothing);
  });

  testWidgets('un estudiante no entra a la gestión de estudiantes', (tester) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      SecureTokenStorage.accessTokenKey: 'access-de-prueba',
      SecureTokenStorage.refreshTokenKey: 'refresh-de-prueba',
      SecureTokenStorage.userRoleKey: 'STUDENT',
    });
    final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(_Auth(operator)),
        institutionRepositoryProvider.overrideWithValue(_Institutions()),
        userDirectoryRepositoryProvider.overrideWithValue(_Directory()),
        studentRepositoryProvider.overrideWithValue(_Students()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AvovApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    container.read(goRouterProvider).go('/admin/students');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('No tienes permisos para acceder a esta sección.'),
      findsOneWidget,
    );
    expect(find.text('Crear estudiante'), findsNothing);
  });
}

Future<void> _fillCreateForm(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('student-first-name')), 'Luis');
  await tester.enterText(find.byKey(const Key('student-last-name')), 'Mora');
  await tester.enterText(find.byKey(const Key('student-email')), 'luis@escuela.test');
  await tester.enterText(find.byKey(const Key('student-password')), 'Clave.Segura1');
  await tester.enterText(find.byKey(const Key('student-identification')), '1712345678');
  await tester.enterText(find.byKey(const Key('student-birth-date')), '2010-04-12');
  await tester.enterText(find.byKey(const Key('student-grade')), '10');
  await tester.ensureVisible(find.byKey(const Key('student-institution')));
  await tester.tap(find.byKey(const Key('student-institution')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Colegio Norte').last);
  await tester.pumpAndSettle();
}

Widget _scope({
  required StudentRepository students,
  GoRouter? router,
  Widget? home,
  UserProfile profile = const UserProfile(
    id: 1,
    email: 'admin@escuela.test',
    firstName: 'Ada',
    lastName: 'Admin',
    role: 'SUPER_ADMIN',
    status: 'ACTIVE',
  ),
}) {
  final child = router == null
      ? MaterialApp(home: home ?? const StudentListScreen())
      : MaterialApp.router(routerConfig: router);
  return ProviderScope(
    overrides: [
      studentRepositoryProvider.overrideWithValue(students),
      institutionRepositoryProvider.overrideWithValue(_Institutions()),
      authRepositoryProvider.overrideWithValue(_Auth(profile)),
    ],
    child: child,
  );
}

GoRouter _router() {
  return GoRouter(
    initialLocation: RouteNames.adminStudentNew,
    routes: [
      GoRoute(
        path: RouteNames.adminStudents,
        builder: (context, state) => const StudentListScreen(),
      ),
      GoRoute(
        path: RouteNames.adminStudentNew,
        builder: (context, state) => const StudentCreateScreen(),
      ),
    ],
  );
}

DioException _error(int status, String message) {
  final options = RequestOptions(path: '/students');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: <String, dynamic>{
        'success': false,
        'message': message,
        'data': null,
        'errors': <Map<String, String>>[],
      },
    ),
  );
}

class _Students implements StudentRepository {
  _Students({
    List<ManagedStudent> items = const [],
    this.createError,
    this.missing = false,
    this.failFirstList = false,
    this.pages = 1,
  }) : items = [...items];

  final List<ManagedStudent> items;
  final AppException? createError;
  final bool missing;
  final bool failFirstList;
  final int pages;
  StudentListQuery? lastQuery;
  StudentDraft? createdDraft;
  String? updatedGrade;
  String? updatedPassword;
  String? lastStatus;
  int listCalls = 0;
  int createCalls = 0;
  int statusCalls = 0;

  @override
  Future<ManagedStudentPage> list(StudentListQuery query) async {
    listCalls += 1;
    lastQuery = query;
    if (failFirstList && listCalls == 1) {
      throw NetworkException(FailureMapper.connectionMessage);
    }
    return ManagedStudentPage(
      items: items,
      total: items.length,
      page: query.page,
      pages: items.isEmpty ? 0 : pages,
    );
  }

  @override
  Future<ManagedStudent> getById(int id) async {
    if (missing) {
      throw AppException('Estudiante no encontrado', statusCode: 404);
    }
    return items.firstWhere((item) => item.id == id);
  }

  @override
  Future<ManagedStudent> create(StudentDraft draft) async {
    createCalls += 1;
    if (createError != null) {
      throw createError!;
    }
    createdDraft = draft;
    final created = ManagedStudent(
      id: 21,
      userId: 30,
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
    items.add(created);
    return created;
  }

  @override
  Future<ManagedStudent> update(int id, StudentDraft draft) async {
    updatedGrade = draft.grade;
    updatedPassword = draft.password;
    final current = items.firstWhere((item) => item.id == id);
    final next = ManagedStudent(
      id: current.id,
      userId: current.userId,
      institutionId: current.institutionId,
      identification: draft.identification,
      birthDate: draft.birthDate,
      gender: draft.gender,
      grade: draft.grade,
      email: draft.email,
      firstName: draft.firstName,
      lastName: draft.lastName,
      status: current.status,
    );
    items
      ..clear()
      ..add(next);
    return next;
  }

  @override
  Future<ManagedStudent> updateStatus(int id, String status) async {
    statusCalls += 1;
    lastStatus = status;
    final current = items.firstWhere((item) => item.id == id);
    final next = ManagedStudent(
      id: current.id,
      userId: current.userId,
      institutionId: current.institutionId,
      identification: current.identification,
      birthDate: current.birthDate,
      gender: current.gender,
      grade: current.grade,
      email: current.email,
      firstName: current.firstName,
      lastName: current.lastName,
      status: status,
    );
    items
      ..clear()
      ..add(next);
    return next;
  }
}

class _SlowStudents extends _Students {
  final Completer<ManagedStudent> _pending = Completer<ManagedStudent>();

  void finish() {
    if (!_pending.isCompleted) {
      _pending.complete(
        const ManagedStudent(
          id: 21,
          userId: 30,
          institutionId: 3,
          identification: '1712345678',
          birthDate: '2010-04-12',
          gender: 'NOT_SPECIFIED',
          grade: '10',
          email: 'luis@escuela.test',
          firstName: 'Luis',
          lastName: 'Mora',
          status: 'ACTIVE',
        ),
      );
    }
  }

  @override
  Future<ManagedStudent> create(StudentDraft draft) {
    createCalls += 1;
    createdDraft = draft;
    return _pending.future;
  }
}

class _Auth implements AuthRepository {
  _Auth(this.profile);

  final UserProfile profile;

  @override
  Future<UserProfile> currentProfile() async => profile;

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> clearSession() async {}
}

class _Institutions implements InstitutionRepository {
  @override
  Future<InstitutionPage> list({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    return const InstitutionPage(items: [_school], total: 1, page: 1, pages: 1);
  }

  @override
  Future<Institution> getById(int id) async => _school;

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

const _school = Institution(
  id: 3,
  name: 'Colegio Norte',
  code: 'CN-01',
  province: 'Pichincha',
  city: 'Quito',
  status: 'ACTIVE',
);
