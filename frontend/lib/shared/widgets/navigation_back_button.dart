import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_navigation.dart';

/// Botón Volver visible en pantallas internas (no en paneles raíz).
class NavigationBackButton extends StatelessWidget {
  const NavigationBackButton({super.key});

  /// Leading de [AppBar]: `null` en raíces o cuando no hay a dónde volver.
  static Widget? maybeOf(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      final path = GoRouterState.of(context).uri.path;
      if (AppNavigation.isRootLocation(path)) {
        return null;
      }
      return const NavigationBackButton();
    }
    if (Navigator.maybeOf(context)?.canPop() ?? false) {
      return const NavigationBackButton();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Volver',
      icon: const Icon(Icons.arrow_back),
      onPressed: () => AppNavigation.back(context),
    );
  }
}
