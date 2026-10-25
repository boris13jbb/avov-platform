import 'package:avov_frontend/features/observations/presentation/widgets/observation_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ObservationForm valida texto vacío', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ObservationForm(
            onSubmit: (_) async {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('observation-submit')));
    await tester.pump();

    expect(find.text('El campo observación es obligatorio'), findsOneWidget);
  });

  testWidgets('ObservationForm envía texto válido', (tester) async {
    String? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ObservationForm(
            onSubmit: (text) async {
              captured = text;
            },
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('observation-text')),
      'Seguimiento vocacional positivo.',
    );
    await tester.tap(find.byKey(const Key('observation-submit')));
    await tester.pumpAndSettle();

    expect(captured, 'Seguimiento vocacional positivo.');
  });
}
