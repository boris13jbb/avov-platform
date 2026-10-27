import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/core/providers/providers.dart';
import 'package:avov_frontend/core/storage/secure_token_storage.dart';
import 'package:avov_frontend/features/admin/domain/user_directory_repository.dart';
import 'package:avov_frontend/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:avov_frontend/features/auth/data/api_auth_repository.dart';
import 'package:avov_frontend/features/auth/data/auth_remote_datasource.dart';
import 'package:avov_frontend/features/auth/domain/auth_repository.dart';
import 'support/auth_repository_stubs.dart';
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
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('un fallo de red borra el access token, el refresh token y el rol', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      SecureTokenStorage.accessTokenKey: 'access-de-prueba',
      SecureTokenStorage.refreshTokenKey: 'refresh-de-prueba',
      SecureTokenStorage.userRoleKey: 'STUDENT',
    });
    final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
    final repository = ApiAuthRepository(
      dio: Dio(),
      storage: storage,
      remote: _FailingRemote(),
    );

    await expectLater(repository.logout(), throwsA(isA<AppException>()));

    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(await storage.getUserRole(), isNull);
  });

  test('pulsaciones simultáneas ejecutan un solo cierre de sesión', () async {
    final storage = _seededStorage('STUDENT');
    final auth = _TrackingAuth(_profile('STUDENT'), storage, delay: const Duration(milliseconds: 200));
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(container.dispose);

    final signedIn = await container.read(authSessionProvider.notifier).login(
          email: 'lucia@escuela.test',
          password: 'no-se-registra',
        );
    expect(signedIn?.role, 'STUDENT');

    final notifier = container.read(authSessionProvider.notifier);
    final first = notifier.logout();
    final second = notifier.logout();
    await Future.wait(<Future<void>>[first, second]);

    expect(auth.logoutCalls, 1);
    expect(container.read(authSessionProvider).profile, isNull);
    expect(container.read(authSessionProvider).isSubmitting, isFalse);
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
  });

  for (final role in ['STUDENT', 'COUNSELOR', 'INSTITUTION_ADMIN', 'SUPER_ADMIN']) {
    testWidgets('$role cierra sesión y no vuelve a su panel', (tester) async {
      final storage = _seededStorage(role);
      final auth = _TrackingAuth(_profile(role), storage);
      final container = _container(storage, auth);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const AvovApp()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.widgetWithText(TextButton, 'Cerrar sesión'), findsOneWidget);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(auth.logoutCalls, 1);
      expect(container.read(authSessionProvider).profile, isNull);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getUserRole(), isNull);
      expect(find.text('Ingresar'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);

      container.read(goRouterProvider).go(_panelFor(role));
      await tester.pumpAndSettle();

      expect(
        container.read(goRouterProvider).routerDelegate.currentConfiguration.uri.path,
        '/login',
      );
      expect(find.text('Ingresar', skipOffstage: true), findsOneWidget);
      expect(find.text(_panelTitle(role), skipOffstage: true), findsNothing);
    });
  }

  testWidgets('el panel del estudiante muestra el cierre sin abrir un menú', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = _seededStorage('STUDENT');
    final container = _container(storage, _TrackingAuth(_profile('STUDENT'), storage));
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AvovApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(TextButton, 'Cerrar sesión'), findsOneWidget);
    expect(find.byTooltip('Menú de usuario'), findsNothing);
  });

  testWidgets('un error del servidor no deja la sesión local ni muestra el fallo', (tester) async {
    final storage = _seededStorage('STUDENT');
    final auth = _TrackingAuth(
      _profile('STUDENT'),
      storage,
      error: AppException('detalle interno que no debe verse'),
    );
    final container = _container(storage, auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AvovApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('detalle interno que no debe verse'), findsNothing);
    expect(find.text('Ingresar'), findsOneWidget);
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
  });

  testWidgets('una segunda pulsación no dispara otro cierre', (tester) async {
    final storage = _seededStorage('STUDENT');
    final auth = _TrackingAuth(
      _profile('STUDENT'),
      storage,
      delay: const Duration(milliseconds: 300),
    );
    final container = _container(storage, auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AvovApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pump();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));

    expect(auth.logoutCalls, 1);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}

SecureTokenStorage _seededStorage(String role) {
  FlutterSecureStorage.setMockInitialValues(<String, String>{
    SecureTokenStorage.accessTokenKey: 'access-de-prueba',
    SecureTokenStorage.refreshTokenKey: 'refresh-de-prueba',
    SecureTokenStorage.userRoleKey: role,
  });
  return SecureTokenStorage(storage: const FlutterSecureStorage());
}

ProviderContainer _container(SecureTokenStorage storage, AuthRepository auth) {
  return ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(auth),
      studentRepositoryProvider.overrideWithValue(_Students()),
      userAccountRepositoryProvider.overrideWithValue(_Users()),
      institutionRepositoryProvider.overrideWithValue(_Institutions()),
      userDirectoryRepositoryProvider.overrideWithValue(_Directory()),
      vocationalRepositoryProvider.overrideWithValue(_Vocational()),
    ],
  );
}

UserProfile _profile(String role) {
  return UserProfile(
    id: 9,
    email: 'persona@escuela.test',
    firstName: 'Lucía',
    lastName: 'Vega',
    role: role,
    status: 'ACTIVE',
    institutionId: role == 'SUPER_ADMIN' ? null : 7,
  );
}

String _panelFor(String role) {
  switch (role) {
    case 'SUPER_ADMIN':
      return '/admin/dashboard';
    case 'INSTITUTION_ADMIN':
      return '/institution/dashboard';
    case 'COUNSELOR':
      return '/counselor/dashboard';
    default:
      return '/student/dashboard';
  }
}

String _panelTitle(String role) {
  switch (role) {
    case 'SUPER_ADMIN':
      return 'Panel de superadministrador';
    case 'INSTITUTION_ADMIN':
      return 'Panel de la institución';
    case 'COUNSELOR':
      return 'Panel del orientador';
    default:
      return 'Panel del estudiante';
  }
}

class _FailingRemote extends AuthRemoteDatasource {
  _FailingRemote() : super(Dio());

  @override
  Future<void> logout({required String refreshToken}) async {
    throw AppException('No se pudo contactar el servidor');
  }
}

class _TrackingAuth with AuthRepositoryChangePasswordStub implements AuthRepository {
  _TrackingAuth(this.profile, this.storage, {this.delay, this.error});

  final UserProfile profile;
  final SecureTokenStorage storage;
  final Duration? delay;
  final AppException? error;
  int logoutCalls = 0;

  @override
  Future<UserProfile> currentProfile() async => profile;

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    await storage.saveAccessToken('access-de-prueba');
    await storage.saveRefreshToken('refresh-de-prueba');
    await storage.saveUserRole(profile.role);
    return profile;
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
    final wait = delay;
    if (wait != null) {
      await Future<void>.delayed(wait);
    }
    await storage.clearTokens();
    final failure = error;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> clearSession() => storage.clearTokens();
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
      email: 'persona@escuela.test',
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
  Future<ManagedStudent> update(int id, StudentDraft draft) => throw UnimplementedError();

  @override
  Future<ManagedStudent> updateStatus(int id, String status) => throw UnimplementedError();
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
  Future<ManagedUser> update(int id, UserDraft draft) => throw UnimplementedError();

  @override
  Future<ManagedUser> updateStatus(int id, String status) => throw UnimplementedError();
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

class _Vocational implements VocationalRepository {
  @override
  Future<VocationalSessionPage> listSessions({int page = 1, int pageSize = 20}) async {
    return const VocationalSessionPage(items: [], total: 0, page: 1, pages: 0);
  }

  @override
  Future<VocationalSession> start() => throw UnimplementedError();

  @override
  Future<VocationalQuestionnaire> questions(int sessionId) => throw UnimplementedError();

  @override
  Future<void> saveAnswer({
    required int sessionId,
    required int questionId,
    required int answerValue,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VocationalResult> finish(int sessionId) => throw UnimplementedError();

  @override
  Future<VocationalResult> result(int sessionId) => throw UnimplementedError();
}
