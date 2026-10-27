import 'dart:async';

import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/core/errors/failure_mapper.dart';
import 'package:avov_frontend/features/student/presentation/screens/student_dashboard_screen.dart';
import 'package:avov_frontend/features/student/presentation/screens/student_results_screen.dart';
import 'package:avov_frontend/features/auth/domain/auth_repository.dart';
import 'support/auth_repository_stubs.dart';
import 'package:avov_frontend/features/auth/domain/auth_tokens.dart';
import 'package:avov_frontend/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:avov_frontend/features/students/domain/managed_student.dart';
import 'package:avov_frontend/features/students/domain/student_repository.dart';
import 'package:avov_frontend/features/students/presentation/providers/students_provider.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_repository.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_test.dart';
import 'package:avov_frontend/features/vocational/presentation/providers/vocational_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  VocationalSession session(int id, {String status = 'COMPLETED'}) {
    return VocationalSession(
      id: id,
      studentId: 4,
      status: status,
      totalQuestions: 60,
      answeredCount: status == 'COMPLETED' ? 60 : 3,
      progressPercent: status == 'COMPLETED' ? 100 : 5,
      startedAt: DateTime.utc(2026, 1, id.clamp(1, 28)),
    );
  }

  testWidgets('historial vacío', (tester) async {
    final vocational = _PagedVocational();
    await _pumpDashboard(tester, vocational);
    expect(find.text('No tienes evaluaciones registradas.'), findsOneWidget);
    expect(find.text('Cargar más evaluaciones'), findsNothing);
    expect(vocational.listCalls, 1);
    expect(vocational.lastPageRequested, 1);
  });

  testWidgets('primera página con menos de 20 registros no ofrece cargar más',
      (tester) async {
    final vocational = _PagedVocational(
      all: [for (var i = 1; i <= 5; i++) session(i)],
    );
    await _pumpDashboard(tester, vocational);
    expect(find.textContaining('Evaluación Completada'), findsNWidgets(5));
    expect(find.text('Cargar más evaluaciones'), findsNothing);
    expect(vocational.listCalls, 1);
  });

  testWidgets('primera página llena muestra carga de la siguiente', (tester) async {
    final vocational = _PagedVocational(
      all: [for (var i = 1; i <= 25; i++) session(i)],
    );
    await _pumpDashboard(tester, vocational);
    expect(find.textContaining('Evaluación Completada'), findsNWidgets(20));
    expect(find.text('Cargar más evaluaciones'), findsOneWidget);
    expect(vocational.lastPageRequested, 1);
  });

  testWidgets('cargar más obtiene la página siguiente sin duplicados',
      (tester) async {
    final vocational = _PagedVocational(
      all: [for (var i = 1; i <= 25; i++) session(i)],
    );
    final container = await _pumpDashboard(tester, vocational);
    expect(find.byKey(const Key('vocational-history-load-more')), findsOneWidget);

    await container.read(vocationalHistoryProvider.notifier).loadMore();
    await tester.pumpAndSettle();

    expect(vocational.listCalls, 2);
    expect(vocational.lastPageRequested, 2);
    expect(
      container.read(vocationalHistoryProvider).requireValue.items.length,
      25,
    );
    expect(find.byKey(const Key('vocational-history-load-more')), findsNothing);

    final ids = container
        .read(vocationalHistoryProvider)
        .requireValue
        .items
        .map((item) => item.id)
        .toList();
    expect(ids.toSet().length, ids.length);
    expect(ids, [for (var i = 1; i <= 25; i++) i]);
  });

  testWidgets('error al cargar más conserva registros y permite reintentar',
      (tester) async {
    final vocational = _PagedVocational(
      all: [for (var i = 1; i <= 25; i++) session(i)],
      failFromPage: 2,
    );
    final container = await _pumpDashboard(tester, vocational);

    await container.read(vocationalHistoryProvider.notifier).loadMore();
    await tester.pumpAndSettle();

    final afterError = container.read(vocationalHistoryProvider).requireValue;
    expect(afterError.items.length, 20);
    expect(afterError.loadMoreError, FailureMapper.connectionMessage);
    expect(find.text('Reintentar carga'), findsOneWidget);

    vocational.failFromPage = null;
    await container.read(vocationalHistoryProvider.notifier).loadMore();
    await tester.pumpAndSettle();

    expect(
      container.read(vocationalHistoryProvider).requireValue.items.length,
      25,
    );
    expect(
      container.read(vocationalHistoryProvider).requireValue.loadMoreError,
      isNull,
    );
  });

  testWidgets('doble pulsación de cargar más no duplica la solicitud',
      (tester) async {
    final vocational = _SlowPagedVocational(
      all: [for (var i = 1; i <= 25; i++) session(i)],
    );
    final container = await _pumpDashboard(tester, vocational);

    final pending = container.read(vocationalHistoryProvider.notifier).loadMore();
    await tester.pump();
    final ignored = container.read(vocationalHistoryProvider.notifier).loadMore();
    await tester.pump();

    expect(vocational.listCalls, 2); // 1 inicial + 1 loadMore
    vocational.finishPage();
    await pending;
    await ignored;
    await tester.pumpAndSettle();
    expect(vocational.listCalls, 2);
  });

  testWidgets('refresh reinicia la paginación desde la página 1', (tester) async {
    final vocational = _PagedVocational(
      all: [for (var i = 1; i <= 25; i++) session(i)],
    );
    final container = await _pumpDashboard(tester, vocational);

    await container.read(vocationalHistoryProvider.notifier).loadMore();
    await tester.pumpAndSettle();
    expect(container.read(vocationalHistoryProvider).requireValue.page, 2);

    await container.read(vocationalHistoryProvider.notifier).refresh();
    await tester.pumpAndSettle();

    final state = container.read(vocationalHistoryProvider).requireValue;
    expect(state.page, 1);
    expect(state.items.length, 20);
    expect(vocational.lastPageRequested, 1);
  });

  testWidgets('resultados no muestran vacío mientras hay más páginas',
      (tester) async {
    final vocational = _PagedVocational(
      all: [
        for (var i = 1; i <= 20; i++) session(i, status: 'STARTED'),
        session(21, status: 'COMPLETED'),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_Auth()),
          studentRepositoryProvider.overrideWithValue(_Students()),
          vocationalRepositoryProvider.overrideWithValue(vocational),
        ],
        child: const MaterialApp(home: StudentResultsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text('No tienes resultados de evaluaciones completadas.'),
      findsNothing,
    );
    expect(
      find.textContaining('Puedes cargar más páginas del historial'),
      findsOneWidget,
    );
    expect(find.text('Cargar más evaluaciones'), findsOneWidget);
  });

  testWidgets('el cliente no envía student_id ajeno al listar', (tester) async {
    final vocational = _PagedVocational(all: [session(1)]);
    await _pumpDashboard(tester, vocational);
    expect(vocational.queriedStudentIds, isEmpty);
    expect(vocational.listQueryKeys, everyElement(isNot(contains('student'))));
  });
}

Future<ProviderContainer> _pumpDashboard(
  WidgetTester tester,
  VocationalRepository vocational,
) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_Auth()),
      studentRepositoryProvider.overrideWithValue(_Students()),
      vocationalRepositoryProvider.overrideWithValue(vocational),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: StudentDashboardScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

class _Auth with AuthRepositoryChangePasswordStub implements AuthRepository {
  @override
  Future<UserProfile> currentProfile() async {
    return const UserProfile(
      id: 9,
      email: 'lucia@escuela.test',
      firstName: 'Lucía',
      lastName: 'Vega',
      role: 'STUDENT',
      status: 'ACTIVE',
      institutionId: 7,
    );
  }

  @override
  Future<UserProfile> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> clearSession() async {}
  @override
  Future<String> forgotPassword({required String email}) async => '';

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async => '';

}

class _Students implements StudentRepository {
  @override
  Future<ManagedStudentPage> list(StudentListQuery query) {
    throw UnimplementedError();
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
      email: 'lucia@escuela.test',
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
  Future<ManagedStudent> update(int id, StudentDraft draft) =>
      throw UnimplementedError();

  @override
  Future<ManagedStudent> updateStatus(int id, String status) =>
      throw UnimplementedError();
}

class _PagedVocational implements VocationalRepository {
  _PagedVocational({
    this.all = const [],
    this.failFromPage,
  });

  final List<VocationalSession> all;
  int? failFromPage;
  int listCalls = 0;
  int lastPageRequested = 0;
  final List<int> queriedStudentIds = [];
  final List<String> listQueryKeys = [];

  @override
  Future<VocationalSessionPage> listSessions({
    int page = 1,
    int pageSize = 20,
  }) async {
    listCalls += 1;
    lastPageRequested = page;
    listQueryKeys.add('page=$page&page_size=$pageSize');
    if (failFromPage != null && page >= failFromPage!) {
      throw NetworkException(FailureMapper.connectionMessage);
    }
    final total = all.length;
    final pages = total == 0 ? 0 : ((total + pageSize - 1) ~/ pageSize);
    final start = (page - 1) * pageSize;
    final end = start + pageSize > total ? total : start + pageSize;
    final items = start >= total ? <VocationalSession>[] : all.sublist(start, end);
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
  Future<VocationalQuestionnaire> questions(int sessionId) {
    throw UnimplementedError();
  }

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

class _SlowPagedVocational extends _PagedVocational {
  _SlowPagedVocational({required super.all});

  final Completer<void> _gate = Completer<void>();

  void finishPage() {
    if (!_gate.isCompleted) {
      _gate.complete();
    }
  }

  @override
  Future<VocationalSessionPage> listSessions({
    int page = 1,
    int pageSize = 20,
  }) async {
    if (page > 1) {
      listCalls += 1;
      lastPageRequested = page;
      await _gate.future;
      final total = all.length;
      final pages = (total + pageSize - 1) ~/ pageSize;
      final start = (page - 1) * pageSize;
      final end = start + pageSize > total ? total : start + pageSize;
      return VocationalSessionPage(
        items: all.sublist(start, end),
        total: total,
        page: page,
        pages: pages,
      );
    }
    return super.listSessions(page: page, pageSize: pageSize);
  }
}
