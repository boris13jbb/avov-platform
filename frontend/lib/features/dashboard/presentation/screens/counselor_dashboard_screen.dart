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

class CounselorDashboardScreen extends ConsumerWidget {
  const CounselorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(counselorDashboardProvider);
    final apiBaseUrl = ref.watch(dioClientProvider).config.apiBaseUrl;

    return DashboardShell(
      title: 'Panel del orientador',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(counselorDashboardProvider);
          await ref.read(counselorDashboardProvider.future);
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
                    fallback: 'No se pudieron cargar las métricas del orientador.',
                  )
                : null,
            onRetry: () => ref.invalidate(counselorDashboardProvider),
            child: dashboardAsync.when(
              data: (data) {
                final summary =
                    data['summary'] as Map<String, dynamic>? ?? {};
                final attention =
                    data['students_needing_attention'] as List<dynamic>? ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de estudiantes asignados',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    DashboardMetricsGrid(
                      metrics: [
                        MetricCard(
                          label: 'Asignados',
                          value: '${summary['assigned_students'] ?? 0}',
                          icon: Icons.groups_outlined,
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
                          label: 'Pendientes de revisión',
                          value: '${summary['pending_review'] ?? 0}',
                          icon: Icons.rate_review_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push(RouteNames.counselorStudents),
                        icon: const Icon(Icons.groups_outlined),
                        label: const Text('Ver estudiantes asignados'),
                      ),
                    ),
                    if (attention.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Estudiantes pendientes de observación',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: attention.map((item) {
                            final map = item as Map<String, dynamic>;
                            final studentId =
                                (map['student_id'] as num?)?.toInt();
                            return ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(map['full_name'] as String? ?? ''),
                              subtitle: Text(
                                'Perfil: ${map['dominant_profile'] ?? 'N/D'}',
                              ),
                              trailing: map['has_report'] == true
                                  ? const Icon(Icons.picture_as_pdf_outlined)
                                  : const Icon(Icons.chevron_right),
                              onTap: studentId == null
                                  ? null
                                  : () => context.push(
                                        RouteNames.counselorStudentResults(
                                          studentId,
                                        ),
                                      ),
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
