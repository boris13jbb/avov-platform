import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_navigation.dart';
import 'confirm_dialog.dart';

/// En paneles raíz: si no hay pantalla anterior, confirma antes de salir.
class RootExitScope extends StatelessWidget {
  const RootExitScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return child;
    }
    final path = GoRouterState.of(context).uri.path;
    if (!AppNavigation.isRootLocation(path)) {
      return child;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        if (router.canPop()) {
          router.pop();
          return;
        }
        final leave = await ConfirmDialog.show(
          context,
          title: 'Salir de AVOV',
          message: '¿Deseas cerrar la aplicación?',
          confirmLabel: 'Salir',
          cancelLabel: 'Cancelar',
        );
        if (leave && context.mounted) {
          await SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}
