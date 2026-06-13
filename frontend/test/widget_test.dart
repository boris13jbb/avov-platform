import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:avov_frontend/core/models/public_settings.dart';
import 'package:avov_frontend/core/providers/public_settings_provider.dart';
import 'package:avov_frontend/core/storage/secure_token_storage.dart';
import 'package:avov_frontend/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:avov_frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:avov_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:avov_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:avov_frontend/features/splash/presentation/screens/splash_screen.dart';
import 'package:avov_frontend/router/route_names.dart';

const _testPublicSettings = PublicSettings(
  appDisplayName: 'AVOV',
  ethicalDisclaimer: 'Mensaje ético de prueba.',
  maintenanceMode: false,
);

List<Override> get _publicSettingsOverrides => [
      publicSettingsProvider.overrideWith((ref) async => _testPublicSettings),
    ];

class _TestAuthRepository extends AuthRepository {
  _TestAuthRepository()
      : super(
          remoteDatasource: AuthRemoteDatasource(Dio()),
          tokenStorage: SecureTokenStorage(),
        );

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<String?> getStoredRole() async => null;
}

void main() {
  testWidgets('Splash muestra la marca AVOV', (tester) async {
    final router = GoRouter(
      initialLocation: RouteNames.splash,
      routes: [
        GoRoute(
          path: RouteNames.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: RouteNames.login,
          builder: (context, state) => const Scaffold(body: Text('Login')),
        ),
        GoRoute(
          path: RouteNames.maintenance,
          builder: (context, state) => const Scaffold(body: Text('Mantenimiento')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._publicSettingsOverrides,
          authRepositoryProvider.overrideWith((ref) => _TestAuthRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.text('AVOV'), findsOneWidget);
    expect(
      find.text('Asistente Virtual de Orientación Vocacional'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Login muestra formulario de acceso', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _publicSettingsOverrides,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('AVOV'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Login usa app_display_name de settings públicas', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicSettingsProvider.overrideWith(
            (ref) async => const PublicSettings(
              appDisplayName: 'Instituto Demo AVOV',
              ethicalDisclaimer: 'Disclaimer demo.',
              maintenanceMode: false,
            ),
          ),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Instituto Demo AVOV'), findsOneWidget);
  });

  testWidgets('La app inicia sin errores de render', (tester) async {
    final router = GoRouter(
      initialLocation: RouteNames.login,
      routes: [
        GoRoute(
          path: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _publicSettingsOverrides,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
