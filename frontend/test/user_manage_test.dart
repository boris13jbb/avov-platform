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
import 'package:avov_frontend/features/users/domain/managed_user.dart';
import 'package:avov_frontend/features/users/domain/user_account_repository.dart';
import 'package:avov_frontend/features/users/presentation/providers/users_provider.dart';
import 'package:avov_frontend/features/users/presentation/screens/user_create_screen.dart';
import 'package:avov_frontend/features/users/presentation/screens/user_edit_screen.dart';
import 'package:avov_frontend/features/users/presentation/screens/user_list_screen.dart';
import 'package:avov_frontend/main.dart';
import 'package:avov_frontend/router/app_router.dart';
import 'package:avov_frontend/router/route_names.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const counselor = ManagedUser(
    id: 8,
    email: 'ana@escuela.test',
    firstName: 'Ana',
    lastName: 'López',
    role: 'COUNSELOR',
    status: 'ACTIVE',
    institutionId: 3,
  );
  const operator = UserProfile(
    id: 1,
    email: 'admin@escuela.test',
    firstName: 'Ada',
    lastName: 'Admin',
    role: 'SUPER_ADMIN',
    status: 'ACTIVE',
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('401, 403, 404, 409, 422, 429 y 503 no exponen el cuerpo interno', () {
    expect(
      FailureMapper.fromDioException(_error(401, 'token secreto')).message,
      FailureMapper.sessionExpiredMessage,
    );
    expect(
      FailureMapper.fromDioException(_error(403, 'traza sql')).message,
      FailureMapper.forbiddenMessage,
    );
    expect(
      FailureMapper.fromDioException(_error(404, 'Usuario no encontrado')).message,
      'Usuario no encontrado',
    );
    expect(
      FailureMapper.fromDioException(_error(409, 'conflicto interno')).message,
      'conflicto interno',
    );
    expect(
      FailureMapper.fromDioException(_error(422, 'El correo electrónico ya está registrado'))
          .message,
      'El correo electrónico ya está registrado',
    );
    expect(
      FailureMapper.fromDioException(_error(429, 'rate')).message,
      FailureMapper.tooManyRequestsMessage,
    );
    expect(
      FailureMapper.fromDioException(_error(503, 'stack')).message,
      FailureMapper.unavailableMessage,
    );
  });

  testWidgets('el listado muestra nombre, correo, rol, institución y estado',
      (tester) async {
    await tester.pumpWidget(_scope(users: _Users(items: const [counselor])));
    await tester.pump();
    await tester.pump();

    expect(find.text('Ana López'), findsOneWidget);
    expect(find.textContaining('ana@escuela.test'), findsOneWidget);
    expect(find.textContaining('Orientador'), findsWidgets);
    expect(find.textContaining('Colegio Norte'), findsWidgets);
    expect(find.text('Activa'), findsWidgets);
  });

  testWidgets('el listado vacío ofrece crear un usuario', (tester) async {
    await tester.pumpWidget(_scope(users: _Users()));
    await tester.pump();
    await tester.pump();

    expect(find.text('Todavía no hay usuarios.'), findsOneWidget);
    expect(find.text('Crear usuario'), findsOneWidget);
  });

  testWidgets('un error de carga se puede reintentar', (tester) async {
    final users = _Users(items: const [counselor], failFirstList: true);
    await tester.pumpWidget(_scope(users: users));
    await tester.pump();
    await tester.pump();

    expect(find.text(FailureMapper.connectionMessage), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(users.listCalls, 2);
    expect(find.text('Ana López'), findsOneWidget);
  });

  testWidgets('la búsqueda y los filtros se envían a la consulta', (tester) async {
    final users = _Users(items: const [counselor], pages: 2);
    await tester.pumpWidget(_scope(users: users));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byKey(const Key('user-search')), 'ana');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump();
    expect(users.lastQuery?.search, 'ana');

    await tester.tap(find.byKey(const Key('user-role-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orientador').last);
    await tester.pump();
    await tester.pump();
    expect(users.lastQuery?.role, 'COUNSELOR');

    await tester.tap(find.byKey(const Key('user-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activa').last);
    await tester.pump();
    await tester.pump();
    expect(users.lastQuery?.status, 'ACTIVE');

    await tester.tap(find.byKey(const Key('user-institution-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Colegio Norte').last);
    await tester.pump();
    await tester.pump();
    expect(users.lastQuery?.institutionId, 3);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    await tester.pump();
    expect(users.lastQuery?.page, 2);
    expect(users.listCalls, 6);
  });

  testWidgets('una búsqueda sin resultados conserva los filtros', (tester) async {
    final users = _Users(items: const [counselor], emptySearch: 'nadie');
    await tester.pumpWidget(_scope(users: users));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byKey(const Key('user-search')), 'nadie');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Todavía no hay usuarios que coincidan con la búsqueda.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('user-search')), findsOneWidget);
  });

  testWidgets('el formulario de creación exige los campos obligatorios',
      (tester) async {
    final users = _Users();
    await tester.pumpWidget(
      _scope(users: users, home: const UserCreateScreen()),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.text('Guardar usuario'));
    await tester.tap(find.text('Guardar usuario'));
    await tester.pump();

    expect(find.text('El campo nombre es obligatorio'), findsOneWidget);
    expect(find.text('El campo apellido es obligatorio'), findsOneWidget);
    expect(find.text('El correo electrónico es obligatorio'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
    expect(
      find.text('La institución es obligatoria para este rol'),
      findsOneWidget,
    );
    expect(users.createCalls, 0);
  });

  testWidgets('una creación válida vuelve al listado sin mostrar la contraseña',
      (tester) async {
    final users = _Users();
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_scope(users: users, router: router));
    await tester.pump();
    await tester.pump();

    await _fillCreateForm(tester);
    await tester.ensureVisible(find.text('Guardar usuario'));
    await tester.tap(find.text('Guardar usuario'));
    await tester.pumpAndSettle();

    expect(find.text('Luis Mora'), findsOneWidget);
    expect(find.text('Clave.Segura1'), findsNothing);
    expect(find.byKey(const Key('user-password')), findsNothing);
    expect(users.createdDraft?.password, 'Clave.Segura1');
    expect(users.createdDraft?.institutionId, 3);
    expect(users.createdDraft?.role, 'STUDENT');
  });

  testWidgets('un 422 de correo duplicado no se presenta como alta exitosa',
      (tester) async {
    final users = _Users(
      createError: ValidationException(
        'El correo electrónico ya está registrado',
        fieldErrors: const ['email: El correo electrónico ya está registrado'],
      ),
    );
    await tester.pumpWidget(
      _scope(users: users, home: const UserCreateScreen()),
    );
    await tester.pump();
    await tester.pump();

    await _fillCreateForm(tester);
    await tester.ensureVisible(find.text('Guardar usuario'));
    await tester.tap(find.text('Guardar usuario'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('El correo electrónico ya está registrado'),
      findsWidgets,
    );
    expect(find.text('Usuarios'), findsNothing);
    expect(users.items, isEmpty);
  });

  testWidgets('la edición carga los datos y guarda el cambio', (tester) async {
    final users = _Users(items: const [counselor]);
    final router = _router(initial: RouteNames.adminUsers);
    addTearDown(router.dispose);
    await tester.pumpWidget(_scope(users: users, router: router));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Editar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Editar usuario'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byKey(const Key('user-last-name'))).controller?.text,
      'López',
    );
    expect(find.byKey(const Key('user-password')), findsNothing);

    await tester.enterText(find.byKey(const Key('user-last-name')), 'García');
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Ana García'), findsOneWidget);
    expect(users.updatedRole, 'COUNSELOR');
    expect(users.updatedPassword, isNull);
  });

  testWidgets('un usuario inexistente muestra el error 404', (tester) async {
    await tester.pumpWidget(
      _scope(
        users: _Users(missing: true),
        home: const UserEditScreen(userId: 99),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Usuario no encontrado'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsNothing);
  });

  testWidgets('desactivar pide confirmación y no actúa si se cancela',
      (tester) async {
    final users = _Users(items: const [counselor]);
    await tester.pumpWidget(_scope(users: users));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no podrá iniciar sesión'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(users.statusCalls, 0);

    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Desactivar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(users.statusCalls, 1);
    expect(users.lastStatus, 'INACTIVE');
    expect(find.text('Inactiva'), findsOneWidget);
  });

  testWidgets('el botón de alta ignora un segundo envío', (tester) async {
    final users = _SlowUsers();
    await tester.pumpWidget(
      _scope(users: users, home: const UserCreateScreen()),
    );
    await tester.pump();
    await tester.pump();

    await _fillCreateForm(tester);
    await tester.ensureVisible(find.text('Guardar usuario'));
    await tester.tap(find.text('Guardar usuario'));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    expect(users.createCalls, 1);

    users.finish();
    await tester.pumpAndSettle();
  });

  testWidgets('el operador no puede cambiar su propio rol ni su estado',
      (tester) async {
    const self = ManagedUser(
      id: 1,
      email: 'admin@escuela.test',
      firstName: 'Ada',
      lastName: 'Admin',
      role: 'SUPER_ADMIN',
      status: 'ACTIVE',
    );
    final users = _Users(items: const [self]);
    final router = _router(initial: RouteNames.adminUsers);
    addTearDown(router.dispose);
    await tester.pumpWidget(_scope(users: users, router: router));
    await tester.pump();
    await tester.pump();

    expect(find.text('Desactivar'), findsNothing);
    expect(find.text('Bloquear'), findsNothing);
    expect(users.statusCalls, 0);

    await tester.tap(find.text('Editar'));
    await tester.pump();
    await tester.pump();

    final role = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('user-role')),
    );
    expect(role.onChanged, isNull);
    expect(
      find.text('No puedes cambiar tu propio rol desde esta pantalla.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('user-first-name')), 'Ada María');
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(users.updatedRole, 'SUPER_ADMIN');
    expect(find.text('Ada María Admin'), findsOneWidget);
  });

  testWidgets('un estudiante no entra a la gestión de usuarios', (tester) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      SecureTokenStorage.accessTokenKey: 'access-de-prueba',
      SecureTokenStorage.refreshTokenKey: 'refresh-de-prueba',
      SecureTokenStorage.userRoleKey: 'STUDENT',
    });
    final storage = SecureTokenStorage(storage: const FlutterSecureStorage());
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(_Auth(operator)),
        institutionRepositoryProvider.overrideWithValue(_Institutions()),
        userDirectoryRepositoryProvider.overrideWithValue(_Directory()),
        userAccountRepositoryProvider.overrideWithValue(_Users()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AvovApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    container.read(goRouterProvider).go('/admin/users');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('No tienes permisos para acceder a esta sección.'),
      findsOneWidget,
    );
    expect(find.text('Crear usuario'), findsNothing);
  });

  testWidgets('un 403 de listado se muestra sin detalle interno', (tester) async {
    await tester.pumpWidget(
      _scope(
        users: _Users(
          listError: AppException(FailureMapper.forbiddenMessage, statusCode: 403),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(FailureMapper.forbiddenMessage), findsOneWidget);
    expect(find.textContaining('sql'), findsNothing);
  });
}

Future<void> _fillCreateForm(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('user-first-name')), 'Luis');
  await tester.enterText(find.byKey(const Key('user-last-name')), 'Mora');
  await tester.enterText(find.byKey(const Key('user-email')), 'luis@escuela.test');
  await tester.enterText(find.byKey(const Key('user-password')), 'Clave.Segura1');
  await tester.ensureVisible(find.byKey(const Key('user-institution')));
  await tester.tap(find.byKey(const Key('user-institution')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Colegio Norte').last);
  await tester.pumpAndSettle();
}

Widget _scope({
  required UserAccountRepository users,
  GoRouter? router,
  Widget? home,
  UserProfile profile = const UserProfile(
    id: 1,
    email: 'admin@escuela.test',
    firstName: 'Ada',
    lastName: 'Admin',
    role: 'SUPER_ADMIN',
    status: 'ACTIVE',
  ),
}) {
  final child = router == null
      ? MaterialApp(home: home ?? const UserListScreen())
      : MaterialApp.router(routerConfig: router);
  return ProviderScope(
    overrides: [
      userAccountRepositoryProvider.overrideWithValue(users),
      institutionRepositoryProvider.overrideWithValue(_Institutions()),
      authRepositoryProvider.overrideWithValue(_Auth(profile)),
    ],
    child: child,
  );
}

GoRouter _router({String initial = RouteNames.adminUserNew}) {
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: RouteNames.adminUsers,
        builder: (context, state) => const UserListScreen(),
      ),
      GoRoute(
        path: RouteNames.adminUserNew,
        builder: (context, state) => const UserCreateScreen(),
      ),
      GoRoute(
        path: '/admin/users/:userId',
        builder: (context, state) => UserEditScreen(
          userId: int.parse(state.pathParameters['userId']!),
        ),
      ),
    ],
  );
}

DioException _error(int status, String message) {
  final options = RequestOptions(path: '/users');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: <String, dynamic>{
        'success': false,
        'message': message,
        'data': null,
        'errors': <Map<String, String>>[],
      },
    ),
  );
}

class _Users implements UserAccountRepository {
  _Users({
    List<ManagedUser> items = const [],
    this.createError,
    this.listError,
    this.missing = false,
    this.failFirstList = false,
    this.emptySearch,
    this.pages = 1,
  }) : items = [...items];

  final List<ManagedUser> items;
  final AppException? createError;
  final AppException? listError;
  final bool missing;
  final bool failFirstList;
  final String? emptySearch;
  final int pages;
  UserListQuery? lastQuery;
  UserDraft? createdDraft;
  String? updatedRole;
  String? updatedPassword;
  String? lastStatus;
  int listCalls = 0;
  int createCalls = 0;
  int statusCalls = 0;

  @override
  Future<ManagedUserPage> list(UserListQuery query) async {
    listCalls += 1;
    lastQuery = query;
    if (listError != null) {
      throw listError!;
    }
    if (failFirstList && listCalls == 1) {
      throw NetworkException(FailureMapper.connectionMessage);
    }
    if (emptySearch != null && query.search == emptySearch) {
      return const ManagedUserPage(items: [], total: 0, page: 1, pages: 0);
    }
    return ManagedUserPage(
      items: items,
      total: items.length,
      page: query.page,
      pages: items.isEmpty ? 0 : pages,
    );
  }

  @override
  Future<ManagedUser> getById(int id) async {
    if (missing) {
      throw AppException('Usuario no encontrado', statusCode: 404);
    }
    return items.firstWhere((item) => item.id == id);
  }

  @override
  Future<ManagedUser> create(UserDraft draft) async {
    createCalls += 1;
    if (createError != null) {
      throw createError!;
    }
    createdDraft = draft;
    final created = ManagedUser(
      id: 21,
      email: draft.email,
      firstName: draft.firstName,
      lastName: draft.lastName,
      role: draft.role,
      status: draft.status,
      institutionId: draft.role == 'SUPER_ADMIN' ? null : draft.institutionId,
    );
    items.add(created);
    return created;
  }

  @override
  Future<ManagedUser> update(int id, UserDraft draft) async {
    updatedRole = draft.role;
    updatedPassword = draft.password;
    final next = ManagedUser(
      id: id,
      email: draft.email,
      firstName: draft.firstName,
      lastName: draft.lastName,
      role: draft.role,
      status: items.firstWhere((item) => item.id == id).status,
      institutionId: draft.role == 'SUPER_ADMIN' ? null : draft.institutionId,
    );
    items
      ..clear()
      ..add(next);
    return next;
  }

  @override
  Future<ManagedUser> updateStatus(int id, String status) async {
    statusCalls += 1;
    lastStatus = status;
    final current = items.firstWhere((item) => item.id == id);
    final next = ManagedUser(
      id: current.id,
      email: current.email,
      firstName: current.firstName,
      lastName: current.lastName,
      role: current.role,
      status: status,
      institutionId: current.institutionId,
    );
    items
      ..clear()
      ..add(next);
    return next;
  }
}

class _SlowUsers extends _Users {
  final Completer<ManagedUser> _pending = Completer<ManagedUser>();

  void finish() {
    if (!_pending.isCompleted) {
      _pending.complete(
        const ManagedUser(
          id: 21,
          email: 'luis@escuela.test',
          firstName: 'Luis',
          lastName: 'Mora',
          role: 'STUDENT',
          status: 'ACTIVE',
          institutionId: 3,
        ),
      );
    }
  }

  @override
  Future<ManagedUser> create(UserDraft draft) {
    createCalls += 1;
    createdDraft = draft;
    return _pending.future;
  }
}

class _Auth with AuthRepositoryChangePasswordStub implements AuthRepository {
  _Auth(this.profile);

  final UserProfile profile;

  @override
  Future<UserProfile> currentProfile() async => profile;

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) {
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

class _Institutions implements InstitutionRepository {
  @override
  Future<InstitutionPage> list({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    return const InstitutionPage(
      items: [school],
      total: 1,
      page: 1,
      pages: 1,
    );
  }

  @override
  Future<Institution> getById(int id) async => school;

  @override
  Future<Institution> create(InstitutionDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<Institution> update(int id, InstitutionDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<Institution> deactivate(int id) {
    throw UnimplementedError();
  }

  @override
  Future<Institution> activate(int id) {
    throw UnimplementedError();
  }
}

class _Directory implements UserDirectoryRepository {
  @override
  Future<int> count() async => 0;
}

const school = Institution(
  id: 3,
  name: 'Colegio Norte',
  code: 'CN-01',
  province: 'Pichincha',
  city: 'Quito',
  status: 'ACTIVE',
);
