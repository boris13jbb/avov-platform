import 'dart:async';

import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/core/errors/failure_mapper.dart';
import 'package:avov_frontend/core/providers/providers.dart';
import 'package:avov_frontend/core/storage/secure_token_storage.dart';
import 'package:avov_frontend/features/auth/domain/auth_repository.dart';
import 'package:avov_frontend/features/auth/domain/auth_tokens.dart';
import 'package:avov_frontend/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:avov_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:avov_frontend/main.dart';
import 'package:avov_frontend/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  testWidgets('los campos vacíos no envían el formulario', (tester) async {
    final repository = _ImmediateRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('El correo electrónico es obligatorio'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
    expect(repository.calls, 0);
  });

  testWidgets('un login exitoso abre el panel del rol', (tester) async {
    final repository = _ImmediateRepository(
      profile: const UserProfile(
        id: 4,
        email: 'persona@escuela.test',
        firstName: 'Ana',
        lastName: 'Pérez',
        role: 'STUDENT',
        status: 'ACTIVE',
      ),
    );
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/student/dashboard',
          builder: (context, state) => const Text('panel-estudiante'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'persona@escuela.test',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'clave-prueba',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    await tester.pump();

    expect(find.text('panel-estudiante'), findsOneWidget);
    expect(repository.calls, 1);
  });

  testWidgets('el botón no dispara otra solicitud mientras carga', (tester) async {
    final repository = _DelayedRepository();
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/student/dashboard',
          builder: (context, state) => const Text('panel-estudiante'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'persona@escuela.test',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'clave-prueba',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byKey(const Key('login-submit')));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(repository.calls, 1);

    repository.finish();
    await tester.pump();
    await tester.pump();
  });

  testWidgets('una credencial rechazada se muestra sin detalle interno',
      (tester) async {
    final repository = _ThrowingRepository(
      UnauthorizedProbe(FailureMapper.invalidCredentialsMessage),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'persona@escuela.test',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'clave-prueba',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    await tester.pump();

    expect(find.text(FailureMapper.invalidCredentialsMessage), findsOneWidget);
    expect(find.textContaining('SQL'), findsNothing);
  });

  testWidgets('con sesión válida el guard abre el panel del rol', (tester) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      SecureTokenStorage.accessTokenKey: 'access-de-prueba',
      SecureTokenStorage.refreshTokenKey: 'refresh-de-prueba',
      SecureTokenStorage.userRoleKey: 'INSTITUTION_ADMIN',
    });
    final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
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

    expect(find.text('Panel de la institución'), findsOneWidget);
  });

  testWidgets('sin sesión, una ruta protegida vuelve al login', (tester) async {
    final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
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
    container.read(goRouterProvider).go('/student/dashboard');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Panel del estudiante'), findsNothing);
  });
}

class UnauthorizedProbe extends AppException {
  UnauthorizedProbe(super.message);
}

class _ImmediateRepository implements AuthRepository {
  _ImmediateRepository({this.profile});

  final UserProfile? profile;
  int calls = 0;

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    calls += 1;
    return profile!;
  }

  @override
  Future<UserProfile> currentProfile() {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> clearSession() async {}
}

class _DelayedRepository implements AuthRepository {
  final Completer<UserProfile> _pending = Completer<UserProfile>();
  int calls = 0;

  void finish() {
    if (!_pending.isCompleted) {
      _pending.complete(
        const UserProfile(
          id: 1,
          email: 'persona@escuela.test',
          firstName: 'Ana',
          lastName: 'Pérez',
          role: 'STUDENT',
          status: 'ACTIVE',
        ),
      );
    }
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) {
    calls += 1;
    return _pending.future;
  }

  @override
  Future<UserProfile> currentProfile() {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> clearSession() async {}
}

class _ThrowingRepository implements AuthRepository {
  _ThrowingRepository(this.error);

  final AppException error;

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    throw error;
  }

  @override
  Future<UserProfile> currentProfile() {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> clearSession() async {}
}
