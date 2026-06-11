import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/question.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/admin_provider.dart';

class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({super.key, required this.questionId});

  final int questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(questionDetailProvider(questionId));
    final mutationState = ref.watch(questionMutationProvider);

    return DashboardShell(
      title: 'Detalle de pregunta',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: detailAsync.when(
        data: (question) => _DetailBody(
          question: question,
          isProcessing: mutationState.isLoading,
          onEdit: () => context.push(RouteNames.adminQuestionEdit(question.id)),
          onDeactivate: () async {
            if (question.status == QuestionStatus.inactive) return;

            final confirmed = await ConfirmDialog.show(
              context,
              title: 'Desactivar pregunta',
              message:
                  '¿Deseas desactivar esta pregunta? No aparecerá en nuevos tests.',
              confirmLabel: 'Desactivar',
            );
            if (!confirmed || !context.mounted) return;

            final success = await ref
                .read(questionMutationProvider.notifier)
                .deactivate(question.id);

            if (!context.mounted) return;

            if (success) {
              ref.invalidate(questionDetailProvider(questionId));
              ref.invalidate(questionListProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pregunta desactivada')),
              );
            } else {
              final error = ref.read(questionMutationProvider).error;
              final message = error is AppException
                  ? error.message
                  : 'No se pudo desactivar la pregunta';
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
              const Text('No se pudo cargar la pregunta'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(questionDetailProvider(questionId)),
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
    required this.question,
    required this.isProcessing,
    required this.onEdit,
    required this.onDeactivate,
  });

  final Question question;
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
                  question.text,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(question.category.code)),
                    Chip(label: Text('Orden ${question.orderNumber}')),
                    Chip(label: Text(question.status.label)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _InfoTile(
          label: 'Categoría',
          value: '${question.category.code} — ${question.category.name}',
        ),
        _InfoTile(
          label: 'Actualizada',
          value: dateFormat.format(question.updatedAt.toLocal()),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: isProcessing ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar pregunta'),
        ),
        if (question.status == QuestionStatus.active) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isProcessing ? null : onDeactivate,
            icon: const Icon(Icons.block_outlined),
            label: const Text('Desactivar pregunta'),
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
