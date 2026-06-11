import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/admin_provider.dart';

class VectorAdminScreen extends ConsumerWidget {
  const VectorAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rebuildState = ref.watch(vectorRebuildProvider);
    final isLoading = rebuildState.isLoading;
    final errorMessage = rebuildState.whenOrNull(
      error: (error, _) => error is AppException
          ? error.message
          : 'No se pudo reconstruir el índice',
    );
    final result = rebuildState.valueOrNull;

    return DashboardShell(
      title: 'Índice vectorial Qdrant',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: isLoading ? null : () => context.pop(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Reconstruye el índice de carreras en Qdrant a partir de MySQL. '
              'Úsalo después de cambios masivos en el catálogo.',
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(errorMessage),
                ),
              ),
            if (result != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Colección: ${result['collection'] ?? ''}'),
                      Text('Indexadas: ${result['indexed'] ?? 0}'),
                      Text('Dimensión: ${result['vector_size'] ?? 0}'),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            FilledButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                      final data = await ref
                          .read(vectorRebuildProvider.notifier)
                          .rebuild();
                      if (!context.mounted || data == null) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Índice reconstruido correctamente'),
                        ),
                      );
                    },
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Reconstruir índice de carreras'),
            ),
          ],
        ),
      ),
    );
  }
}
