import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/ethical_disclaimer_banner.dart';
import '../../../../shared/widgets/riasec_chart.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/results_provider.dart';

class StudentResultsScreen extends ConsumerWidget {
  const StudentResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(studentDashboardProvider);
    final mutationState = ref.watch(resultsMutationProvider);
    final isBusy = mutationState.isLoading;

    return DashboardShell(
      title: 'Mis resultados',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: isBusy ? null : () => context.pop(),
      ),
      body: Stack(
        children: [
          dashboardAsync.when(
            data: (data) {
              final riasec = data['riasec_result'] as Map<String, dynamic>?;
              final test = data['test'] as Map<String, dynamic>? ?? {};
              final studentId = (data['student_id'] as num?)?.toInt();
              final sessionId =
                  (test['latest_completed_session_id'] as num?)?.toInt();
              final hasRecommendations = data['has_recommendations'] == true;
              final hasReport = data['has_report'] == true;
              final reportCode = data['latest_report_code'] as String?;

              if (riasec == null || sessionId == null || studentId == null) {
                return const Center(
                  child: Text('Aún no tienes un test completado.'),
                );
              }

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Perfil RIASEC',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _ScoreRow(
                              label: 'Dominante',
                              value: riasec['dominant_profile'] as String? ?? '—',
                              highlight: true,
                            ),
                            _ScoreRow(
                              label: 'Secundario',
                              value: riasec['secondary_profile'] as String? ?? '—',
                            ),
                            _ScoreRow(
                              label: 'Combinado',
                              value: riasec['combined_profile'] as String? ?? '—',
                            ),
                            const Divider(height: 24),
                            RiasecChart(
                              scores: RiasecScores.fromMap(riasec),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (riasec['interpretation'] != null &&
                        (riasec['interpretation'] as String).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(riasec['interpretation'] as String),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Siguientes pasos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (!hasRecommendations)
                      FilledButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => _generateRecommendations(
                                  context,
                                  ref,
                                  sessionId,
                                  studentId,
                                ),
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('Generar recomendaciones'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => context.push(RouteNames.studentRecommendations),
                        icon: const Icon(Icons.school_outlined),
                        label: Text(
                          'Ver carreras recomendadas (${data['recommendations_count'] ?? 0})',
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: isBusy || !hasRecommendations
                          ? null
                          : () => _downloadPdf(context, ref, sessionId),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        hasReport
                            ? 'Descargar PDF ($reportCode)'
                            : 'Generar y descargar PDF',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const EthicalDisclaimerBanner(),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: FilledButton(
                onPressed: () => ref.invalidate(studentDashboardProvider),
                child: const Text('Reintentar'),
              ),
            ),
          ),
          if (isBusy) const LoadingOverlay(message: 'Procesando...'),
        ],
      ),
    );
  }

  Future<void> _generateRecommendations(
    BuildContext context,
    WidgetRef ref,
    int sessionId,
    int studentId,
  ) async {
    final result = await ref
        .read(resultsMutationProvider.notifier)
        .generateRecommendations(testSessionId: sessionId);

    if (!context.mounted) return;

    if (result != null) {
      ref.invalidate(studentDashboardProvider);
      ref.invalidate(studentRecommendationsProvider(studentId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se generaron ${result.items.length} recomendaciones',
          ),
        ),
      );
      context.push(RouteNames.studentRecommendations);
    } else {
      final error = ref.read(resultsMutationProvider).error;
      final message = error is AppException
          ? error.message
          : 'No se pudieron generar las recomendaciones';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
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
      ref.invalidate(studentDashboardProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF listo: $reportCode')),
      );
    } else {
      final error = ref.read(resultsMutationProvider).error;
      final message = error is AppException
          ? error.message
          : 'No se pudo descargar el PDF';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: highlight
                ? Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                : null,
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
