import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';

/// Navegación segura sobre go_router sin acumular rutas duplicadas.
///
/// - [open]: entra a una pantalla hija con `push` (conserva historial).
/// - [back]: `pop` si hay pila; si no, vuelve al panel del área.
/// - [completeTo]: tras guardar un formulario, deja la pila en el destino
///   (evita regresar al formulario con Atrás).
class AppNavigation {
  AppNavigation._();

  /// Paneles raíz por rol: no muestran botón Volver.
  static const rootLocations = <String>{
    RouteNames.adminDashboard,
    RouteNames.institutionDashboard,
    RouteNames.counselorDashboard,
    RouteNames.studentDashboard,
  };

  static bool isRootLocation(String path) => rootLocations.contains(path);

  /// Destino de retorno cuando no hay historial (p. ej. tras `go` o deeplink).
  static String fallbackFor(String path) {
    if (path == RouteNames.adminPrefix ||
        path.startsWith('${RouteNames.adminPrefix}/')) {
      return RouteNames.adminDashboard;
    }
    if (path == RouteNames.institutionPrefix ||
        path.startsWith('${RouteNames.institutionPrefix}/')) {
      return RouteNames.institutionDashboard;
    }
    if (path == RouteNames.counselorPrefix ||
        path.startsWith('${RouteNames.counselorPrefix}/')) {
      return RouteNames.counselorDashboard;
    }
    if (path.startsWith('${RouteNames.studentTestHome}/') &&
        path.endsWith('/result')) {
      return RouteNames.studentResults;
    }
    if (path.startsWith('${RouteNames.studentTestHome}/')) {
      return RouteNames.studentTestHome;
    }
    if (path == RouteNames.studentTestHome ||
        path == RouteNames.studentResults ||
        path == RouteNames.studentAssistant ||
        path == RouteNames.studentProfile) {
      return RouteNames.studentDashboard;
    }
    if (path == RouteNames.studentPrefix ||
        path.startsWith('${RouteNames.studentPrefix}/')) {
      return RouteNames.studentDashboard;
    }
    return RouteNames.home;
  }

  /// Abre una ruta hija. No apila si ya estamos en esa ubicación.
  static void open(BuildContext context, String location) {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }
    final current = GoRouterState.of(context).uri.path;
    if (current == location) {
      return;
    }
    router.push(location);
  }

  /// Regresa por el historial o, si no hay, al panel del área.
  static void back(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      final navigator = Navigator.maybeOf(context);
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
      }
      return;
    }
    if (router.canPop()) {
      router.pop();
      return;
    }
    final path = GoRouterState.of(context).uri.path;
    if (isRootLocation(path)) {
      return;
    }
    final fallback = fallbackFor(path);
    if (path != fallback) {
      router.go(fallback);
    }
  }

  /// Tras un alta/edición exitosa: deja al usuario en [location] sin el formulario
  /// debajo en la pila (así Atrás no reabre el formulario guardado).
  static void completeTo(BuildContext context, String location) {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }
    router.go(location);
  }
}
