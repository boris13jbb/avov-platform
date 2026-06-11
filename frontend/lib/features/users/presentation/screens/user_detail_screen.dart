import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/managed_user.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../../../institutions/presentation/providers/institution_provider.dart';
import '../../domain/user_management_config.dart';
import '../providers/user_provider.dart';

class UserDetailScreen extends ConsumerWidget {
  const UserDetailScreen({
    super.key,
    required this.config,
    required this.userId,
  });

  final UserManagementConfig config;
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(userDetailProvider(userId));
    final mutationState = ref.watch(userMutationProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return DashboardShell(
      title: config.detailTitle,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: detailAsync.when(
        data: (user) {
          final currentUserId = currentUserAsync.valueOrNull?.id;
          final isSelf = currentUserId == user.id;

          final institutionName = user.institutionId == null
              ? '—'
              : ref.watch(institutionDetailProvider(user.institutionId!)).when(
                    data: (institution) =>
                        '${institution.name} (${institution.code})',
                    loading: () => 'Cargando institución...',
                    error: (_, __) => 'Institución #${user.institutionId}',
                  );

          return _DetailBody(
            user: user,
            institutionName: institutionName,
            isProcessing: mutationState.isLoading,
            canChangeStatus: !isSelf,
            onEdit: () => context.push(config.editRoute(user.id)),
            onStatusChange: (status) async {
              final label = UserAccountStatus.fromApi(status).label;
              final confirmed = await ConfirmDialog.show(
                context,
                title: 'Cambiar estado',
                message:
                    '¿Deseas cambiar el estado de "${user.fullName}" a $label?',
                confirmLabel: 'Confirmar',
              );
              if (!confirmed || !context.mounted) return;

              final success = await ref
                  .read(userMutationProvider.notifier)
                  .updateStatus(user.id, status);

              if (!context.mounted) return;

              if (success) {
                ref.invalidate(userDetailProvider(userId));
                ref.invalidate(userListProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Estado actualizado')),
                );
              } else {
                final error = ref.read(userMutationProvider).error;
                final message = error is AppException
                    ? error.message
                    : 'No se pudo actualizar el estado';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No se pudo cargar el usuario'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(userDetailProvider(userId)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.user,
    required this.institutionName,
    required this.isProcessing,
    required this.canChangeStatus,
    required this.onEdit,
    required this.onStatusChange,
  });

  final ManagedUser user;
  final String institutionName;
  final bool isProcessing;
  final bool canChangeStatus;
  final VoidCallback onEdit;
  final ValueChanged<String> onStatusChange;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isActive = user.status == UserAccountStatus.active;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        label: Text(user.status.label),
                        backgroundColor: isActive
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(label: 'Correo', value: user.email),
                  _InfoRow(label: 'Rol', value: user.role.label),
                  _InfoRow(label: 'Institución', value: institutionName),
                  _InfoRow(label: 'Teléfono', value: user.phone ?? '—'),
                  _InfoRow(
                    label: 'Último acceso',
                    value: user.lastLoginAt == null
                        ? '—'
                        : dateFormat.format(user.lastLoginAt!),
                  ),
                  _InfoRow(
                    label: 'Creado',
                    value: dateFormat.format(user.createdAt),
                  ),
                  _InfoRow(
                    label: 'Actualizado',
                    value: dateFormat.format(user.updatedAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isProcessing ? null : onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar usuario'),
            ),
          ),
          if (canChangeStatus) ...[
            const SizedBox(height: 24),
            Text(
              'Cambiar estado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: UserAccountStatus.values.map((status) {
                final selected = user.status == status;
                return FilterChip(
                  label: Text(status.label),
                  selected: selected,
                  onSelected: selected || isProcessing
                      ? null
                      : (_) => onStatusChange(status.apiValue),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
