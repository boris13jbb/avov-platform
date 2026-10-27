import 'dart:async';

import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/core/errors/failure_mapper.dart';
import 'package:avov_frontend/features/auth/domain/auth_repository.dart';
import 'support/auth_repository_stubs.dart';
import 'package:avov_frontend/features/auth/domain/auth_tokens.dart';
import 'package:avov_frontend/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:avov_frontend/features/student/presentation/screens/student_test_home_screen.dart';
import 'package:avov_frontend/features/student/presentation/widgets/open_vocational_session_tile.dart';
import 'package:avov_frontend/features/students/domain/managed_student.dart';
import 'package:avov_frontend/features/students/domain/student_repository.dart';
import 'package:avov_frontend/features/students/presentation/providers/students_provider.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_repository.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_test.dart';
import 'package:avov_frontend/features/vocational/presentation/providers/vocational_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final firstOpen = VocationalSession(
    id: 21,
    studentId: 4,
    status: 'STARTED',
    totalQuestions: 60,
    answeredCount: 2,
    progressPercent: 3.3,
    startedAt: DateTime.utc(2026, 3, 10, 14, 30),
  );
  final secondOpen = VocationalSession(
    id: 22,
    studentId: 4,
    status: 'IN_PROGRESS',
    totalQuestions: 60,
    answeredCount: 18,
    progressPercent: 30,
    startedAt: DateTime.utc(2026, 3, 12, 9, 5),
  );

  testWidgets('historial sin evaluaciones abiertas muestra inicio explícito',
      (tester) async {
    final vocational = _VocationalHistory();
    await _pumpTestHome(tester, vocational);

    expect(find.text('No tienes una evaluación en curso.'), findsOneWidget);
    expect(find.text('Iniciar evaluación'), findsOneWidget);
    expect(find.text('Continuar esta evaluación'), findsNothing);
    expect(vocational.startCalls, 0);
  });

  testWidgets('exactamente una evaluación abierta ofrece continuar', (tester) async {
    final vocational = _VocationalHistory(sessions: [firstOpen]);
    await _pumpTestHome(tester, vocational);

    expect(find.textContaining('Evaluación Iniciada'), findsOneWidget);
    expect(find.text('Continuar esta evaluación'), findsOneWidget);
    expect(find.text('Iniciar evaluación'), findsNothing);
    expect(find.text(MultipleOpenSessionsNotice.message), findsNothing);
    expect(vocational.startCalls, 0);
  });

  testWidgets('varias evaluaciones abiertas se listan sin iniciar otra',
      (tester) async {
    final vocational = _VocationalHistory(sessions: [firstOpen, secondOpen]);
    await _pumpTestHome(tester, vocational);

    expect(find.text(MultipleOpenSessionsNotice.message), findsWidgets);
    expect(find.text('Continuar esta evaluación'), findsNWidgets(2));
    expect(find.text('Iniciar evaluación'), findsNothing);
    expect(
      find.textContaining('No puedes iniciar otra evaluación'),
      findsOneWidget,
    );
    expect(vocational.startCalls, 0);
  });

  testWidgets('continuar la segunda evaluación usa su identificador',
      (tester) async {
    final vocational = _VocationalHistory(sessions: [firstOpen, secondOpen]);
    final visited = <int>[];
    await _pumpTestHome(
      tester,
      vocational,
      onOpenSession: (id) => visited.add(id),
    );

    await tester.tap(find.byKey(const ValueKey('continue-open-22')));
    await tester.pumpAndSettle();

    expect(visited, [22]);
    expect(find.text('Sesión abierta 22'), findsOneWidget);
    expect(vocational.startCalls, 0);
  });

  testWidgets('422 por varias abiertas refresca el historial y no reintenta start',
      (tester) async {
    final vocational = _VocationalHistory(
      sessions: const [],
      startError: ValidationException(
        'Hay más de una evaluación en progreso. '
        'No se inicia otra ni se elige una automáticamente.',
      ),
      afterStartFailureSessions: [firstOpen, secondOpen],
    );
    await _pumpTestHome(tester, vocational);

    expect(find.text('Iniciar evaluación'), findsOneWidget);
    await tester.tap(find.text('Iniciar evaluación'));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(vocational.startCalls, 1);
    expect(vocational.listCalls, greaterThanOrEqualTo(2));
    expect(find.text(MultipleOpenSessionsNotice.message), findsWidgets);
    expect(find.text('Continuar esta evaluación'), findsNWidgets(2));
    expect(find.text('Iniciar evaluación'), findsNothing);
  });

  testWidgets('error de red al refrescar tras 422 ofrece reintento',
      (tester) async {
    final vocational = _VocationalHistory(
      sessions: const [],
      startError: ValidationException(
        'Hay más de una evaluación en progreso. '
        'No se inicia otra ni se elige una automáticamente.',
      ),
      refreshErrorAfterStart: NetworkException(FailureMapper.connectionMessage),
    );
    await _pumpTestHome(tester, vocational);

    await tester.tap(find.text('Iniciar evaluación'));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text(FailureMapper.connectionMessage), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(vocational.startCalls, 1);

    vocational.refreshErrorAfterStart = null;
    vocational.afterStartFailureSessions = [firstOpen, secondOpen];
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Continuar esta evaluación'), findsNWidgets(2));
    expect(vocational.startCalls, 1);
  });

  testWidgets('entrar a la sección no inicia el test automáticamente',
      (tester) async {
    final vocational = _VocationalHistory(sessions: [firstOpen]);
    await _pumpTestHome(tester, vocational);
    await tester.pump(const Duration(milliseconds: 200));

    expect(vocational.startCalls, 0);
  });

  testWidgets('doble pulsación de iniciar no duplica start', (tester) async {
    final vocational = _SlowStartVocational();
    await _pumpTestHome(tester, vocational);

    await tester.tap(find.text('Iniciar evaluación'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(vocational.startCalls, 1);
    vocational.finishStart();
    await tester.pumpAndSettle();
    expect(find.text('Sesión abierta 15'), findsOneWidget);
  });
}

Future<void> _pumpTestHome(
  WidgetTester tester,
  _VocationalHistory vocational, {
  void Function(int sessionId)? onOpenSession,
}) async {
  final router = GoRouter(
    initialLocation: '/student/test',
    routes: [
      GoRoute(
        path: '/student/test',
        builder: (context, state) => const StudentTestHomeScreen(),
      ),
      GoRoute(
        path: '/student/test/:sessionId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['sessionId']!);
          onOpenSession?.call(id);
          return Scaffold(body: Text('Sesión abierta $id'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_Auth()),
        studentRepositoryProvider.overrideWithValue(_Students()),
        vocationalRepositoryProvider.overrideWithValue(vocational),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();
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

class _VocationalHistory implements VocationalRepository {
  _VocationalHistory({
    this.sessions = const [],
    this.startError,
    this.afterStartFailureSessions,
    this.refreshErrorAfterStart,
  });

  List<VocationalSession> sessions;
  final AppException? startError;
  List<VocationalSession>? afterStartFailureSessions;
  AppException? refreshErrorAfterStart;
  int startCalls = 0;
  int listCalls = 0;
  bool _startFailedOnce = false;

  @override
  Future<VocationalSessionPage> listSessions({
    int page = 1,
    int pageSize = 20,
  }) async {
    listCalls += 1;
    if (_startFailedOnce && refreshErrorAfterStart != null) {
      throw refreshErrorAfterStart!;
    }
    final items = _startFailedOnce && afterStartFailureSessions != null
        ? afterStartFailureSessions!
        : sessions;
    return VocationalSessionPage(
      items: items,
      total: items.length,
      page: 1,
      pages: items.isEmpty ? 0 : 1,
    );
  }

  @override
  Future<VocationalSession> start() async {
    startCalls += 1;
    final failure = startError;
    if (failure != null) {
      _startFailedOnce = true;
      throw failure;
    }
    return const VocationalSession(
      id: 15,
      studentId: 4,
      status: 'STARTED',
      totalQuestions: 60,
      answeredCount: 0,
      progressPercent: 0,
    );
  }

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
  Future<VocationalResult> finish(int sessionId) {
    throw UnimplementedError();
  }

  @override
  Future<VocationalResult> result(int sessionId) {
    throw UnimplementedError();
  }
}

class _SlowStartVocational extends _VocationalHistory {
  final Completer<VocationalSession> _pending = Completer<VocationalSession>();

  void finishStart() {
    if (!_pending.isCompleted) {
      _pending.complete(
        const VocationalSession(
          id: 15,
          studentId: 4,
          status: 'STARTED',
          totalQuestions: 60,
          answeredCount: 0,
          progressPercent: 0,
        ),
      );
    }
  }

  @override
  Future<VocationalSession> start() {
    startCalls += 1;
    return _pending.future;
  }
}
