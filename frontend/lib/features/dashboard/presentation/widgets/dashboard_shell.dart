import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

class DashboardShell extends ConsumerWidget {
  const DashboardShell({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.leading,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: Text(title),
        actions: [
          userAsync.when(
            data: (user) => user == null
                ? const SizedBox.shrink()
                : PopupMenuButton<String>(
                    tooltip: 'Cuenta',
                    onSelected: (value) {
                      if (value == 'profile') {
                        context.push(RouteNames.profile);
                      } else if (value == 'password') {
                        context.push(RouteNames.changePassword);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'profile',
                        child: ListTile(
                          leading: Icon(Icons.person_outline),
                          title: Text('Mi perfil'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'password',
                        child: ListTile(
                          leading: Icon(Icons.lock_outline),
                          title: Text('Cambiar contraseña'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              ref.invalidate(currentUserProvider);
              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: body),
    );
  }
}
