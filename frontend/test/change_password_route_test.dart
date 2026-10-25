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
import 'package:avov_frontend/router/app_router.dart';
import 'package:avov_frontend/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// S-19: no hay pantalla Flutter de cambio de contraseña.
/// La constante huérfana se retiró; la ruta no debe registrarse ni ofrecerse.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('GoRouter no registra /change-password', () {
    final container = _container();
    addTearDown(container.dispose);

    final paths = container
        .read(goRouterProvider)
        .configuration
        .routes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toList();

    expect(paths, isNot(contains('/change-password')));
    expect(paths, contains(RouteNames.login));
    expect(paths, contains(RouteNames.studentDashboard));
    expect(paths, contains(RouteNames.studentProfile));
    expect(paths, contains(RouteNames.studentTestHome));
    expect(paths, contains(RouteNames.studentResults));
  });

  testWidgets(
    'navegar a /change-password no muestra un flujo de cambio de contraseña',
    (tester) async {
      final container = await _pumpStudent(tester);
      container.read(goRouterProvider).go('/change-password');
      await tester.pumpAndSettle();

      expect(find.text('Ruta no encontrada'), findsOneWidget);
      expect(find.text('Cambiar contraseña'), findsNothing);
      expect(find.textContaining('Nueva contraseña'), findsNothing);
      expect(find.textContaining('Contraseña actual'), findsNothing);
    },
  );

  testWidgets(
    'el menú del estudiante no ofrece cambio de contraseña',
    (tester) async {
      await _pumpStudent(tester);

      expect(find.text('Panel del estudiante'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cerrar sesión'), findsOneWidget);

      await tester.tap(find.byTooltip('Abrir menú'));
      await tester.pumpAndSettle();

      expect(find.text('Cambiar contraseña'), findsNothing);
      expect(find.textContaining('change-password'), findsNothing);
      expect(find.text('Inicio'), findsWidgets);
      expect(find.text('Perfil'), findsWidgets);
    },
  );
}

ProviderContainer _container({
  UserProfile? profile,
  SecureTokenStorage? storage,
}) {
  final resolved = profile ??
      const UserProfile(
        id: 9,
        email: 'lucia@escuela.test',
        firstName: 'Lucía',
        lastName: 'Vega',
        role: 'STUDENT',
        status: 'ACTIVE',
        institutionId: 7,
      );
  return ProviderContainer(
    overrides: [
      if (storage != null) tokenStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(_Auth(resolved, storage)),
      studentRepositoryProvider.overrideWithValue(_Students()),
      vocationalRepositoryProvider.overrideWithValue(_Vocational()),
      institutionRepositoryProvider.overrideWithValue(_Institutions()),
      userDirectoryRepositoryProvider.overrideWithValue(_Directory()),
      userAccountRepositoryProvider.overrideWithValue(_Users()),
    ],
  );
}

Future<ProviderContainer> _pumpStudent(WidgetTester tester) async {
  FlutterSecureStorage.setMockInitialValues(<String, String>{
    SecureTokenStorage.accessTokenKey: 'access-de-prueba',
    SecureTokenStorage.refreshTokenKey: 'refresh-de-prueba',
    SecureTokenStorage.userRoleKey: 'STUDENT',
  });
  final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
  final container = _container(
    storage: storage,
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
  @override
  Future<String> forgotPassword({required String email}) async => '';

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async => '';

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
  Future<ManagedStudent> create(StudentDraft draft) => throw UnimplementedError();

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

class _Institutions implements InstitutionRepository {
  @override
  Future<InstitutionPage> list({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    return const InstitutionPage(items: [], total: 0, page: 1, pages: 0);
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
  Future<int> count() async => 0;
}
