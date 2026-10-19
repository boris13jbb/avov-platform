import 'package:avov_frontend/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:avov_frontend/features/institutions/domain/institution.dart';
import 'package:avov_frontend/features/institutions/domain/institution_repository.dart';
import 'package:avov_frontend/features/institutions/presentation/screens/institution_create_screen.dart';
import 'package:avov_frontend/features/institutions/presentation/screens/institution_list_screen.dart';
import 'package:avov_frontend/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('el formulario exige los campos del esquema', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          institutionRepositoryProvider.overrideWithValue(_Repo()),
        ],
        child: const MaterialApp(home: InstitutionCreateScreen()),
      ),
    );

    await tester.ensureVisible(find.text('Guardar institución'));
    await tester.tap(find.text('Guardar institución'));
    await tester.pump();

    expect(find.text('El campo nombre es obligatorio'), findsOneWidget);
    expect(find.text('El campo código es obligatorio'), findsOneWidget);
    expect(find.text('El campo provincia es obligatorio'), findsOneWidget);
    expect(find.text('El campo ciudad es obligatorio'), findsOneWidget);
  });

  testWidgets('una creación válida vuelve a la lista', (tester) async {
    final repository = _Repo();
    final router = GoRouter(
      initialLocation: RouteNames.adminInstitutionNew,
      routes: [
        GoRoute(
          path: RouteNames.adminInstitutions,
          builder: (context, state) => const InstitutionListScreen(),
        ),
        GoRoute(
          path: RouteNames.adminInstitutionNew,
          builder: (context, state) => const InstitutionCreateScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          institutionRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(find.byKey(const Key('institution-name')), 'Colegio Norte');
    await tester.enterText(find.byKey(const Key('institution-code')), 'CN-01');
    await tester.enterText(find.byKey(const Key('institution-province')), 'Pichincha');
    await tester.enterText(find.byKey(const Key('institution-city')), 'Quito');
    await tester.ensureVisible(find.text('Guardar institución'));
    await tester.tap(find.text('Guardar institución'));
    await tester.pumpAndSettle();

    expect(find.text('Colegio Norte'), findsOneWidget);
    expect(find.byKey(const Key('institution-name')), findsNothing);
    expect(find.text('Activa'), findsOneWidget);
    expect(repository.created, isTrue);
  });
}

class _Repo implements InstitutionRepository {
  bool created = false;

  @override
  Future<Institution> create(InstitutionDraft draft) async {
    created = true;
    return Institution(
      id: 9,
      name: draft.name,
      code: draft.code,
      province: draft.province,
      city: draft.city,
      status: draft.status,
    );
  }

  @override
  Future<Institution> getById(int id) {
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

  @override
  Future<InstitutionPage> list({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    if (!created) {
      return const InstitutionPage(items: [], total: 0, page: 1, pages: 0);
    }
    return const InstitutionPage(
      items: [
        Institution(
          id: 9,
          name: 'Colegio Norte',
          code: 'CN-01',
          province: 'Pichincha',
          city: 'Quito',
          status: 'ACTIVE',
        ),
      ],
      total: 1,
      page: 1,
      pages: 1,
    );
  }
}
