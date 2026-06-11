import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/dashboard_body.dart';
import '../../../dashboard/presentation/widgets/dashboard_metrics_grid.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../../../dashboard/presentation/widgets/metric_card.dart';
import '../../../results/presentation/providers/results_provider.dart';
import '../../../../shared/widgets/loading_overlay.dart';

class InstitutionReportsScreen extends ConsumerWidget {
  const InstitutionReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(institutionDashboardProvider);
    final pdfMutation = ref.watch(resultsMutationProvider);
    final isBusy = pdfMutation.isLoading;

    return DashboardShell(
      title: 'Reportes institución',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: isBusy ? null : () => context.pop(),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(institutionDashboardProvider);
              await ref.read(institutionDashboardProvider.future);
            },
            child: DashboardBody(
              isLoading: dashboardAsync.isLoading,
              errorMessage: dashboardAsync.hasError
                  ? 'No se pudieron cargar los reportes institucionales.'
                  : null,
              onRetry: () => ref.invalidate(institutionDashboardProvider),
              child: dashboardAsync.when(
                data: (data) => _ReportsContent(
                  data: data,
                  isBusy: isBusy,
                  onDownloadPdf: (sessionId) =>
                      _downloadPdf(context, ref, sessionId),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
          if (isBusy) const LoadingOverlay(),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(
    BuildContext context,
    WidgetRef ref,
    int sessionId,
  ) async {
    final reportCode = await ref
        .read(resultsMutationProvider.notifier)
        .downloadAndOpenPdf(sessionId);

    if (!context.mounted) return;

    if (reportCode != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reporte $reportCode abierto')),
      );
    } else {
      final error = ref.read(resultsMutationProvider).error;
      final message = error is AppException
          ? error.message
          : 'No se pudo descargar el PDF';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({
    required this.data,
    required this.isBusy,
    required this.onDownloadPdf,
  });

  final Map<String, dynamic> data;
  final bool isBusy;
  final Future<void> Function(int sessionId) onDownloadPdf;

  @override
  Widget build(BuildContext context) {
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final testsByStatus =
        data['tests_by_status'] as Map<String, dynamic>? ?? {};
    final distribution =
        data['riasec_distribution'] as List<dynamic>? ?? [];
    final recentCompletions =
        data['recent_completions'] as List<dynamic>? ?? [];
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        Text(
          data['institution_name'] as String? ?? 'Institución',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Resumen vocacional y reportes PDF generados en tu institución.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        DashboardMetricsGrid(
          metrics: [
            MetricCard(
              label: 'Tests completados',
              value: '${summary['tests_completed'] ?? 0}',
              icon: Icons.check_circle_outline,
            ),
            MetricCard(
              label: 'En progreso',
              value: '${summary['tests_in_progress'] ?? 0}',
              icon: Icons.pending_outlined,
            ),
            MetricCard(
              label: 'Sin iniciar',
              value: '${summary['tests_not_started'] ?? 0}',
              icon: Icons.hourglass_empty_outlined,
            ),
            MetricCard(
              label: 'Reportes PDF',
              value: '${summary['reports_generated'] ?? 0}',
              icon: Icons.picture_as_pdf_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Tests por estado', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _StatusRow(label: 'Completados', value: testsByStatus['COMPLETED']),
              _StatusRow(label: 'En progreso', value: testsByStatus['IN_PROGRESS']),
              _StatusRow(label: 'Iniciados', value: testsByStatus['STARTED']),
              _StatusRow(label: 'Cancelados', value: testsByStatus['CANCELLED']),
            ],
          ),
        ),
        if (distribution.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Distribución RIASEC dominante',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: distribution.map((item) {
                final map = item as Map<String, dynamic>;
                return ListTile(
                  title: Text(map['profile'] as String? ?? 'N/D'),
                  trailing: Text('${map['count'] ?? 0}'),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Finalizaciones recientes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (recentCompletions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aún no hay tests completados recientes.'),
            ),
          )
        else
          Card(
            child: Column(
              children: recentCompletions.map((item) {
                final map = item as Map<String, dynamic>;
                final sessionId = (map['test_session_id'] as num?)?.toInt();
                final finishedAt = map['finished_at'] as String?;
                final finishedLabel = finishedAt == null
                    ? 'Sin fecha'
                    : dateFormat.format(DateTime.parse(finishedAt));

                return ListTile(
                  title: Text(map['student_name'] as String? ?? ''),
                  subtitle: Text(
                    'Perfil: ${map['dominant_profile'] ?? 'N/D'} · $finishedLabel',
                  ),
                  trailing: sessionId == null
                      ? null
                      : IconButton(
                          tooltip: 'Descargar PDF',
                          onPressed: isBusy
                              ? null
                              : () => onDownloadPdf(sessionId),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                        ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text('${value ?? 0}'),
    );
  }
}
