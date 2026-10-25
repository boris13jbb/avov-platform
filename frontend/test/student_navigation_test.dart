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
import 'package:avov_frontend/features/students/domain/managed_student.dart';
import 'package:avov_frontend/features/students/domain/student_repository.dart';
import 'package:avov_frontend/features/students/presentation/providers/students_provider.dart';
import 'package:avov_frontend/features/users/domain/managed_user.dart';
import 'package:avov_frontend/features/users/domain/user_account_repository.dart';
import 'package:avov_frontend/features/users/presentation/providers/users_provider.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_repository.dart';
import 'package:avov_frontend/features/vocational/domain/vocational_test.dart';
import 'package:avov_frontend/features/vocational/presentation/providers/vocational_provider.dart';
import 'package:avov_frontend/main.dart';
import 'package:avov_frontend/router/app_router.dart';
import 'package:avov_frontend/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('el menú del estudiante abre, marca la sección y navega', (tester) async {
    final vocational = _Vocational();
    final container = await _pumpStudent(tester, vocational: vocational);

    expect(find.byTooltip('Abrir menú'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);

    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Test vocacional'), findsWidgets);
    expect(find.text('Resultados'), findsWidgets);
    expect(find.text('Perfil'), findsWidgets);
    expect(_tile(tester, 'Inicio').selected, isTrue);

    await tester.tapAt(const Offset(700, 200));
    await tester.pumpAndSettle();
    expect(find.text('Inicio', skipOffstage: true), findsNothing);

    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Test vocacional'));
    await tester.pumpAndSettle();

    expect(find.text('No tienes una evaluación en curso.'), findsOneWidget);
    expect(vocational.startCalls, 0);
    expect(_visibleTile(tester, 'Test vocacional'), isNull);

    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    expect(_tile(tester, 'Test vocacional').selected, isTrue);
    await tester.tap(find.widgetWithText(ListTile, 'Resultados'));
    await tester.pumpAndSettle();

    expect(find.text('No tienes resultados de evaluaciones completadas.'), findsOneWidget);
    expect(vocational.startCalls, 0);

    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Mi ficha'), findsOneWidget);
    expect(find.text('Identificación: ID-PROPIA'), findsOneWidget);

    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Panel del estudiante'), findsOneWidget);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresar'), findsOneWidget);
    expect(container.read(goRouterProvider).routerDelegate.currentConfiguration.uri.path, '/login');
  });

  testWidgets('volver usa el historial y, si no existe, el panel', (tester) async {
    final container = await _pumpStudent(tester);
    final router = container.read(goRouterProvider);

    router.push(RouteNames.studentProfile);
    await tester.pumpAndSettle();
    expect(find.text('Mi ficha'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Panel del estudiante'), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.go(RouteNames.studentResults);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(find.text('Panel del estudiante'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('volver desde el test no borra respuestas guardadas', (tester) async {
    final vocational = _Vocational(catalog: const [question], savedAnswer: 4);
    final container = await _pumpStudent(tester, vocational: vocational);
    container.read(goRouterProvider).go(RouteNames.studentTest(15));
    await tester.pumpAndSettle();

    expect(find.text('Me gusta reparar objetos'), findsOneWidget);
    expect(find.text('4'), findsWidgets);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(vocational.saved, 0);
    expect(find.text('Test vocacional', skipOffstage: true), findsWidgets);

    container.read(goRouterProvider).go(RouteNames.studentTest(15));
    await tester.pumpAndSettle();
    expect(find.text('4'), findsWidgets);
    expect(vocational.saved, 0);
  });

  testWidgets('sin sesión las rutas del estudiante vuelven al login', (tester) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(_Auth(_profile('STUDENT'))),
        studentRepositoryProvider.overrideWithValue(_Students()),
        vocationalRepositoryProvider.overrideWithValue(_Vocational()),
        institutionRepositoryProvider.overrideWithValue(_Institutions()),
        userDirectoryRepositoryProvider.overrideWithValue(_Directory()),
        userAccountRepositoryProvider.overrideWithValue(_Users()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AvovApp()),
    );
    await tester.pump();
    container.read(goRouterProvider).go(RouteNames.studentResults);
    await tester.pumpAndSettle();

    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Resultados', skipOffstage: true), findsNothing);
  });

  testWidgets('el orientador conserva su panel sin el menú del estudiante', (tester) async {
    await _pumpRole(
      tester,
      role: 'COUNSELOR',
      profile: _profile('COUNSELOR'),
    );

    expect(find.text('Panel del orientador'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(find.byTooltip('Abrir menú'), findsNothing);
    expect(find.text('Test vocacional'), findsNothing);
  });

  testWidgets('una pantalla estrecha abre el menú sin desbordarse', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpStudent(tester);

    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Perfil'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en escritorio el menú permanece visible', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpStudent(tester);

    expect(find.byTooltip('Abrir menú'), findsNothing);
    expect(find.text('Inicio', skipOffstage: true), findsOneWidget);
    expect(find.text('Resultados', skipOffstage: true), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Mi ficha'), findsOneWidget);
  });
}

ListTile _tile(WidgetTester tester, String label) {
  return tester.widget<ListTile>(find.widgetWithText(ListTile, label));
}

ListTile? _visibleTile(WidgetTester tester, String label) {
  final finder = find.widgetWithText(ListTile, label, skipOffstage: true);
  if (finder.evaluate().isEmpty) {
    return null;
  }
  return tester.widget<ListTile>(finder);
}

Future<ProviderContainer> _pumpStudent(
  WidgetTester tester, {
  _Vocational? vocational,
}) {
  return _pumpRole(
    tester,
    role: 'STUDENT',
    profile: _profile('STUDENT'),
    vocational: vocational,
  );
}

Future<ProviderContainer> _pumpRole(
  WidgetTester tester, {
  required String role,
  required UserProfile profile,
  _Vocational? vocational,
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
      authRepositoryProvider.overrideWithValue(_Auth(profile, storage)),
      studentRepositoryProvider.overrideWithValue(_Students()),
      vocationalRepositoryProvider.overrideWithValue(vocational ?? _Vocational()),
      institutionRepositoryProvider.overrideWithValue(_Institutions()),
      userDirectoryRepositoryProvider.overrideWithValue(_Directory()),
      userAccountRepositoryProvider.overrideWithValue(_Users()),
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

UserProfile _profile(String role) {
  return UserProfile(
    id: 9,
    email: 'lucia@escuela.test',
    firstName: 'Lucía',
    lastName: 'Vega',
    role: role,
    status: 'ACTIVE',
    institutionId: 7,
  );
}

class _Auth with AuthRepositoryChangePasswordStub implements AuthRepository {
  _Auth(this.profile, [this.storage]);

  final UserProfile profile;
  final SecureTokenStorage? storage;

  @override
  Future<UserProfile> currentProfile() async => profile;

  @override
  Future<UserProfile> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    await storage?.clearTokens();
  }

  @override
  Future<void> clearSession() async {
    await storage?.clearTokens();
  }
}

class _Students implements StudentRepository {
  @override
  Future<ManagedStudentPage> list(StudentListQuery query) async {
    return const ManagedStudentPage(items: [], total: 0, page: 1, pages: 0);
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
  Future<ManagedStudent> update(int id, StudentDraft draft) => throw UnimplementedError();

  @override
  Future<ManagedStudent> updateStatus(int id, String status) => throw UnimplementedError();
}

class _Vocational implements VocationalRepository {
  _Vocational({this.catalog = const [], this.savedAnswer});

  final List<VocationalQuestion> catalog;
  final int? savedAnswer;
  int startCalls = 0;
  int saved = 0;
  final Map<int, int> answers = {};

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
    final stored = savedAnswer;
    return VocationalQuestionnaire(
      session: VocationalSession(
        id: sessionId,
        studentId: 4,
        status: 'IN_PROGRESS',
        totalQuestions: catalog.length,
        answeredCount: stored == null ? 0 : 1,
        progressPercent: 0,
      ),
      questions: [
        for (final question in catalog)
          question.copyWithAnswer(answers[question.id] ?? stored),
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
  Future<VocationalResult> finish(int sessionId) => throw UnimplementedError();

  @override
  Future<VocationalResult> result(int sessionId) => throw UnimplementedError();
}

class _Users implements UserAccountRepository {
  @override
  Future<ManagedUserPage> list(UserListQuery query) async {
    return const ManagedUserPage(items: [], total: 0, page: 1, pages: 0);
  }

  @override
  Future<ManagedUser> getById(int id) => throw UnimplementedError();

  @override
  Future<ManagedUser> create(UserDraft draft) => throw UnimplementedError();

  @override
  Future<ManagedUser> update(int id, UserDraft draft) => throw UnimplementedError();

  @override
  Future<ManagedUser> updateStatus(int id, String status) => throw UnimplementedError();
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
