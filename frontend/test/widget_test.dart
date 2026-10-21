import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avov_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:avov_frontend/features/splash/presentation/screens/splash_screen.dart';
import 'package:avov_frontend/main.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  testWidgets('Splash muestra la marca AVOV', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    expect(find.text('AVOV'), findsOneWidget);
    expect(
      find.text('Asistente Virtual de Orientación Vocacional'),
      findsOneWidget,
    );
  });

  testWidgets('Login muestra formulario de acceso', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('AVOV'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('La app inicia sin errores de render', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AvovApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
