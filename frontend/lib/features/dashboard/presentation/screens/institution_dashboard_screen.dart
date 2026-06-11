import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/providers.dart';
import '../../../../router/route_names.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_body.dart';
import '../widgets/dashboard_error_message.dart';
import '../widgets/dashboard_metrics_grid.dart';
import '../widgets/dashboard_shell.dart';
import '../widgets/metric_card.dart';

class InstitutionDashboardScreen extends ConsumerWidget {
  const InstitutionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(institutionDashboardProvider);
    final apiBaseUrl = ref.watch(dioClientProvider).config.apiBaseUrl;

    return DashboardShell(
      title: 'Panel institucional',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(institutionDashboardProvider);
          await ref.read(institutionDashboardProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: DashboardBody(
            isLoading: dashboardAsync.isLoading,
            errorMessage: dashboardAsync.hasError
                ? buildDashboardErrorMessage(
                    error: dashboardAsync.error,
                    apiBaseUrl: apiBaseUrl,
                    fallback: 'No se pudieron cargar las métricas institucionales.',
                  )
                : null,
            onRetry: () => ref.invalidate(institutionDashboardProvider),
            child: dashboardAsync.when(
              data: (data) {
                final summary =
                    data['summary'] as Map<String, dynamic>? ?? {};
                final distribution =
                    data['riasec_distribution'] as List<dynamic>? ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['institution_name'] as String? ?? 'Institución',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    DashboardMetricsGrid(
                      metrics: [
                        MetricCard(
                          label: 'Estudiantes',
                          value: '${summary['students_total'] ?? 0}',
                          subtitle:
                              'Activos: ${summary['students_active'] ?? 0}',
                          icon: Icons.groups_outlined,
                        ),
                        MetricCard(
                          label: 'Orientadores',
                          value: '${summary['counselors_total'] ?? 0}',
                          icon: Icons.support_agent_outlined,
                        ),
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
                    Text(
                      'Acciones rápidas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.push(RouteNames.institutionCounselors),
                        icon: const Icon(Icons.support_agent_outlined),
                        label: const Text('Gestionar orientadores'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push(RouteNames.institutionStudents),
                        icon: const Icon(Icons.groups_outlined),
                        label: const Text('Gestionar estudiantes'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push(RouteNames.institutionReports),
                        icon: const Icon(Icons.assessment_outlined),
                        label: const Text('Reportes institución'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push(RouteNames.institutionExports),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Exportaciones CSV'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push(RouteNames.institutionSettings),
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Configuración institución'),
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
                              title: Text(map['profile'] as String? ?? ''),
                              trailing: Text('${map['count'] ?? 0}'),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
