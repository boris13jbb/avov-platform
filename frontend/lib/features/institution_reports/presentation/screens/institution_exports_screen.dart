import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../providers/export_provider.dart';

class InstitutionExportsScreen extends ConsumerWidget {
  const InstitutionExportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportMutationProvider);
    final isBusy = exportState.isLoading;

    return DashboardShell(
      title: 'Exportaciones',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: isBusy ? null : () => context.pop(),
      ),
      body: Stack(
        children: [
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              Text(
                'Descarga datos de tu institución en formato CSV.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _ExportCard(
                title: 'Estudiantes',
                description:
                    'Listado de estudiantes con identificación, grado, correo y estado.',
                icon: Icons.groups_outlined,
                enabled: !isBusy,
                onTap: () => _export(context, ref, ExportType.students),
              ),
              const SizedBox(height: 12),
              _ExportCard(
                title: 'Resultados de tests',
                description:
                    'Resultados RIASEC de tests completados con perfiles y puntajes.',
                icon: Icons.insights_outlined,
                enabled: !isBusy,
                onTap: () => _export(context, ref, ExportType.testResults),
              ),
            ],
          ),
          if (isBusy) const LoadingOverlay(),
        ],
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    ExportType type,
  ) async {
    final fileName =
        await ref.read(exportMutationProvider.notifier).downloadAndOpen(type);

    if (!context.mounted) return;

    if (fileName != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archivo $fileName descargado')),
      );
    } else {
      final error = ref.read(exportMutationProvider).error;
      final message = error is AppException
          ? error.message
          : 'No se pudo descargar el archivo';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: enabled ? onTap : null,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Descargar CSV'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
