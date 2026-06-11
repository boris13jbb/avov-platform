import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/recommendation.dart';
import '../../../../shared/widgets/ethical_disclaimer_banner.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/results_provider.dart';

class StudentRecommendationsScreen extends ConsumerWidget {
  const StudentRecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(studentDashboardProvider);
    final mutationState = ref.watch(resultsMutationProvider);
    final isBusy = mutationState.isLoading;

    return DashboardShell(
      title: 'Carreras recomendadas',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: isBusy ? null : () => context.pop(),
      ),
      body: Stack(
        children: [
          dashboardAsync.when(
            data: (data) {
              final studentId = (data['student_id'] as num?)?.toInt();
              final test = data['test'] as Map<String, dynamic>? ?? {};
              final sessionId =
                  (test['latest_completed_session_id'] as num?)?.toInt();

              if (studentId == null) {
                return const Center(child: Text('Perfil de estudiante no disponible'));
              }

              final recommendationsAsync =
                  ref.watch(studentRecommendationsProvider(studentId));

              return recommendationsAsync.when(
                data: (list) {
                  if (list.items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Aún no tienes recomendaciones generadas.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: isBusy
                                  ? null
                                  : () => _generate(
                                        context,
                                        ref,
                                        studentId,
                                        sessionId,
                                      ),
                              icon: const Icon(Icons.auto_awesome_outlined),
                              label: const Text('Generar recomendaciones'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(studentRecommendationsProvider(studentId));
                      await ref.read(
                        studentRecommendationsProvider(studentId).future,
                      );
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        16 + MediaQuery.of(context).padding.bottom,
                      ),
                      children: [
                        if (list.aiSummary != null &&
                            list.aiSummary!.isNotEmpty) ...[
                          Card(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.35),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resumen de orientación',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(list.aiSummary!),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ...list.items.map(
                          (item) => _RecommendationCard(item: item),
                        ),
                        const SizedBox(height: 16),
                        EthicalDisclaimerBanner(
                          message: list.ethicalDisclaimer.isNotEmpty
                              ? list.ethicalDisclaimer
                              : null,
                        ),
                      ],
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) {
                  final notGenerated = error is AppException &&
                      error.message.contains('No hay recomendaciones');
                  if (notGenerated) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Aún no tienes recomendaciones generadas.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: isBusy
                                  ? null
                                  : () => _generate(
                                        context,
                                        ref,
                                        studentId,
                                        sessionId,
                                      ),
                              icon: const Icon(Icons.auto_awesome_outlined),
                              label: const Text('Generar recomendaciones'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No se pudieron cargar las recomendaciones'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => ref.invalidate(
                            studentRecommendationsProvider(studentId),
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                },
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
          if (isBusy) const LoadingOverlay(message: 'Generando recomendaciones...'),
        ],
      ),
    );
  }

  Future<void> _generate(
    BuildContext context,
    WidgetRef ref,
    int studentId,
    int? sessionId,
  ) async {
    final result = await ref
        .read(resultsMutationProvider.notifier)
        .generateRecommendations(testSessionId: sessionId);

    if (!context.mounted) return;

    if (result != null) {
      ref.invalidate(studentDashboardProvider);
      ref.invalidate(studentRecommendationsProvider(studentId));
    } else {
      final error = ref.read(resultsMutationProvider).error;
      final message = error is AppException
          ? error.message
          : 'No se pudieron generar las recomendaciones';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item});

  final CareerRecommendation item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.career.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text('${item.matchPercentage.toStringAsFixed(0)}%'),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.career.area,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Perfil RIASEC carrera: ${item.career.riasecProfile}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (item.aiExplanation != null && item.aiExplanation!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(item.aiExplanation!),
            ],
          ],
        ),
      ),
    );
  }
}
