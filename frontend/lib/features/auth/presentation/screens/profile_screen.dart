import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_role.dart';
import '../../../../router/route_names.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/current_user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return DashboardShell(
      title: 'Mi perfil',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No hay sesión activa'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        child: Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : '?',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(user.email),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _InfoTile(label: 'Rol', value: _roleLabel(user.role)),
              if (user.institutionId != null)
                _InfoTile(
                  label: 'Institución ID',
                  value: '${user.institutionId}',
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push(RouteNames.changePassword),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Cambiar contraseña'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(currentUserProvider),
            child: const Text('Reintentar'),
          ),
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super administrador';
      case UserRole.institutionAdmin:
        return 'Administrador institucional';
      case UserRole.counselor:
        return 'Orientador';
      case UserRole.student:
        return 'Estudiante';
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
