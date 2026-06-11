import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/career.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/admin_provider.dart';

class CareerDetailScreen extends ConsumerWidget {
  const CareerDetailScreen({super.key, required this.careerId});

  final int careerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(careerDetailProvider(careerId));
    final mutationState = ref.watch(careerMutationProvider);

    return DashboardShell(
      title: 'Detalle de carrera',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: detailAsync.when(
        data: (career) => _DetailBody(
          career: career,
          isProcessing: mutationState.isLoading,
          onEdit: () => context.push(RouteNames.adminCareerEdit(career.id)),
          onDeactivate: () async {
            if (career.status == CareerStatus.inactive) return;

            final confirmed = await ConfirmDialog.show(
              context,
              title: 'Desactivar carrera',
              message:
                  '¿Deseas desactivar "${career.name}"? Dejará de aparecer en recomendaciones activas.',
              confirmLabel: 'Desactivar',
            );
            if (!confirmed || !context.mounted) return;

            final result = await ref
                .read(careerMutationProvider.notifier)
                .deactivate(career.id);

            if (!context.mounted) return;

            if (result != null) {
              ref.invalidate(careerDetailProvider(careerId));
              ref.invalidate(careerListProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.message)),
              );
            } else {
              final error = ref.read(careerMutationProvider).error;
              final message = error is AppException
                  ? error.message
                  : 'No se pudo desactivar la carrera';
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
              const Text('No se pudo cargar la carrera'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(careerDetailProvider(careerId)),
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
    required this.career,
    required this.isProcessing,
    required this.onEdit,
    required this.onDeactivate,
  });

  final Career career;
  final bool isProcessing;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  career.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Chip(label: Text(career.status.label)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _InfoTile(label: 'Área', value: career.area),
        _InfoTile(label: 'Perfil RIASEC', value: career.riasecProfile),
        _InfoTile(label: 'Tipo de título', value: career.degreeType.label),
        _InfoTile(
          label: 'Tipo de institución',
          value: career.institutionType.label,
        ),
        _InfoTile(label: 'Campo laboral', value: career.employmentField),
        if (career.duration != null)
          _InfoTile(label: 'Duración', value: career.duration!),
        _InfoTile(label: 'Descripción', value: career.description),
        _InfoTile(
          label: 'Actualizada',
          value: dateFormat.format(career.updatedAt.toLocal()),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: isProcessing ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar carrera'),
        ),
        if (career.status == CareerStatus.active) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isProcessing ? null : onDeactivate,
            icon: const Icon(Icons.block_outlined),
            label: const Text('Desactivar carrera'),
          ),
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
