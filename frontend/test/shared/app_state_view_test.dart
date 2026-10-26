import 'package:avov_frontend/shared/widgets/app_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppStateView.error muestra mensaje y reintento', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppStateView.error(
            message: 'No se pudo cargar',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retried, isTrue);
  });

  testWidgets('AppStateView.empty muestra acción opcional', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppStateView.empty(
            message: 'Sin registros',
            actionLabel: 'Crear',
            onAction: null,
          ),
        ),
      ),
    );

    expect(find.text('Sin registros'), findsOneWidget);
    expect(find.text('Crear'), findsNothing);
  });

  testWidgets('AppPageHeader renderiza título y subtítulo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppPageHeader(
            title: 'Panel',
            subtitle: 'Ana Pérez',
            caption: 'ana@escuela.test',
          ),
        ),
      ),
    );

    expect(find.text('Panel'), findsOneWidget);
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('ana@escuela.test'), findsOneWidget);
  });
}
