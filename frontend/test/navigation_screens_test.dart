import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:avov_frontend/core/models/public_settings.dart';
import 'package:avov_frontend/core/providers/public_settings_provider.dart';
import 'package:avov_frontend/features/auth/presentation/screens/maintenance_screen.dart';
import 'package:avov_frontend/features/auth/presentation/screens/unauthorized_screen.dart';
import 'package:avov_frontend/router/route_names.dart';

const _testPublicSettings = PublicSettings(
  appDisplayName: 'AVOV Prueba',
  ethicalDisclaimer: 'Mensaje ético de prueba.',
  maintenanceMode: true,
);

void main() {
  group('Pantallas de acceso', () {
    testWidgets('UnauthorizedScreen muestra mensaje y botón', (tester) async {
      final router = GoRouter(
        initialLocation: RouteNames.unauthorized,
        routes: [
          GoRoute(
            path: RouteNames.unauthorized,
            builder: (context, state) => const UnauthorizedScreen(),
          ),
          GoRoute(
            path: RouteNames.login,
            builder: (context, state) => const Scaffold(body: Text('Login')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acceso no autorizado'), findsOneWidget);
      expect(
        find.text('No tienes permisos para acceder a esta sección.'),
        findsOneWidget,
      );
      expect(find.text('Volver al inicio de sesión'), findsOneWidget);
    });

    testWidgets('MaintenanceScreen muestra nombre dinámico de la app',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            publicSettingsProvider.overrideWith(
              (ref) async => _testPublicSettings,
            ),
          ],
          child: const MaterialApp(
            home: MaintenanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mantenimiento'), findsOneWidget);
      expect(
        find.textContaining('AVOV Prueba no está disponible'),
        findsOneWidget,
      );
      expect(find.text('Acceso administrador'), findsOneWidget);
    });
  });
}
