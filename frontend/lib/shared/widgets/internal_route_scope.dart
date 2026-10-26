import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_navigation.dart';

/// Intercepta el Atrás del sistema en pantallas internas.
///
/// Si hay historial, hace `pop`. Si la pantalla llegó con `go` o deeplink
/// (sin pila), navega al panel del área en lugar de cerrar la aplicación.
class InternalRouteScope extends StatelessWidget {
  const InternalRouteScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return child;
    }
    final path = GoRouterState.of(context).uri.path;
    if (AppNavigation.isRootLocation(path)) {
      return child;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        AppNavigation.back(context);
      },
      child: child,
    );
  }
}
