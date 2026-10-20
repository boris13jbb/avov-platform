import 'dart:async';

import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/core/errors/failure_mapper.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_repository.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_test.dart';
import 'package:avov_frontend/features/vocational/presentation/providers/vocational_provider.dart';
import 'package:avov_frontend/features/vocational/presentation/screens/vocational_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const q1 = VocationalQuestion(
    id: 1,
    text: 'Me gusta reparar objetos',
    orderNumber: 1,
    categoryCode: 'R',
    categoryName: 'Realista',
  );
  const q2 = VocationalQuestion(
    id: 2,
    text: 'Me gusta resolver problemas',
    orderNumber: 2,
    categoryCode: 'I',
    categoryName: 'Investigador',
  );

  testWidgets('seleccionar y guardar confirma en el servidor', (tester) async {
    final vocational = _Vocational(catalog: const [q1, q2]);
    await _pump(tester, vocational);

    await tester.tap(find.text('5 — Me gusta mucho'));
    await tester.pump();
    expect(
      find.textContaining('Selección pendiente de guardar'),
      findsOneWidget,
    );
    await tester.tap(find.text('Guardar respuesta'));
    await tester.pump();
    await tester.pump();

    expect(vocational.savedAnswers, {1: 5});
    expect(
      find.text('Respuesta confirmada por el servidor.'),
      findsOneWidget,
    );
    expect(find.text('Respuestas guardadas: 1 de 2'), findsOneWidget);
  });

  testWidgets('cambiar una respuesta guardada y volver a guardar', (tester) async {
    final vocational = _Vocational(
      catalog: const [q1, q2],
      answers: {1: 2},
    );
    await _pump(tester, vocational);

    expect(
      find.text('Respuesta confirmada por el servidor.'),
      findsOneWidget,
    );
    await tester.tap(find.text('4'));
    await tester.pump();
    expect(
      find.textContaining('Selección pendiente de guardar'),
      findsOneWidget,
    );
    await tester.tap(find.text('Guardar respuesta'));
    await tester.pump();
    await tester.pump();

    expect(vocational.savedAnswers[1], 4);
    expect(
      find.text('Respuesta confirmada por el servidor.'),
      findsOneWidget,
    );
  });

  testWidgets('cambiar de pregunta con selección sin guardar muestra aviso',
      (tester) async {
    final vocational = _Vocational(
      catalog: const [q1, q2],
      answers: {1: 3},
    );
    await _pump(tester, vocational);

    await tester.tap(find.text('5 — Me gusta mucho'));
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('Respuesta sin guardar'), findsOneWidget);
    expect(find.text('Me gusta reparar objetos'), findsOneWidget);
    expect(vocational.savedAnswers[1], 3);
  });

  testWidgets('guardar desde el aviso y luego navegar', (tester) async {
    final vocational = _Vocational(
      catalog: const [q1, q2],
      answers: {1: 3},
    );
    await _pump(tester, vocational);

    await tester.tap(find.text('5 — Me gusta mucho'));
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(vocational.savedAnswers[1], 5);
    expect(find.text('Me gusta resolver problemas'), findsOneWidget);
  });

  testWidgets('descartar solo elimina la selección no guardada', (tester) async {
    final vocational = _Vocational(
      catalog: const [q1, q2],
      answers: {1: 3},
    );
    await _pump(tester, vocational);

    await tester.tap(find.text('5 — Me gusta mucho'));
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(vocational.savedAnswers[1], 3);
    expect(find.text('Me gusta resolver problemas'), findsOneWidget);

    await tester.tap(find.text('Anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Respuesta confirmada por el servidor.'), findsOneWidget);
    expect(find.textContaining('Selección pendiente de guardar'), findsNothing);
  });

  testWidgets('cancelar conserva la selección local', (tester) async {
    final vocational = _Vocational(
      catalog: const [q1, q2],
      answers: {1: 3},
    );
    await _pump(tester, vocational);

    await tester.tap(find.text('5 — Me gusta mucho'));
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Me gusta reparar objetos'), findsOneWidget);
    expect(
      find.textContaining('Selección pendiente de guardar'),
      findsOneWidget,
    );
    expect(vocational.savedAnswers[1], 3);
  });

  testWidgets('fallo de red al guardar conserva la selección y permite reintentar',
      (tester) async {
    final vocational = _Vocational(
      catalog: const [q1],
      saveError: NetworkException(FailureMapper.connectionMessage),
    );
    await _pump(tester, vocational);

    await tester.tap(find.text('5 — Me gusta mucho'));
    await tester.pump();
    await tester.tap(find.text('Guardar respuesta'));
    await tester.pump();
    await tester.pump();

    expect(vocational.saveCalls, 1);
    expect(vocational.savedAnswers.containsKey(1), isFalse);
    expect(find.textContaining('No se confirmó el guardado'), findsOneWidget);
    expect(
      find.textContaining('Selección pendiente de guardar'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('vocational-save-answer')), findsOneWidget);

    vocational.saveError = null;
    final retry = find.byKey(const Key('vocational-save-answer'));
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pump();
    await tester.pump();

    expect(vocational.saveCalls, 2);
    expect(vocational.savedAnswers[1], 5);
    expect(
      find.text('Respuesta confirmada por el servidor.'),
      findsOneWidget,
    );
  });

  testWidgets('guardado en curso no admite segundo envío ni cambio de pregunta',
      (tester) async {
    final vocational = _SlowSaveVocational(catalog: const [q1, q2]);
    await _pump(tester, vocational);

    await tester.tap(find.text('5 — Me gusta mucho'));
    await tester.pump();
    await tester.tap(find.text('Guardar respuesta'));
    await tester.pump();

    expect(vocational.saveCalls, 1);
    await tester.tap(find.text('Guardar respuesta'));
    await tester.pump();
    expect(vocational.saveCalls, 1);

    final next = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Siguiente'),
    );
    expect(next.onPressed, isNull);

    vocational.finishSave();
    await tester.pump();
    await tester.pump();
    expect(vocational.savedAnswers[1], 5);
  });

  testWidgets('volver a una pregunta muestra la respuesta confirmada',
      (tester) async {
    final vocational = _Vocational(
      catalog: const [q1, q2],
      answers: {1: 4, 2: 2},
    );
    await _pump(tester, vocational);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Me gusta resolver problemas'), findsOneWidget);

    await tester.tap(find.text('Anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Me gusta reparar objetos'), findsOneWidget);
    expect(
      find.text('Respuesta confirmada por el servidor.'),
      findsOneWidget,
    );
  });

  testWidgets('finalizar rechazado no inventa resultado y backend manda',
      (tester) async {
    final vocational = _Vocational(
      catalog: const [q1],
      answers: {1: 5},
      finishError: ValidationException(
        'Faltan 1 respuestas para completar el test',
      ),
    );
    await _pump(tester, vocational);

    await tester.tap(find.text('Finalizar test'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Faltan 1 respuestas para completar el test'), findsOneWidget);
    expect(find.textContaining('Perfil', skipOffstage: true), findsNothing);
    expect(vocational.finishCalls, 1);
  });
}

Future<void> _pump(WidgetTester tester, VocationalRepository vocational) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vocationalRepositoryProvider.overrideWithValue(vocational),
      ],
      child: const MaterialApp(home: VocationalTestScreen(sessionId: 15)),
    ),
  );
  await tester.pump();
  await tester.pump();
}

class _Vocational implements VocationalRepository {
  _Vocational({
    required this.catalog,
    Map<int, int>? answers,
    this.saveError,
    this.finishError,
  }) : savedAnswers = Map<int, int>.from(answers ?? const {});

  final List<VocationalQuestion> catalog;
  final Map<int, int> savedAnswers;
  AppException? saveError;
  final AppException? finishError;
  int saveCalls = 0;
  int finishCalls = 0;

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
  Future<VocationalQuestionnaire> questions(int sessionId) async {
    return VocationalQuestionnaire(
      session: VocationalSession(
        id: sessionId,
        studentId: 4,
        status: 'IN_PROGRESS',
        totalQuestions: catalog.length,
        answeredCount: savedAnswers.length,
        progressPercent: 0,
      ),
      questions: [
        for (final question in catalog)
          question.copyWithAnswer(savedAnswers[question.id]),
      ],
    );
  }

  @override
  Future<void> saveAnswer({
    required int sessionId,
    required int questionId,
    required int answerValue,
  }) async {
    saveCalls += 1;
    final failure = saveError;
    if (failure != null) {
      throw failure;
    }
    savedAnswers[questionId] = answerValue;
  }

  @override
  Future<VocationalResult> finish(int sessionId) async {
    finishCalls += 1;
    final failure = finishError;
    if (failure != null) {
      throw failure;
    }
    throw UnimplementedError();
  }

  @override
  Future<VocationalResult> result(int sessionId) => throw UnimplementedError();
}

class _SlowSaveVocational extends _Vocational {
  _SlowSaveVocational({required super.catalog}) : super();

  final Completer<void> _pending = Completer<void>();

  void finishSave() {
    if (!_pending.isCompleted) {
      _pending.complete();
    }
  }

  @override
  Future<void> saveAnswer({
    required int sessionId,
    required int questionId,
    required int answerValue,
  }) async {
    saveCalls += 1;
    await _pending.future;
    savedAnswers[questionId] = answerValue;
  }
}
