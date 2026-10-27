import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../providers/auth_session_provider.dart';

/// Acciones de sesión en la barra: cambio de contraseña y cierre visible.
///
/// El texto «Cerrar sesión» permanece en la barra para no exigir un menú.
/// El acceso a cambio de contraseña usa un icono con tooltip accesible.
class SessionMenuButton extends ConsumerWidget {
  const SessionMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(
      authSessionProvider.select((state) => state.isSubmitting),
    );
    final foreground =
        Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Cambiar contraseña',
          onPressed: busy
              ? null
              : () => context.go(RouteNames.changePassword),
          icon: Icon(Icons.lock_outline, color: foreground),
        ),
        TextButton.icon(
          onPressed: busy ? null : () => _logout(context, ref),
          style: TextButton.styleFrom(
            foregroundColor: foreground,
            disabledForegroundColor: foreground.withValues(alpha: 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          icon: busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              : const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
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
