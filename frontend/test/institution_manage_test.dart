import 'dart:async';

import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/core/errors/failure_mapper.dart';
import 'package:avov_frontend/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:avov_frontend/features/institutions/domain/institution.dart';
import 'package:avov_frontend/features/institutions/domain/institution_repository.dart';
import 'package:avov_frontend/features/institutions/presentation/screens/institution_edit_screen.dart';
import 'package:avov_frontend/features/institutions/presentation/screens/institution_list_screen.dart';
import 'package:avov_frontend/router/route_names.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  const sample = Institution(
    id: 3,
    name: 'Colegio Norte',
    code: 'CN-01',
    province: 'Pichincha',
    city: 'Quito',
    status: 'ACTIVE',
    email: 'norte@escuela.test',
  );

  test('401, 403 y 404 usan mensajes controlados', () {
    expect(
      FailureMapper.fromDioException(_error(401, 'token secreto')).message,
      FailureMapper.sessionExpiredMessage,
    );
    expect(
      FailureMapper.fromDioException(_error(403, 'detalle interno')).message,
      FailureMapper.forbiddenMessage,
    );
    expect(
      FailureMapper.fromDioException(_error(404, 'Institución no encontrada'))
          .message,
      'Institución no encontrada',
    );
  });

  testWidgets('el listado muestra nombre, ubicación y estado', (tester) async {
    await tester.pumpWidget(_app(_MemoryRepo(items: const [sample])));
    await tester.pump();
    await tester.pump();

    expect(find.text('Colegio Norte'), findsOneWidget);
    expect(find.textContaining('Quito, Pichincha'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
  });

  testWidgets('el listado vacío ofrece crear la primera institución',
      (tester) async {
    await tester.pumpWidget(_app(_MemoryRepo()));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Todavía no hay instituciones'), findsOneWidget);
  });

  testWidgets('un error de carga se puede reintentar', (tester) async {
    final repository = _FlakyRepo(sample);
    await tester.pumpWidget(_app(repository));
    await tester.pump();
    await tester.pump();

    expect(find.text(FailureMapper.connectionMessage), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(repository.calls, 2);
    expect(find.text('Colegio Norte'), findsOneWidget);
  });

  testWidgets('la edición abre los datos actuales y guarda el cambio',
      (tester) async {
    final repository = _MemoryRepo(items: const [sample]);
    final router = _router(repository);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(repository, router: router));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Editar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Editar institución'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byKey(const Key('institution-name'))).controller?.text,
      'Colegio Norte',
    );

    await tester.enterText(find.byKey(const Key('institution-name')), 'Colegio Sur');
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Colegio Sur'), findsOneWidget);
    expect(repository.updated, isTrue);
  });

  testWidgets('un 422 del backend no se presenta como edición exitosa',
      (tester) async {
    final repository = _MemoryRepo(
      items: const [sample],
      updateError: ValidationException(
        'El código de institución ya está registrado',
        fieldErrors: const ['code: El código de institución ya está registrado'],
      ),
    );
    await tester.pumpWidget(
      _app(
        repository,
        home: const InstitutionEditScreen(institutionId: 3),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('El código de institución ya está registrado'),
      findsWidgets,
    );
    expect(find.text('Instituciones'), findsNothing);
    expect(repository.items.single.name, 'Colegio Norte');
  });

  testWidgets('un fallo de conexión conserva el formulario', (tester) async {
    final repository = _MemoryRepo(
      items: const [sample],
      updateError: NetworkException(FailureMapper.connectionMessage),
    );
    await tester.pumpWidget(
      _app(
        repository,
        home: const InstitutionEditScreen(institutionId: 3),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();
    await tester.pump();

    expect(find.text(FailureMapper.connectionMessage), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byKey(const Key('institution-name'))).controller?.text,
      'Colegio Norte',
    );
  });

  testWidgets('el botón de guardado ignora un segundo envío', (tester) async {
    final repository = _SlowRepo(sample);
    await tester.pumpWidget(
      _app(
        repository,
        home: const InstitutionEditScreen(institutionId: 3),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    expect(repository.calls, 1);

    repository.finish();
    await tester.pumpAndSettle();
  });

  testWidgets('desactivar pide confirmación y no actúa si se cancela',
      (tester) async {
    final repository = _MemoryRepo(items: const [sample]);
    await tester.pumpWidget(_app(repository));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('El registro se conserva'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.deactivated, isFalse);

    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Desactivar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.deactivated, isTrue);
    expect(find.text('Inactiva'), findsOneWidget);
  });

  testWidgets('una institución inexistente muestra el error 404', (tester) async {
    await tester.pumpWidget(
      _app(
        _MemoryRepo(missing: true),
        home: const InstitutionEditScreen(institutionId: 99),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Institución no encontrada'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsNothing);
  });
}

Widget _app(InstitutionRepository repository, {GoRouter? router, Widget? home}) {
  final child = router == null
      ? MaterialApp(home: home ?? const InstitutionListScreen())
      : MaterialApp.router(routerConfig: router);
  return ProviderScope(
    overrides: [
      institutionRepositoryProvider.overrideWithValue(repository),
    ],
    child: child,
  );
}

GoRouter _router(InstitutionRepository repository) {
  return GoRouter(
    initialLocation: RouteNames.adminInstitutions,
    routes: [
      GoRoute(
        path: RouteNames.adminInstitutions,
        builder: (context, state) => const InstitutionListScreen(),
      ),
      GoRoute(
        path: '/admin/institutions/:institutionId',
        builder: (context, state) => InstitutionEditScreen(
          institutionId: int.parse(state.pathParameters['institutionId']!),
        ),
      ),
    ],
  );
}

DioException _error(int status, String message) {
  final options = RequestOptions(path: '/institutions/3');
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

class _MemoryRepo implements InstitutionRepository {
  _MemoryRepo({
    List<Institution> items = const [],
    this.updateError,
    this.missing = false,
  }) : items = [...items];

  final List<Institution> items;
  final AppException? updateError;
  final bool missing;
  bool updated = false;
  bool deactivated = false;

  @override
  Future<InstitutionPage> list({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    return InstitutionPage(
      items: items,
      total: items.length,
      page: 1,
      pages: items.isEmpty ? 0 : 1,
    );
  }

  @override
  Future<Institution> getById(int id) async {
    if (missing) {
      throw AppException('Institución no encontrada', statusCode: 404);
    }
    return items.firstWhere((item) => item.id == id);
  }

  @override
  Future<Institution> create(InstitutionDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<Institution> update(int id, InstitutionDraft draft) async {
    if (updateError != null) {
      throw updateError!;
    }
    updated = true;
    final next = Institution(
      id: id,
      name: draft.name,
      code: draft.code,
      province: draft.province,
      city: draft.city,
      status: draft.status,
    );
    items
      ..clear()
      ..add(next);
    return next;
  }

  @override
  Future<Institution> deactivate(int id) async {
    deactivated = true;
    final current = items.firstWhere((item) => item.id == id);
    final next = Institution(
      id: current.id,
      name: current.name,
      code: current.code,
      province: current.province,
      city: current.city,
      status: 'INACTIVE',
    );
    items
      ..clear()
      ..add(next);
    return next;
  }

  @override
  Future<Institution> activate(int id) {
    throw UnimplementedError();
  }
}

class _FlakyRepo extends _MemoryRepo {
  _FlakyRepo(Institution item) : super(items: [item]);

  int calls = 0;

  @override
  Future<InstitutionPage> list({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    calls += 1;
    if (calls == 1) {
      throw NetworkException(FailureMapper.connectionMessage);
    }
    return super.list(page: page, pageSize: pageSize, search: search);
  }
}

class _SlowRepo implements InstitutionRepository {
  _SlowRepo(this.item);

  final Institution item;
  final Completer<Institution> _pending = Completer<Institution>();
  int calls = 0;

  void finish() {
    if (!_pending.isCompleted) {
      _pending.complete(item);
    }
  }

  @override
  Future<Institution> update(int id, InstitutionDraft draft) {
    calls += 1;
    return _pending.future;
  }

  @override
  Future<Institution> getById(int id) async => item;

  @override
  Future<InstitutionPage> list({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    return InstitutionPage(items: [item], total: 1, page: 1, pages: 1);
  }

  @override
  Future<Institution> create(InstitutionDraft draft) {
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
