import 'package:avov_frontend/features/assignments/domain/assignment_repository.dart';
import 'package:avov_frontend/features/assignments/domain/counselor_assignment.dart';
import 'package:avov_frontend/features/assignments/presentation/providers/assignment_provider.dart';
import 'package:avov_frontend/features/assignments/presentation/screens/assignment_create_screen.dart';
import 'package:avov_frontend/features/assignments/presentation/screens/assignment_list_screen.dart';
import 'package:avov_frontend/features/auth/domain/auth_repository.dart';
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
          userAccountRepositoryProvider.overrideWithValue(_FakeUserRepository()),
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
}

class _FakeAssignmentRepository implements AssignmentRepository {
  _FakeAssignmentRepository({required this.page});

  final CounselorAssignmentPage page;
  int createCalls = 0;

  @override
  Future<CounselorAssignment> create({
    required int studentId,
    required int counselorId,
  }) async {
    createCalls += 1;
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
    return const ManagedStudentPage(
      items: [
        ManagedStudent(
          id: 9,
          userId: 11,
          institutionId: 1,
          identification: 'ABC',
          birthDate: '2008-01-01',
          gender: 'NOT_SPECIFIED',
          grade: '11',
          status: 'ACTIVE',
          email: 's@test.edu',
          firstName: 'Estu',
          lastName: 'Diante',
        ),
      ],
      total: 1,
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
    return const ManagedUserPage(
      items: [
        ManagedUser(
          id: 5,
          email: 'o@test.edu',
          firstName: 'Ori',
          lastName: 'Entador',
          role: 'COUNSELOR',
          status: 'ACTIVE',
          institutionId: 1,
        ),
      ],
      total: 1,
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

class _FakeAuthRepository implements AuthRepository {
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
