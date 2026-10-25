import 'dart:async';

import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/core/errors/failure_mapper.dart';
import 'package:avov_frontend/core/providers/providers.dart';
import 'package:avov_frontend/core/storage/secure_token_storage.dart';
import 'package:avov_frontend/features/admin/domain/user_directory_repository.dart';
import 'package:avov_frontend/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:avov_frontend/features/auth/domain/auth_repository.dart';
import 'support/auth_repository_stubs.dart';
import 'package:avov_frontend/features/auth/domain/auth_tokens.dart';
import 'package:avov_frontend/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:avov_frontend/features/institutions/domain/institution.dart';
import 'package:avov_frontend/features/institutions/domain/institution_repository.dart';
import 'package:avov_frontend/features/student/presentation/screens/student_dashboard_screen.dart';
import 'package:avov_frontend/features/student/presentation/screens/student_profile_screen.dart';
import 'package:avov_frontend/features/students/domain/managed_student.dart';
import 'package:avov_frontend/features/students/domain/student_repository.dart';
import 'package:avov_frontend/features/students/presentation/providers/students_provider.dart';
import 'package:avov_frontend/features/vocational/domain/career_recommendation.dart';
import 'package:avov_frontend/features/vocational/domain/recommendation_repository.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_repository.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_test.dart';
import 'package:avov_frontend/features/vocational/presentation/providers/recommendation_provider.dart';
import 'package:avov_frontend/features/vocational/presentation/providers/vocational_provider.dart';
import 'package:avov_frontend/features/vocational/presentation/screens/vocational_result_screen.dart';
import 'package:avov_frontend/features/vocational/presentation/screens/vocational_test_screen.dart';
import 'package:avov_frontend/main.dart';
import 'package:avov_frontend/router/app_router.dart';
import 'package:avov_frontend/router/role_destination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const profile = UserProfile(
    id: 9,
    email: 'lucia@escuela.test',
    firstName: 'Lucía',
    lastName: 'Vega',
    role: 'STUDENT',
    status: 'ACTIVE',
    institutionId: 7,
  );

  const question = VocationalQuestion(
    id: 3,
    text: 'Me gusta reparar objetos',
    orderNumber: 1,
    categoryCode: 'R',
    categoryName: 'Realista',
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('el espacio /student queda reservado al estudiante', () {
    expect(routeMatchesRole('/student/dashboard', 'STUDENT'), isTrue);
    expect(routeMatchesRole('/student/profile', 'STUDENT'), isTrue);
    expect(routeMatchesRole('/student/test/4', 'COUNSELOR'), isFalse);
    expect(routeMatchesRole('/admin/dashboard', 'STUDENT'), isFalse);
    expect(routeMatchesRole('/institution/dashboard', 'STUDENT'), isFalse);
    expect(routeMatchesRole('/counselor/dashboard', 'STUDENT'), isFalse);
    expect(destinationForRole('STUDENT'), '/student/dashboard');
    expect(destinationForRole('SUPER_ADMIN'), '/admin/dashboard');
    expect(destinationForRole('INSTITUTION_ADMIN'), '/institution/dashboard');
    expect(destinationForRole('COUNSELOR'), '/counselor/dashboard');
  });

  testWidgets('el estudiante entra a su panel y no ve recomendaciones', (tester) async {
    await _pumpApp(tester, role: 'STUDENT', profile: profile);

    expect(find.text('Panel del estudiante'), findsOneWidget);
    expect(find.text('Lucía Vega'), findsWidgets);
    expect(find.text('lucia@escuela.test'), findsOneWidget);
    expect(find.text('Identificación: ID-PROPIA'), findsOneWidget);
    expect(find.text('Curso: 10'), findsOneWidget);
    expect(find.text('No tienes evaluaciones registradas.'), findsOneWidget);
    expect(
      find.textContaining(
        'Las recomendaciones de carreras se generan en el resultado',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('%'), findsNothing);
    expect(find.text('Iniciar evaluación'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cerrar sesión'), findsOneWidget);
  });

  testWidgets('otro rol no entra al espacio del estudiante', (tester) async {
    final container = await _appContainer(
      tester,
      role: 'COUNSELOR',
      profile: const UserProfile(
        id: 6,
        email: 'omar@escuela.test',
        firstName: 'Omar',
        lastName: 'León',
        role: 'COUNSELOR',
        status: 'ACTIVE',
        institutionId: 7,
      ),
    );
    container.read(goRouterProvider).go('/student/profile');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('No tienes permisos para acceder a esta sección.'),
      findsOneWidget,
    );
  });

  testWidgets('el perfil propio no consulta fichas ajenas', (tester) async {
    final students = _Students();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_Auth(profile)),
          studentRepositoryProvider.overrideWithValue(students),
        ],
        child: const MaterialApp(home: StudentProfileScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('lucia@escuela.test'), findsOneWidget);
    expect(find.text('Identificación: ID-PROPIA'), findsOneWidget);
    expect(find.textContaining('no puede modificarla'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(students.getCalls, 0);
    expect(students.ownCalls, 1);
  });

  testWidgets('el panel muestra carga, error y reintento', (tester) async {
    final auth = _PendingAuth(profile);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          studentRepositoryProvider.overrideWithValue(_Students()),
          vocationalRepositoryProvider.overrideWithValue(_Vocational()),
        ],
        child: const MaterialApp(home: StudentDashboardScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    auth.finish();
    await tester.pump();
    await tester.pump();

    expect(find.text('Lucía Vega'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _Auth(profile, error: UnauthorizedException()),
          ),
          studentRepositoryProvider.overrideWithValue(_Students()),
          vocationalRepositoryProvider.overrideWithValue(_Vocational()),
        ],
        child: const MaterialApp(home: StudentDashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Sesión expirada o no autorizada'), findsOneWidget);
    expect(find.textContaining('token'), findsNothing);
  });

  testWidgets('iniciar el test usa la sesión devuelta y no admite doble envío', (tester) async {
    final vocational = _SlowVocational();
    final router = GoRouter(
      initialLocation: '/student/dashboard',
      routes: [
        GoRoute(
          path: '/student/dashboard',
          builder: (context, state) => const StudentDashboardScreen(),
        ),
        GoRoute(
          path: '/student/test/:sessionId',
          builder: (context, state) => const Scaffold(body: Text('Cuestionario')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_Auth(profile)),
          studentRepositoryProvider.overrideWithValue(_Students()),
          vocationalRepositoryProvider.overrideWithValue(vocational),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Iniciar evaluación'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(vocational.startCalls, 1);
    vocational.finishStart();
    await tester.pump();
    await tester.pump();

    expect(find.text('Cuestionario'), findsOneWidget);
  });

  testWidgets('una finalización rechazada no muestra puntajes', (tester) async {
    final vocational = _Vocational(
      catalog: const [question],
      finishError: ValidationException('Faltan 1 respuestas para completar el test'),
    );
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

    expect(find.text('Me gusta reparar objetos'), findsOneWidget);
    await tester.tap(find.text('5 — Me gusta mucho'));
    await tester.pump();
    await tester.tap(find.text('Guardar respuesta'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Finalizar test'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Faltan 1 respuestas para completar el test'), findsOneWidget);
    expect(find.textContaining('Perfil', skipOffstage: true), findsNothing);
    expect(vocational.saved, 1);
    expect(vocational.finishCalls, 1);
  });

  testWidgets('403 y 404 del resultado no inventan un perfil', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vocationalRepositoryProvider.overrideWithValue(
            _Vocational(
              resultError: AppException(FailureMapper.forbiddenMessage, statusCode: 403),
            ),
          ),
        ],
        child: const MaterialApp(home: VocationalResultScreen(sessionId: 8)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(FailureMapper.forbiddenMessage), findsOneWidget);
    expect(find.textContaining('Perfil', skipOffstage: true), findsNothing);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vocationalRepositoryProvider.overrideWithValue(
            _Vocational(
              resultError: AppException('Resultado RIASEC no encontrado', statusCode: 404),
            ),
          ),
        ],
        child: const MaterialApp(home: VocationalResultScreen(sessionId: 8)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Resultado RIASEC no encontrado'), findsOneWidget);
    expect(find.textContaining('Realista:'), findsNothing);
  });

  testWidgets('el resultado muestra solo los puntajes del servidor', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vocationalRepositoryProvider.overrideWithValue(
            _Vocational(
              serverResult: const VocationalResult(
                testSessionId: 8,
                studentId: 4,
                scoreR: 40,
                scoreI: 12,
                scoreA: 8,
                scoreS: 10,
                scoreE: 9,
                scoreC: 11,
                dominantProfile: 'R',
                secondaryProfile: 'I',
                combinedProfile: 'RIS',
              ),
            ),
          ),
          recommendationRepositoryProvider.overrideWithValue(
            _EmptyRecommendations(),
          ),
        ],
        child: const MaterialApp(home: VocationalResultScreen(sessionId: 8)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perfil RIS'), findsOneWidget);
    expect(find.text('Realista: 40'), findsOneWidget);
    expect(find.textContaining('no reemplaza la orientación profesional'), findsWidgets);
    expect(find.text('Descargar PDF'), findsOneWidget);
    expect(find.text('Carreras recomendadas'), findsOneWidget);
    expect(
      find.textContaining('No hay carreras compatibles'),
      findsOneWidget,
    );
    expect(find.textContaining('Ese servicio no tiene operaciones'), findsNothing);
    expect(find.textContaining('Ingeniería'), findsNothing);
  });
}

class _EmptyRecommendations implements RecommendationRepository {
  @override
  Future<CareerRecommendationPage> listForSession(int sessionId) async {
    return const CareerRecommendationPage(
      testSessionId: 8,
      studentId: 4,
      riasecProfile: 'RIS',
      usedFallback: true,
      total: 0,
      items: [],
    );
  }

  @override
  Future<CareerRecommendationPage> generateForSession(int sessionId) async {
    return listForSession(sessionId);
  }
}

Future<ProviderContainer> _appContainer(
  WidgetTester tester, {
  required String role,
  required UserProfile profile,
}) async {
  FlutterSecureStorage.setMockInitialValues(<String, String>{
    SecureTokenStorage.accessTokenKey: 'access-de-prueba',
    SecureTokenStorage.refreshTokenKey: 'refresh-de-prueba',
    SecureTokenStorage.userRoleKey: role,
  });
  final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(_Auth(profile)),
      studentRepositoryProvider.overrideWithValue(_Students()),
      institutionRepositoryProvider.overrideWithValue(_Institutions()),
      userDirectoryRepositoryProvider.overrideWithValue(_Directory()),
      vocationalRepositoryProvider.overrideWithValue(_Vocational()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AvovApp()),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return container;
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required String role,
  required UserProfile profile,
}) async {
  await _appContainer(tester, role: role, profile: profile);
  await tester.pump();
  await tester.pump();
}

class _Auth with AuthRepositoryChangePasswordStub implements AuthRepository {
  _Auth(this.profile, {this.error});

  final UserProfile profile;
  final AppException? error;

  @override
  Future<UserProfile> currentProfile() async {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return profile;
  }

  @override
  Future<UserProfile> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> clearSession() async {}
}

class _PendingAuth extends _Auth {
  _PendingAuth(super.profile);

  final Completer<UserProfile> _pending = Completer<UserProfile>();

  void finish() {
    if (!_pending.isCompleted) {
      _pending.complete(profile);
    }
  }

  @override
  Future<UserProfile> currentProfile() => _pending.future;
}

class _Students implements StudentRepository {
  int getCalls = 0;

  @override
  Future<ManagedStudentPage> list(StudentListQuery query) {
    throw UnimplementedError();
  }

  int ownCalls = 0;

  @override
  Future<ManagedStudent> getOwn() async {
    ownCalls += 1;
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
      parallel: 'A',
    );
  }

  @override
  Future<ManagedStudent> getById(int id) async {
    getCalls += 1;
    throw AppException(FailureMapper.forbiddenMessage, statusCode: 403);
  }

  @override
  Future<ManagedStudent> create(StudentDraft draft) => throw UnimplementedError();

  @override
  Future<ManagedStudent> update(int id, StudentDraft draft) => throw UnimplementedError();

  @override
  Future<ManagedStudent> updateStatus(int id, String status) => throw UnimplementedError();
}

class _Vocational implements VocationalRepository {
  _Vocational({
    this.catalog = const [],
    this.finishError,
    this.resultError,
    this.serverResult,
  });

  final List<VocationalQuestion> catalog;
  final AppException? finishError;
  final AppException? resultError;
  final VocationalResult? serverResult;
  int startCalls = 0;
  int finishCalls = 0;
  int saved = 0;
  final Map<int, int> answers = {};

  @override
  @override
  Future<VocationalSessionPage> listSessions({int page = 1, int pageSize = 20}) async {
    return const VocationalSessionPage(items: [], total: 0, page: 1, pages: 0);
  }

  @override
  Future<VocationalSession> start() async {
    startCalls += 1;
    return const VocationalSession(
      id: 15,
      studentId: 4,
      status: 'STARTED',
      totalQuestions: 1,
      answeredCount: 0,
      progressPercent: 0,
    );
  }

  @override
  Future<VocationalQuestionnaire> questions(int sessionId) async {
    return VocationalQuestionnaire(
      session: VocationalSession(
        id: sessionId,
        studentId: 4,
        status: 'IN_PROGRESS',
        totalQuestions: catalog.length,
        answeredCount: answers.length,
        progressPercent: 0,
      ),
      questions: [
        for (final question in catalog)
          question.copyWithAnswer(answers[question.id]),
      ],
    );
  }

  @override
  Future<void> saveAnswer({
    required int sessionId,
    required int questionId,
    required int answerValue,
  }) async {
    saved += 1;
    answers[questionId] = answerValue;
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
  Future<VocationalResult> result(int sessionId) async {
    final failure = resultError;
    if (failure != null) {
      throw failure;
    }
    final value = serverResult;
    if (value != null) {
      return value;
    }
    throw UnimplementedError();
  }
}

class _SlowVocational extends _Vocational {
  final Completer<VocationalSession> _pending = Completer<VocationalSession>();

  void finishStart() {
    if (!_pending.isCompleted) {
      _pending.complete(
        const VocationalSession(
          id: 15,
          studentId: 4,
          status: 'STARTED',
          totalQuestions: 1,
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

class _Institutions implements InstitutionRepository {
  @override
  Future<InstitutionPage> list({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    return const InstitutionPage(items: [], total: 0, page: 1, pages: 0);
  }

  @override
  Future<Institution> getById(int id) => throw UnimplementedError();

  @override
  Future<Institution> create(InstitutionDraft draft) => throw UnimplementedError();

  @override
  Future<Institution> update(int id, InstitutionDraft draft) => throw UnimplementedError();

  @override
  Future<Institution> deactivate(int id) => throw UnimplementedError();

  @override
  Future<Institution> activate(int id) => throw UnimplementedError();
}

class _Directory implements UserDirectoryRepository {
  @override
  Future<int> count() async => 0;
}
