import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/institution.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/institution_provider.dart';

class InstitutionDetailScreen extends ConsumerWidget {
  const InstitutionDetailScreen({super.key, required this.institutionId});

  final int institutionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(institutionDetailProvider(institutionId));
    final mutationState = ref.watch(institutionMutationProvider);

    return DashboardShell(
      title: 'Detalle institución',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: detailAsync.when(
        data: (institution) => _DetailBody(
          institution: institution,
          isProcessing: mutationState.isLoading,
          onEdit: () => context.push(
            RouteNames.adminInstitutionEdit(institution.id),
          ),
          onDeactivate: () async {
            final confirmed = await ConfirmDialog.show(
              context,
              title: 'Desactivar institución',
              message:
                  '¿Deseas desactivar "${institution.name}"? Los usuarios asociados no podrán operar hasta reactivarla.',
              confirmLabel: 'Desactivar',
            );
            if (!confirmed || !context.mounted) return;

            final success = await ref
                .read(institutionMutationProvider.notifier)
                .deactivate(institution.id);

            if (!context.mounted) return;

            if (success) {
              ref.invalidate(institutionDetailProvider(institutionId));
              ref.invalidate(institutionListProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Institución desactivada')),
              );
            } else {
              final error = ref.read(institutionMutationProvider).error;
              final message = error is AppException
                  ? error.message
                  : 'No se pudo desactivar la institución';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No se pudo cargar la institución'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(institutionDetailProvider(institutionId)),
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
    required this.institution,
    required this.isProcessing,
    required this.onEdit,
    required this.onDeactivate,
  });

  final Institution institution;
  final bool isProcessing;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isActive = institution.status == InstitutionStatus.active;

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
                          institution.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        label: Text(institution.status.label),
                        backgroundColor: isActive
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(label: 'Código', value: institution.code),
                  _InfoRow(label: 'Provincia', value: institution.province),
                  _InfoRow(label: 'Ciudad', value: institution.city),
                  _InfoRow(label: 'Dirección', value: institution.address ?? '—'),
                  _InfoRow(label: 'Teléfono', value: institution.phone ?? '—'),
                  _InfoRow(label: 'Correo', value: institution.email ?? '—'),
                  _InfoRow(
                    label: 'Creada',
                    value: dateFormat.format(institution.createdAt),
                  ),
                  _InfoRow(
                    label: 'Actualizada',
                    value: dateFormat.format(institution.updatedAt),
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
              label: const Text('Editar institución'),
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isProcessing ? null : onDeactivate,
                icon: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.block_outlined),
                label: const Text('Desactivar institución'),
              ),
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
