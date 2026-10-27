import 'package:avov_frontend/features/assignments/domain/assignment_repository.dart';
import 'package:avov_frontend/features/assignments/domain/counselor_assignment.dart';
import 'package:avov_frontend/features/assignments/presentation/providers/assignment_provider.dart';
import 'package:avov_frontend/features/assignments/presentation/screens/assignment_create_screen.dart';
import 'package:avov_frontend/features/assignments/presentation/screens/assignment_list_screen.dart';
import 'package:avov_frontend/features/auth/domain/auth_repository.dart';
import 'support/auth_repository_stubs.dart';
import 'package:avov_frontend/features/auth/domain/auth_tokens.dart';
import 'package:avov_frontend/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:avov_frontend/features/students/domain/managed_student.dart';
import 'package:avov_frontend/features/students/domain/student_repository.dart';
import 'package:avov_frontend/features/students/presentation/providers/students_provider.dart';
import 'package:avov_frontend/features/users/domain/managed_user.dart';
import 'package:avov_frontend/features/users/domain/user_account_repository.dart';
import 'package:avov_frontend/features/users/presentation/providers/users_provider.dart';
import 'package:avov_frontend/router/role_destination.dart';
import 'package:avov_frontend/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rutas de asignación por rol y guards', () {
    expect(
      AssignmentAreaRoutes.createLocation(role: 'SUPER_ADMIN', studentId: 9),
      '/admin/assignments/new?studentId=9',
    );
    expect(
      AssignmentAreaRoutes.createLocation(
        role: 'INSTITUTION_ADMIN',
        studentId: 9,
      ),
      '/institution/assignments/new?studentId=9',
    );
    expect(AssignmentAreaRoutes.createLocation(role: 'COUNSELOR'), isNull);
    expect(AssignmentAreaRoutes.createLocation(role: 'STUDENT'), isNull);

    expect(routeMatchesRole('/admin/assignments', 'SUPER_ADMIN'), isTrue);
    expect(routeMatchesRole('/admin/assignments/new', 'SUPER_ADMIN'), isTrue);
    expect(
      routeMatchesRole('/admin/assignments', 'INSTITUTION_ADMIN'),
      isFalse,
    );
    expect(
      routeMatchesRole('/institution/assignments', 'INSTITUTION_ADMIN'),
      isTrue,
    );
    expect(
      routeMatchesRole('/institution/assignments/new', 'SUPER_ADMIN'),
      isFalse,
    );
    expect(routeMatchesRole('/institution/assignments', 'COUNSELOR'), isFalse);
    expect(routeMatchesRole('/admin/assignments', 'STUDENT'), isFalse);
    expect(routeMatchesRole('/admin/assignments/new', 'COUNSELOR'), isFalse);
  });

  test('CounselorAssignment.fromJson mapea estado y nombres', () {
    final item = CounselorAssignment.fromJson(<String, dynamic>{
      'id': 1,
      'counselor_id': 5,
      'student_id': 9,
      'institution_id': 3,
      'status': 'ACTIVE',
      'assigned_at': '2026-10-24T00:00:00',
      'counselor': <String, dynamic>{
        'id': 5,
        'email': 'o@test.edu',
        'first_name': 'Ori',
        'last_name': 'Entador',
      },
      'student': <String, dynamic>{
        'id': 9,
        'identification': 'ABC',
        'user': <String, dynamic>{
          'id': 11,
          'first_name': 'Estu',
          'last_name': 'Diante',
        },
      },
    });

    expect(item.isActive, isTrue);
    expect(item.statusLabel, 'Activa');
    expect(item.counselorName, 'Ori Entador');
    expect(item.studentName, 'Estu Diante');
  });

  test('uniqueByEntityId conserva el primero y elimina duplicados del mismo id',
      () {
    final items = <ManagedStudent>[
      _student(id: 1, identification: 'A', firstName: 'Uno'),
      _student(id: 1, identification: 'A-dup', firstName: 'UnoDup'),
      _student(id: 2, identification: 'B', firstName: 'Dos'),
    ];
    final unique = uniqueByEntityId(items, (s) => s.id);
    expect(unique.map((s) => s.id), [1, 2]);
    expect(unique.first.identification, 'A');
    expect(uniqueByEntityId(<ManagedStudent>[], (s) => s.id), isEmpty);
    expect(
      uniqueByEntityId(
        [_student(id: 7, identification: 'S', firstName: 'Solo')],
        (s) => s.id,
      ).single.id,
      7,
    );
  });

  testWidgets('lista muestra vacío y permite crear', (tester) async {
    final repo = _FakeAssignmentRepository(
      page: const CounselorAssignmentPage(
        items: [],
        total: 0,
        page: 1,
        pageSize: 20,
        pages: 0,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(home: AssignmentListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No hay asignaciones'), findsOneWidget);
    expect(find.text('Crear asignación'), findsOneWidget);
  });

  testWidgets('formulario valida selección antes de enviar', (tester) async {
    final repo = _FakeAssignmentRepository(
      page: const CounselorAssignmentPage(
        items: [],
        total: 0,
        page: 1,
        pageSize: 20,
        pages: 0,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(repo),
          studentRepositoryProvider.overrideWithValue(_FakeStudentRepository()),
          userAccountRepositoryProvider
              .overrideWithValue(_FakeUserRepository()),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(home: AssignmentCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Asignar'));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona un estudiante'), findsOneWidget);
    expect(find.text('Selecciona un orientador'), findsOneWidget);
    expect(repo.createCalls, 0);
  });

  testWidgets('lista vacía de estudiantes muestra mensaje claro',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(
            _FakeAssignmentRepository(
              page: const CounselorAssignmentPage(
                items: [],
                total: 0,
                page: 1,
                pageSize: 20,
                pages: 0,
              ),
            ),
          ),
          studentRepositoryProvider.overrideWithValue(
            _FakeStudentRepository(items: const []),
          ),
          userAccountRepositoryProvider
              .overrideWithValue(_FakeUserRepository()),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(home: AssignmentCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No hay estudiantes activos para asignar.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets(
    'ids duplicados del mismo estudiante no rompen el dropdown (valor 1)',
    (tester) async {
      final students = [
        _student(id: 1, identification: 'DUP-1', firstName: 'Primero'),
        _student(id: 1, identification: 'DUP-1b', firstName: 'Duplicado'),
        _student(id: 3, identification: 'OK', firstName: 'Otro'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentRepositoryProvider.overrideWithValue(
              _FakeAssignmentRepository(
                page: const CounselorAssignmentPage(
                  items: [],
                  total: 0,
                  page: 1,
                  pageSize: 20,
                  pages: 0,
                ),
              ),
            ),
            studentRepositoryProvider.overrideWithValue(
              _FakeStudentRepository(items: students),
            ),
            userAccountRepositoryProvider.overrideWithValue(
              _FakeUserRepository(
                items: [
                  _counselor(id: 5, firstName: 'Ori', lastName: 'Entador'),
                ],
              ),
            ),
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: const MaterialApp(
            home: AssignmentCreateScreen(preselectedStudentId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DropdownButtonFormField<int>), findsNWidgets(2));
      expect(find.textContaining('Primero'), findsWidgets);
      expect(find.textContaining('Duplicado'), findsNothing);
    },
  );

  testWidgets('selección preseleccionada inexistente no lanza aserción',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(
            _FakeAssignmentRepository(
              page: const CounselorAssignmentPage(
                items: [],
                total: 0,
                page: 1,
                pageSize: 20,
                pages: 0,
              ),
            ),
          ),
          studentRepositoryProvider.overrideWithValue(_FakeStudentRepository()),
          userAccountRepositoryProvider
              .overrideWithValue(_FakeUserRepository()),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(
          home: AssignmentCreateScreen(preselectedStudentId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Asignar'), findsOneWidget);
  });

  testWidgets('recarga asíncrona del catálogo mantiene el formulario usable',
      (tester) async {
    final studentRepo = _FakeStudentRepository(
      items: [_student(id: 9, identification: 'ABC', firstName: 'Estu')],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(
            _FakeAssignmentRepository(
              page: const CounselorAssignmentPage(
                items: [],
                total: 0,
                page: 1,
                pageSize: 20,
                pages: 0,
              ),
            ),
          ),
          studentRepositoryProvider.overrideWithValue(studentRepo),
          userAccountRepositoryProvider
              .overrideWithValue(_FakeUserRepository()),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(home: AssignmentCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    studentRepo.items = [
      _student(id: 9, identification: 'ABC', firstName: 'Estu'),
      _student(id: 10, identification: 'XYZ', firstName: 'Nuevo'),
    ];

    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Estu').last);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AssignmentCreateScreen)),
    );
    container.invalidate(studentChoicesForAssignmentProvider);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Asignar'), findsOneWidget);
  });

  testWidgets('guardado válido de una asignación', (tester) async {
    final repo = _FakeAssignmentRepository(
      page: const CounselorAssignmentPage(
        items: [],
        total: 0,
        page: 1,
        pageSize: 20,
        pages: 0,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(repo),
          studentRepositoryProvider.overrideWithValue(_FakeStudentRepository()),
          userAccountRepositoryProvider
              .overrideWithValue(_FakeUserRepository()),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: MaterialApp(
          home: const AssignmentCreateScreen(),
          routes: {
            RouteNames.institutionAssignments: (_) =>
                const Scaffold(body: Text('lista-asignaciones')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Estu').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Ori').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Asignar'));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
    expect(repo.lastStudentId, 9);
    expect(repo.lastCounselorId, 5);
  });
}

ManagedStudent _student({
  required int id,
  required String identification,
  required String firstName,
  String lastName = 'Test',
}) {
  return ManagedStudent(
    id: id,
    userId: id + 100,
    institutionId: 1,
    identification: identification,
    birthDate: '2008-01-01',
    gender: 'NOT_SPECIFIED',
    grade: '11',
    status: 'ACTIVE',
    email: '$firstName@test.edu',
    firstName: firstName,
    lastName: lastName,
  );
}

ManagedUser _counselor({
  required int id,
  required String firstName,
  required String lastName,
}) {
  return ManagedUser(
    id: id,
    email: '$firstName@test.edu',
    firstName: firstName,
    lastName: lastName,
    role: 'COUNSELOR',
    status: 'ACTIVE',
    institutionId: 1,
  );
}

class _FakeAssignmentRepository implements AssignmentRepository {
  _FakeAssignmentRepository({required this.page});

  final CounselorAssignmentPage page;
  int createCalls = 0;
  int? lastStudentId;
  int? lastCounselorId;

  @override
  Future<CounselorAssignment> create({
    required int studentId,
    required int counselorId,
  }) async {
    createCalls += 1;
    lastStudentId = studentId;
    lastCounselorId = counselorId;
    return CounselorAssignment(
      id: 1,
      counselorId: counselorId,
      studentId: studentId,
      institutionId: 1,
      status: 'ACTIVE',
      assignedAt: '2026-10-24T00:00:00',
    );
  }

  @override
  Future<CounselorAssignmentPage> list(AssignmentListQuery query) async => page;

  @override
  Future<CounselorAssignment> updateStatus({
    required int assignmentId,
    required String status,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository({List<ManagedStudent>? items})
      : items = items ??
            [
              _student(
                id: 9,
                identification: 'ABC',
                firstName: 'Estu',
                lastName: 'Diante',
              ),
            ];

  List<ManagedStudent> items;

  @override
  Future<ManagedStudent> create(StudentDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<ManagedStudent> getById(int id) {
    throw UnimplementedError();
  }

  @override
  Future<ManagedStudent> getOwn() {
    throw UnimplementedError();
  }

  @override
  Future<ManagedStudentPage> list(StudentListQuery query) async {
    return ManagedStudentPage(
      items: items,
      total: items.length,
      page: 1,
      pages: 1,
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

class _FakeUserRepository implements UserAccountRepository {
  _FakeUserRepository({List<ManagedUser>? items})
      : items = items ??
            [
              _counselor(id: 5, firstName: 'Ori', lastName: 'Entador'),
            ];

  final List<ManagedUser> items;

  @override
  Future<ManagedUser> create(UserDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<ManagedUser> getById(int id) {
    throw UnimplementedError();
  }

  @override
  Future<ManagedUserPage> list(UserListQuery query) async {
    return ManagedUserPage(
      items: items,
      total: items.length,
      page: 1,
      pages: 1,
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

class _FakeAuthRepository with AuthRepositoryChangePasswordStub implements AuthRepository {
  @override
  Future<void> clearSession() async {}

  @override
  Future<UserProfile> currentProfile() async {
    return const UserProfile(
      id: 1,
      email: 'admin@test.edu',
      firstName: 'Admin',
      lastName: 'Inst',
      role: 'INSTITUTION_ADMIN',
      status: 'ACTIVE',
      institutionId: 1,
    );
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}
