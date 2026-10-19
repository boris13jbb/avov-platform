import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../providers/auth_session_provider.dart';

class SessionMenuButton extends ConsumerWidget {
  const SessionMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Menú de usuario',
      onSelected: (value) async {
        if (value != 'logout') {
          return;
        }
        await ref.read(authSessionProvider.notifier).logout();
        if (context.mounted) {
          context.go(RouteNames.login);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'logout',
          child: Text('Cerrar sesión'),
        ),
      ],
      icon: const Icon(Icons.account_circle_outlined),
    );
  }
}
