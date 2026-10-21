import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regresión: push a `/student/test/:sessionId` debe actualizar la URI
/// cuando `optionURLReflectsImperativeAPIs` está activo (como en main.dart).
void main() {
  tearDown(() {
    GoRouter.optionURLReflectsImperativeAPIs = false;
  });

  testWidgets(
    'push de evaluación refleja /student/test/:sessionId en la URI',
    (tester) async {
      GoRouter.optionURLReflectsImperativeAPIs = true;

      final router = GoRouter(
        initialLocation: '/student/test',
        routes: [
          GoRoute(
            path: '/student/test',
            builder: (context, state) => const Scaffold(
              body: Text('lista'),
            ),
          ),
          GoRoute(
            path: '/student/test/:sessionId',
            builder: (context, state) {
              final id = state.pathParameters['sessionId'];
              return Scaffold(body: Text('sesion-$id'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('lista'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/student/test');

      router.push('/student/test/138');
      await tester.pumpAndSettle();

      expect(find.text('sesion-138'), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/student/test/138',
      );
    },
  );

  testWidgets(
    'sin la opción, push imperativo no cambia la URI (comportamiento go_router)',
    (tester) async {
      GoRouter.optionURLReflectsImperativeAPIs = false;

      final router = GoRouter(
        initialLocation: '/student/test',
        routes: [
          GoRoute(
            path: '/student/test',
            builder: (context, state) => const Scaffold(
              body: Text('lista'),
            ),
          ),
          GoRoute(
            path: '/student/test/:sessionId',
            builder: (context, state) {
              final id = state.pathParameters['sessionId'];
              return Scaffold(body: Text('sesion-$id'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.push('/student/test/138');
      await tester.pumpAndSettle();

      expect(find.text('sesion-138'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/student/test');
    },
  );
}
