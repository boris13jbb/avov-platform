import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../providers/auth_session_provider.dart';

/// Menú de sesión con cambio de contraseña y cierre de sesión.
class SessionMenuButton extends ConsumerWidget {
  const SessionMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(
      authSessionProvider.select((state) => state.isSubmitting),
    );
    final foreground =
        Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;
    if (busy) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: foreground,
          ),
        ),
      );
    }
    return PopupMenuButton<_SessionAction>(
      tooltip: 'Opciones de sesión',
      icon: Icon(Icons.account_circle_outlined, color: foreground),
      onSelected: (action) async {
        switch (action) {
          case _SessionAction.changePassword:
            context.go(RouteNames.changePassword);
          case _SessionAction.logout:
            await _logout(context, ref);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _SessionAction.changePassword,
          child: Text('Cambiar contraseña'),
        ),
        PopupMenuItem(
          value: _SessionAction.logout,
          child: Text('Cerrar sesión'),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authSessionProvider.notifier).logout();
    if (context.mounted) {
      context.go(RouteNames.login);
    }
  }
}

enum _SessionAction { changePassword, logout }
