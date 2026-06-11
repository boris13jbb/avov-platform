import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/providers.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/ethical_disclaimer_banner.dart';
import '../../../results/presentation/providers/results_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_body.dart';
import '../widgets/dashboard_error_message.dart';
import '../widgets/dashboard_metrics_grid.dart';
import '../widgets/dashboard_shell.dart';
import '../widgets/metric_card.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(studentDashboardProvider);
    final apiBaseUrl = ref.watch(dioClientProvider).config.apiBaseUrl;

    return DashboardShell(
      title: 'Mi panel',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentDashboardProvider);
          await ref.read(studentDashboardProvider.future);
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
                    fallback: 'No se pudo cargar tu panel.',
                  )
                : null,
            onRetry: () => ref.invalidate(studentDashboardProvider),
            child: dashboardAsync.when(
              data: (data) => _StudentDashboardContent(data: data),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentDashboardContent extends ConsumerWidget {
  const _StudentDashboardContent({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final test = data['test'] as Map<String, dynamic>? ?? {};
    final riasec = data['riasec_result'] as Map<String, dynamic>?;
    final nextActions = (data['next_actions'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    final openSession = test['open_session'] as Map<String, dynamic>?;
    final sessionId = (test['latest_completed_session_id'] as num?)?.toInt();

    final status = test['status'] as String? ?? 'Sin test';
    final progress = openSession?['progress_percent'];
    final isBusy = ref.watch(resultsMutationProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado de tu orientación vocacional',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        DashboardMetricsGrid(
          metrics: [
            MetricCard(
              label: 'Estado del test',
              value: _formatStatus(status),
              icon: Icons.quiz_outlined,
            ),
            MetricCard(
              label: 'Recomendaciones',
              value: '${data['recommendations_count'] ?? 0}',
              icon: Icons.school_outlined,
            ),
            MetricCard(
              label: 'Reporte PDF',
              value: data['has_report'] == true ? 'Disponible' : 'Pendiente',
              icon: Icons.picture_as_pdf_outlined,
            ),
            if (progress != null)
              MetricCard(
                label: 'Progreso actual',
                value: '$progress%',
                icon: Icons.timeline,
              ),
          ],
        ),
        if (nextActions.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Acciones',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...nextActions.map((action) {
            final config = _actionConfig(
              action: action,
              openSession: openSession,
              sessionId: sessionId,
              isBusy: isBusy,
            );
            if (config == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: config.isPrimary
                    ? FilledButton.icon(
                        onPressed: config.enabled
                            ? () => config.onTap(context, ref)
                            : null,
                        icon: Icon(config.icon),
                        label: Text(config.label),
                      )
                    : OutlinedButton.icon(
                        onPressed: config.enabled
                            ? () => config.onTap(context, ref)
                            : null,
                        icon: Icon(config.icon),
                        label: Text(config.label),
                      ),
              ),
            );
          }),
        ],
        if (riasec != null) ...[
          const SizedBox(height: 24),
          Text(
            'Perfil RIASEC',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dominante: ${riasec['dominant_profile'] ?? 'N/D'}'),
                  Text('Secundario: ${riasec['secondary_profile'] ?? 'N/D'}'),
                  Text('Combinado: ${riasec['combined_profile'] ?? 'N/D'}'),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const EthicalDisclaimerBanner(),
      ],
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'COMPLETED':
        return 'Completado';
      case 'IN_PROGRESS':
        return 'En progreso';
      case 'STARTED':
        return 'Iniciado';
      default:
        return status;
    }
  }

  _ActionConfig? _actionConfig({
    required String action,
    required Map<String, dynamic>? openSession,
    required int? sessionId,
    required bool isBusy,
  }) {
    switch (action) {
      case 'start_test':
        return _ActionConfig(
          label: 'Iniciar test vocacional',
          icon: Icons.play_circle_outline,
          isPrimary: true,
          enabled: !isBusy,
          onTap: (context, _) =>
              context.push(RouteNames.studentTestInstructions),
        );
      case 'continue_test':
        final openSessionId = (openSession?['id'] as num?)?.toInt();
        return _ActionConfig(
          label: 'Continuar test',
          icon: Icons.play_arrow_outlined,
          isPrimary: true,
          enabled: !isBusy,
          onTap: (context, _) {
            if (openSessionId != null) {
              context.go(RouteNames.studentTestSession(openSessionId));
            } else {
              context.push(
                '${RouteNames.studentTestInstructions}?continue=true',
              );
            }
          },
        );
      case 'view_results':
        return _ActionConfig(
          label: 'Ver resultados RIASEC',
          icon: Icons.insights_outlined,
          isPrimary: true,
          enabled: !isBusy,
          onTap: (context, _) => context.push(RouteNames.studentResults),
        );
      case 'generate_recommendations':
        return _ActionConfig(
          label: 'Generar recomendaciones',
          icon: Icons.auto_awesome_outlined,
          isPrimary: true,
          enabled: !isBusy && sessionId != null,
          onTap: (context, ref) => _generateRecommendations(
            context,
            ref,
            sessionId!,
          ),
        );
      case 'download_pdf':
        return _ActionConfig(
          label: 'Descargar reporte PDF',
          icon: Icons.picture_as_pdf_outlined,
          isPrimary: false,
          enabled: !isBusy && sessionId != null,
          onTap: (context, ref) => _downloadPdf(context, ref, sessionId!),
        );
      case 'open_assistant':
        return _ActionConfig(
          label: 'Asistente virtual',
          icon: Icons.smart_toy_outlined,
          isPrimary: false,
          enabled: !isBusy,
          onTap: (context, _) => context.push(RouteNames.studentAssistant),
        );
      case 'view_recommendations':
        return _ActionConfig(
          label: 'Ver carreras recomendadas',
          icon: Icons.school_outlined,
          isPrimary: false,
          enabled: !isBusy,
          onTap: (context, _) => context.push(RouteNames.studentRecommendations),
        );
      case 'complete_profile':
        return _ActionConfig(
          label: 'Completar mi perfil',
          icon: Icons.person_outline,
          isPrimary: false,
          enabled: !isBusy,
          onTap: (context, _) => context.push(RouteNames.studentProfile),
        );
      default:
        return null;
    }
  }

  Future<void> _generateRecommendations(
    BuildContext context,
    WidgetRef ref,
    int sessionId,
  ) async {
    final result = await ref
        .read(resultsMutationProvider.notifier)
        .generateRecommendations(testSessionId: sessionId);

    if (!context.mounted) return;

    if (result != null) {
      ref.invalidate(studentDashboardProvider);
      final studentId = (data['student_id'] as num?)?.toInt();
      if (studentId != null) {
        ref.invalidate(studentRecommendationsProvider(studentId));
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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
        SnackBar(content: Text('PDF abierto: $reportCode')),
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

class _ActionConfig {
  const _ActionConfig({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final void Function(BuildContext context, WidgetRef ref) onTap;
}
