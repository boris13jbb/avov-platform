import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/core/errors/failure_mapper.dart';
import 'package:avov_frontend/features/vocational/domain/career_recommendation.dart';
import 'package:avov_frontend/features/vocational/domain/recommendation_repository.dart';
import 'package:avov_frontend/features/vocational/domain/report_history.dart';
import 'package:avov_frontend/features/vocational/domain/report_repository.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_repository.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_test.dart';
import 'package:avov_frontend/features/vocational/presentation/providers/recommendation_provider.dart';
import 'package:avov_frontend/features/vocational/presentation/providers/report_provider.dart';
import 'package:avov_frontend/features/vocational/presentation/providers/vocational_provider.dart';
import 'package:avov_frontend/features/vocational/presentation/screens/vocational_result_screen.dart';
import 'package:avov_frontend/features/vocational/presentation/screens/vocational_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _EmptyRecRepo implements RecommendationRepository {
  @override
  Future<CareerRecommendationPage> listForSession(int sessionId) async {
    return CareerRecommendationPage(
      testSessionId: sessionId,
      studentId: 4,
      riasecProfile: 'R',
      usedFallback: false,
      total: 0,
      items: const [],
    );
  }

  @override
  Future<CareerRecommendationPage> generateForSession(int sessionId) async {
    return listForSession(sessionId);
  }
}

class _NoopReportRepo implements ReportRepository {
  @override
  Future<VocationalPdfFile> downloadSessionPdf(int sessionId) async {
    throw AppException('No usado en esta prueba');
  }

  @override
  Future<ReportHistoryPage> listStudentReports(
    int studentId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    throw AppException('No usado en esta prueba');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const question = VocationalQuestion(
    id: 1,
    text: 'Me gusta reparar objetos',
    orderNumber: 1,
    categoryCode: 'R',
    categoryName: 'Realista',
  );

  VocationalSession openSession(int id) => VocationalSession(
        id: id,
        studentId: 4,
        status: 'IN_PROGRESS',
        totalQuestions: 1,
        answeredCount: 1,
        progressPercent: 100,
        startedAt: DateTime.utc(2026, 2, id.clamp(1, 28)),
      );

  VocationalSession completedSession(int id) => VocationalSession(
        id: id,
        studentId: 4,
        status: 'COMPLETED',
        totalQuestions: 1,
        answeredCount: 1,
        progressPercent: 100,
        startedAt: DateTime.utc(2026, 3, id.clamp(1, 28)),
      );

  testWidgets('finalización exitosa refresca el historial desde la página 1',
      (tester) async {
    final vocational = _SyncVocational(
      catalog: const [question],
      answers: {1: 5},
      historyBeforeFinish: [
        for (var i = 1; i <= 22; i++) openSession(i),
      ],
      historyAfterFinish: [
        completedSession(22),
        for (var i = 1; i <= 21; i++) openSession(i),
      ],
    );
    final container = await _pumpFinishFlow(tester, vocational);
    final sub = container.listen(vocationalHistoryProvider, (_, __) {});
    addTearDown(sub.close);

    await container.read(vocationalHistoryProvider.future);
    await container.read(vocationalHistoryProvider.notifier).loadMore();
    await tester.pumpAndSettle();
    expect(container.read(vocationalHistoryProvider).requireValue.page, 2);

    await tester.tap(find.text('Finalizar test'));
    await tester.pumpAndSettle();

    expect(vocational.finishCalls, 1);
    expect(vocational.lastListPage, 1);
    final history = container.read(vocationalHistoryProvider).requireValue;
    expect(history.page, 1);
    expect(history.items.first.id, 22);
    expect(history.items.first.isCompleted, isTrue);
    expect(history.items.length, 20);
    expect(find.text('Resultado vocacional'), findsOneWidget);
  });

  testWidgets('finalización fallida no se presenta como éxito ni refresca',
      (tester) async {
    final vocational = _SyncVocational(
      catalog: const [question],
      answers: {1: 5},
      finishError: ValidationException(
        'Faltan 1 respuestas para completar el test',
      ),
      historyBeforeFinish: [openSession(9)],
    );
    final container = await _pumpFinishFlow(tester, vocational);
    final sub = container.listen(vocationalHistoryProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(vocationalHistoryProvider.future);
    final listsBefore = vocational.listCalls;

    await tester.tap(find.text('Finalizar test'));
    await tester.pumpAndSettle();

    expect(vocational.finishCalls, 1);
    expect(find.text('Faltan 1 respuestas para completar el test'), findsOneWidget);
    expect(find.text('Resultado vocacional'), findsNothing);
    expect(vocational.listCalls, listsBefore);
    expect(
      container.read(vocationalHistoryProvider).requireValue.items.single.status,
      'IN_PROGRESS',
    );
  });

  testWidgets(
      'historial fallido tras finish confirmado permite reintentar sin finalizar otra vez',
      (tester) async {
    final vocational = _SyncVocational(
      catalog: const [question],
      answers: {1: 5},
      historyBeforeFinish: [openSession(3)],
      historyAfterFinish: [completedSession(3)],
      historyFailuresAfterFinish: 1,
    );
    await _pumpFinishFlow(tester, vocational);

    await tester.tap(find.text('Finalizar test'));
    await tester.pumpAndSettle();

    expect(vocational.finishCalls, 1);
    expect(find.text('Evaluación finalizada'), findsOneWidget);
    expect(
      find.textContaining('no se pudo actualizar el historial'),
      findsOneWidget,
    );

    await tester.tap(find.text('Reintentar historial'));
    await tester.pumpAndSettle();

    expect(vocational.finishCalls, 1);
    expect(find.text('Resultado vocacional'), findsOneWidget);
  });

  testWidgets(
      'ver resultado tras fallo de historial no vuelve a llamar finish',
      (tester) async {
    final vocational = _SyncVocational(
      catalog: const [question],
      answers: {1: 5},
      historyBeforeFinish: [openSession(4)],
      historyAfterFinish: [completedSession(4)],
      historyFailuresAfterFinish: 2,
    );
    await _pumpFinishFlow(tester, vocational);

    await tester.tap(find.text('Finalizar test'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver resultado'));
    await tester.pumpAndSettle();

    expect(vocational.finishCalls, 1);
    expect(find.text('Resultado vocacional'), findsOneWidget);
  });

  testWidgets('refresh no mezcla páginas antiguas con la nueva primera página',
      (tester) async {
    final vocational = _SyncVocational(
      historyBeforeFinish: [
        for (var i = 1; i <= 25; i++) openSession(i),
      ],
      historyAfterFinish: [
        completedSession(99),
        for (var i = 1; i <= 24; i++) openSession(i),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        vocationalRepositoryProvider.overrideWithValue(vocational),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(vocationalHistoryProvider, (_, __) {});
    addTearDown(sub.close);

    await container.read(vocationalHistoryProvider.future);
    await container.read(vocationalHistoryProvider.notifier).loadMore();
    expect(container.read(vocationalHistoryProvider).requireValue.items.length, 25);

    vocational.markFinished();
    final ok = await container.read(vocationalHistoryProvider.notifier).refresh();
    expect(ok, isTrue);

    final state = container.read(vocationalHistoryProvider).requireValue;
    expect(state.page, 1);
    expect(state.items.length, 20);
    expect(state.items.first.id, 99);
    expect(state.items.any((item) => item.id == 25), isFalse);
  });
}

Future<ProviderContainer> _pumpFinishFlow(
  WidgetTester tester,
  _SyncVocational vocational,
) async {
  final router = GoRouter(
    initialLocation: '/student/test/15',
    routes: [
      GoRoute(
        path: '/student/test/:sessionId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['sessionId']!);
          return VocationalTestScreen(sessionId: id);
        },
      ),
      GoRoute(
        path: '/student/test/:sessionId/result',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['sessionId']!);
          return VocationalResultScreen(sessionId: id);
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      vocationalRepositoryProvider.overrideWithValue(vocational),
      // Resultado monta recomendaciones/PDF: evitar Dio real y hangs de carga.
      recommendationRepositoryProvider.overrideWithValue(_EmptyRecRepo()),
      reportRepositoryProvider.overrideWithValue(_NoopReportRepo()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

class _SyncVocational implements VocationalRepository {
  _SyncVocational({
    this.catalog = const [],
    Map<int, int>? answers,
    this.finishError,
    List<VocationalSession>? historyBeforeFinish,
    List<VocationalSession>? historyAfterFinish,
    this.historyFailuresAfterFinish = 0,
  })  : savedAnswers = Map<int, int>.from(answers ?? const {}),
        _history = List<VocationalSession>.from(
          historyBeforeFinish ?? const <VocationalSession>[],
        ),
        _historyAfterFinish = List<VocationalSession>.from(
          historyAfterFinish ?? historyBeforeFinish ?? const <VocationalSession>[],
        );

  final List<VocationalQuestion> catalog;
  final Map<int, int> savedAnswers;
  final AppException? finishError;
  final List<VocationalSession> _historyAfterFinish;
  List<VocationalSession> _history;
  int historyFailuresAfterFinish;
  bool _finished = false;
  int finishCalls = 0;
  int listCalls = 0;
  int lastListPage = 0;

  void markFinished() {
    _finished = true;
    _history = List<VocationalSession>.from(_historyAfterFinish);
  }

  @override
  Future<VocationalSessionPage> listSessions({
    int page = 1,
    int pageSize = 20,
  }) async {
    listCalls += 1;
    lastListPage = page;
    if (_finished && historyFailuresAfterFinish > 0) {
      historyFailuresAfterFinish -= 1;
      throw NetworkException(FailureMapper.connectionMessage);
    }
    final source = _history;
    final total = source.length;
    final pages = total == 0 ? 0 : ((total + pageSize - 1) ~/ pageSize);
    final start = (page - 1) * pageSize;
    final end = start + pageSize > total ? total : start + pageSize;
    final items =
        start >= total ? <VocationalSession>[] : source.sublist(start, end);
    return VocationalSessionPage(
      items: items,
      total: total,
      page: page,
      pages: pages,
    );
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
        progressPercent: 100,
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
    savedAnswers[questionId] = answerValue;
  }

  @override
  Future<VocationalResult> finish(int sessionId) async {
    finishCalls += 1;
    final failure = finishError;
    if (failure != null) {
      throw failure;
    }
    markFinished();
    return const VocationalResult(
      testSessionId: 15,
      studentId: 4,
      scoreR: 5,
      scoreI: 0,
      scoreA: 0,
      scoreS: 0,
      scoreE: 0,
      scoreC: 0,
      dominantProfile: 'R',
      combinedProfile: 'R',
    );
  }

  @override
  Future<VocationalResult> result(int sessionId) async {
    return VocationalResult(
      testSessionId: sessionId,
      studentId: 4,
      scoreR: 5,
      scoreI: 0,
      scoreA: 0,
      scoreS: 0,
      scoreE: 0,
      scoreC: 0,
      dominantProfile: 'R',
      combinedProfile: 'R',
    );
  }
}
