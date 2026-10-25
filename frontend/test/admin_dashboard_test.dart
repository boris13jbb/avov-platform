import 'package:avov_frontend/core/errors/failure_mapper.dart';
import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/core/providers/providers.dart';
import 'package:avov_frontend/core/storage/secure_token_storage.dart';
import 'package:avov_frontend/features/admin/domain/user_directory_repository.dart';
import 'package:avov_frontend/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:avov_frontend/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:avov_frontend/features/auth/domain/auth_repository.dart';
import 'support/auth_repository_stubs.dart';
import 'package:avov_frontend/features/auth/domain/auth_tokens.dart';
import 'package:avov_frontend/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:avov_frontend/features/institutions/domain/institution.dart';
import 'package:avov_frontend/features/institutions/domain/institution_repository.dart';
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
    id: 1,
    email: 'admin@escuela.test',
    firstName: 'Ana',
    lastName: 'Pérez',
    role: 'SUPER_ADMIN',
    status: 'ACTIVE',
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('las rutas /admin quedan reservadas al superadministrador', () {
    expect(routeMatchesRole('/admin/institutions', 'SUPER_ADMIN'), isTrue);
    expect(routeMatchesRole('/admin/institutions/new', 'STUDENT'), isFalse);
    expect(routeMatchesRole('/admin/users', 'SUPER_ADMIN'), isTrue);
    expect(routeMatchesRole('/admin/users/new', 'STUDENT'), isFalse);
    expect(routeMatchesRole('/admin/users/4', 'INSTITUTION_ADMIN'), isFalse);
    expect(routeMatchesRole('/admin/students', 'SUPER_ADMIN'), isTrue);
    expect(routeMatchesRole('/admin/students/new', 'STUDENT'), isFalse);
    expect(routeMatchesRole('/admin/students/3', 'COUNSELOR'), isFalse);
    expect(routeMatchesRole('/admin/assignments', 'SUPER_ADMIN'), isTrue);
    expect(routeMatchesRole('/admin/assignments/new', 'COUNSELOR'), isFalse);
    expect(routeMatchesRole('/admin/dashboard', 'INSTITUTION_ADMIN'), isFalse);
  });

  testWidgets('el panel muestra el perfil y el estado vacío', (tester) async {
    await tester.pumpWidget(
      _scope(
        auth: _AuthRepo(profile),
        institutions: _InstitutionRepo(),
        users: _UserRepo(4),
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Panel de superadministrador'), findsOneWidget);
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('admin@escuela.test'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Todavía no hay instituciones'), findsOneWidget);
    expect(find.text('Gestionar usuarios'), findsOneWidget);
    expect(find.text('Gestionar estudiantes'), findsOneWidget);
    expect(find.textContaining('Carreras, preguntas RIASEC'), findsOneWidget);
  });

  testWidgets('un error de carga ofrece reintento', (tester) async {
    final users = _FlakyUserRepo();
    await tester.pumpWidget(
      _scope(
        auth: _AuthRepo(profile),
        institutions: _InstitutionRepo(),
        users: users,
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(FailureMapper.connectionMessage), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(users.calls, 2);
    expect(find.text('Ana Pérez'), findsOneWidget);
  });

  testWidgets('un estudiante no entra a las rutas de administración',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      SecureTokenStorage.accessTokenKey: 'access-de-prueba',
      SecureTokenStorage.refreshTokenKey: 'refresh-de-prueba',
      SecureTokenStorage.userRoleKey: 'STUDENT',
    });
    final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(_AuthRepo(profile)),
        institutionRepositoryProvider.overrideWithValue(_InstitutionRepo()),
        userDirectoryRepositoryProvider.overrideWithValue(_UserRepo(1)),
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

    expect(find.text('Panel del estudiante'), findsOneWidget);
    container.read(goRouterProvider).go('/admin/users');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('No tienes permisos para acceder a esta sección.'),
      findsOneWidget,
    );
  });

  testWidgets('cerrar sesión borra los tokens y vuelve al login', (tester) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      SecureTokenStorage.accessTokenKey: 'access-de-prueba',
      SecureTokenStorage.refreshTokenKey: 'refresh-de-prueba',
      SecureTokenStorage.userRoleKey: 'SUPER_ADMIN',
    });
    final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(_ClearingAuthRepo(storage, profile)),
        institutionRepositoryProvider.overrideWithValue(_InstitutionRepo()),
        userDirectoryRepositoryProvider.overrideWithValue(_UserRepo(1)),
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

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cerrar sesión'), findsOneWidget);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(await storage.getUserRole(), isNull);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}

Widget _scope({
  required AuthRepository auth,
  required InstitutionRepository institutions,
  required UserDirectoryRepository users,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      institutionRepositoryProvider.overrideWithValue(institutions),
      userDirectoryRepositoryProvider.overrideWithValue(users),
    ],
    child: child,
  );
}

class _AuthRepo with AuthRepositoryChangePasswordStub implements AuthRepository {
  _AuthRepo(this.profile);

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

class _ClearingAuthRepo extends _AuthRepo {
  _ClearingAuthRepo(this.storage, super.profile);

  final SecureTokenStorage storage;

  @override
  Future<void> logout() => storage.clearTokens();
}

class _InstitutionRepo implements InstitutionRepository {
  InstitutionPage page = const InstitutionPage(
    items: [],
    total: 0,
    page: 1,
    pages: 0,
  );

  @override
  Future<InstitutionPage> list({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    return this.page;
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

class _UserRepo implements UserDirectoryRepository {
  _UserRepo(this.total);

  final int total;

  @override
  Future<int> count() async => total;
}

class _FlakyUserRepo implements UserDirectoryRepository {
  int calls = 0;

  @override
  Future<int> count() async {
    calls += 1;
    if (calls == 1) {
      throw NetworkException(FailureMapper.connectionMessage);
    }
    return 2;
  }
}
