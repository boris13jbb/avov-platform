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

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(superAdminDashboardProvider);
    final apiBaseUrl = ref.watch(dioClientProvider).config.apiBaseUrl;

    return DashboardShell(
      title: 'Panel global',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(superAdminDashboardProvider);
          await ref.read(superAdminDashboardProvider.future);
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
                    fallback: 'No se pudieron cargar las métricas globales.',
                  )
                : null,
            onRetry: () => ref.invalidate(superAdminDashboardProvider),
            child: dashboardAsync.when(
              data: (data) {
                final summary =
                    data['summary'] as Map<String, dynamic>? ?? {};
                final usersByRole =
                    summary['users_by_role'] as Map<String, dynamic>? ?? {};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Métricas globales del sistema',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    DashboardMetricsGrid(
                      metrics: [
                        MetricCard(
                          label: 'Instituciones',
                          value: '${summary['institutions_total'] ?? 0}',
                          subtitle:
                              'Activas: ${summary['institutions_active'] ?? 0}',
                          icon: Icons.apartment_outlined,
                        ),
                        MetricCard(
                          label: 'Estudiantes',
                          value: '${summary['students_total'] ?? 0}',
                          icon: Icons.groups_outlined,
                        ),
                        MetricCard(
                          label: 'Tests completados',
                          value: '${summary['tests_completed'] ?? 0}',
                          icon: Icons.check_circle_outline,
                        ),
                        MetricCard(
                          label: 'Tests en progreso',
                          value: '${summary['tests_in_progress'] ?? 0}',
                          icon: Icons.pending_outlined,
                        ),
                        MetricCard(
                          label: 'Reportes PDF',
                          value: '${summary['reports_generated'] ?? 0}',
                          icon: Icons.picture_as_pdf_outlined,
                        ),
                        MetricCard(
                          label: 'Carreras activas',
                          value: '${summary['careers_active'] ?? 0}',
                          icon: Icons.work_outline,
                        ),
                        MetricCard(
                          label: 'Preguntas activas',
                          value: '${summary['questions_active'] ?? 0}',
                          icon: Icons.help_outline,
                        ),
                        MetricCard(
                          label: 'Usuarios totales',
                          value: '${summary['users_total'] ?? 0}',
                          icon: Icons.people_outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Usuarios por rol',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _RoleRow(
                              label: 'Super Admin',
                              value: usersByRole['SUPER_ADMIN'] ?? 0,
                            ),
                            _RoleRow(
                              label: 'Admin institucional',
                              value: usersByRole['INSTITUTION_ADMIN'] ?? 0,
                            ),
                            _RoleRow(
                              label: 'Orientadores',
                              value: usersByRole['COUNSELOR'] ?? 0,
                            ),
                            _RoleRow(
                              label: 'Estudiantes',
                              value: usersByRole['STUDENT'] ?? 0,
                            ),
                          ],
                        ),
                      ),
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
                            context.push(RouteNames.adminInstitutions),
                        icon: const Icon(Icons.apartment_outlined),
                        label: const Text('Gestionar instituciones'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(RouteNames.adminUsers),
                        icon: const Icon(Icons.people_outlined),
                        label: const Text('Gestionar usuarios'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(RouteNames.adminCareers),
                        icon: const Icon(Icons.work_outline),
                        label: const Text('Catálogo de carreras'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(RouteNames.adminQuestions),
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Preguntas RIASEC'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(RouteNames.adminVector),
                        icon: const Icon(Icons.hub_outlined),
                        label: const Text('Índice vectorial Qdrant'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(RouteNames.adminAudit),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Auditoría'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(RouteNames.adminSettings),
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Configuración del sistema'),
                      ),
                    ),
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

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
