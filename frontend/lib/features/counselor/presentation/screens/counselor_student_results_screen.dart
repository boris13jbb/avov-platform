import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/recommendation.dart';
import '../../../../shared/widgets/ethical_disclaimer_banner.dart';
import '../../../../shared/widgets/riasec_chart.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../results/presentation/providers/results_provider.dart';
import '../../../students/domain/student_management_config.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/counselor_provider.dart';

class CounselorStudentResultsScreen extends ConsumerWidget {
  const CounselorStudentResultsScreen({
    super.key,
    required this.studentId,
  });

  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(counselorStudentCaseProvider(studentId));
    final mutationState = ref.watch(resultsMutationProvider);
    final isBusy = mutationState.isLoading;
    const config = StudentManagementConfig.counselor;

    return DashboardShell(
      title: config.detailTitle,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: isBusy ? null : () => context.pop(),
      ),
      body: Stack(
        children: [
          caseAsync.when(
            data: (studentCase) => _ResultsBody(
              studentCase: studentCase,
              isBusy: isBusy,
              onRefresh: () async {
                ref.invalidate(counselorStudentCaseProvider(studentId));
                await ref.read(counselorStudentCaseProvider(studentId).future);
              },
              onAddObservation: studentCase.canAddObservation
                  ? () => context.push(config.observationRoute(studentId))
                  : null,
              onDownloadPdf: studentCase.testSessionId == null
                  ? null
                  : () => _downloadPdf(context, ref, studentCase.testSessionId!),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      error is AppException
                          ? error.message
                          : 'No se pudo cargar el resultado del estudiante',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(counselorStudentCaseProvider(studentId)),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
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

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({
    required this.studentCase,
    required this.isBusy,
    required this.onRefresh,
    required this.onAddObservation,
    required this.onDownloadPdf,
  });

  final CounselorStudentCase studentCase;
  final bool isBusy;
  final Future<void> Function() onRefresh;
  final VoidCallback? onAddObservation;
  final VoidCallback? onDownloadPdf;

  @override
  Widget build(BuildContext context) {
    final student = studentCase.student;
    final riasec = studentCase.riasec;
    final recommendationList = studentCase.recommendations;

    if (riasec == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                student.user.fullName,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Este estudiante aún no tiene un test completado con '
                'recomendaciones disponibles para revisión.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Text(
            student.user.fullName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            '${student.identification} · ${student.grade}${student.parallel != null ? " ${student.parallel}" : ""}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'Perfil RIASEC',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ScoreRow(
                    label: 'Dominante',
                    value: riasec.dominantProfile ?? '—',
                    highlight: true,
                  ),
                  _ScoreRow(
                    label: 'Secundario',
                    value: riasec.secondaryProfile ?? '—',
                  ),
                  _ScoreRow(
                    label: 'Combinado',
                    value: riasec.combinedProfile ?? '—',
                  ),
                  const Divider(height: 24),
                  RiasecChart(
                    scores: RiasecScores(
                      scoreR: riasec.scoreR,
                      scoreI: riasec.scoreI,
                      scoreA: riasec.scoreA,
                      scoreS: riasec.scoreS,
                      scoreE: riasec.scoreE,
                      scoreC: riasec.scoreC,
                      dominantProfile: riasec.dominantProfile,
                      secondaryProfile: riasec.secondaryProfile,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (riasec.interpretation != null &&
              riasec.interpretation!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(riasec.interpretation!),
              ),
            ),
          ],
          if (recommendationList != null &&
              recommendationList.items.isEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'El estudiante aún no tiene recomendaciones de carreras '
                  'generadas. Puedes registrar tu observación profesional con '
                  'base en el perfil RIASEC.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
          if (recommendationList != null &&
              recommendationList.items.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Carreras recomendadas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...recommendationList.items.map(
              (item) => _RecommendationCard(item: item),
            ),
            const SizedBox(height: 12),
            const EthicalDisclaimerBanner(),
          ],
          const SizedBox(height: 24),
          if (onAddObservation != null)
            FilledButton.icon(
              onPressed: isBusy ? null : onAddObservation,
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Agregar observación profesional'),
            ),
          if (onDownloadPdf != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onDownloadPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Descargar reporte PDF'),
            ),
          ],
        ],
      ),
    );
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
            style: highlight
                ? Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                : null,
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item});

  final CareerRecommendation item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.career.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text('Área: ${item.career.area}'),
            Text('Compatibilidad: ${item.matchPercentage.toStringAsFixed(1)}%'),
            if (item.aiExplanation != null && item.aiExplanation!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(item.aiExplanation!),
            ],
          ],
        ),
      ),
    );
  }
}
