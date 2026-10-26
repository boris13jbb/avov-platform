import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../router/route_names.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../domain/report_history.dart';
import '../providers/report_provider.dart';
import 'download_vocational_pdf_button.dart';

/// Lista el historial de informes PDF y permite descargar el PDF vigente de cada sesión.
class StudentReportsHistorySection extends ConsumerWidget {
  const StudentReportsHistorySection({
    super.key,
    required this.studentId,
    this.saver,
    this.counselorReviewEnabled = false,
  });

  final int studentId;
  final VocationalPdfSaver? saver;
  final bool counselorReviewEnabled;

  static const historyIntroKey = ValueKey('reports-history-intro');

  /// Texto fijo de aclaración (misma semántica en cada fila).
  static const sessionDownloadNote =
      'La acción descarga el PDF vigente de esta sesión.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(studentReportsHistoryProvider(studentId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Historial de informes',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Consulta los registros de informes PDF de este estudiante. '
          'La descarga obtiene el PDF vigente de la sesión asociada, '
          'no una versión histórica concreta del registro.',
          key: historyIntroKey,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        history.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _HistoryNotice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () =>
                ref.invalidate(studentReportsHistoryProvider(studentId)),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aún no hay informes PDF para este estudiante.',
                  key: ValueKey('reports-history-empty'),
                ),
              );
            }
            return Column(
              key: ValueKey('reports-history-list-${page.total}'),
              children: [
                for (final item in page.items)
                  _HistoryTile(
                    item: item,
                    saver: saver,
                    counselorReviewEnabled: counselorReviewEnabled,
                    studentId: studentId,
                  ),
                if (page.total > page.items.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Mostrando ${page.items.length} de ${page.total} informes '
                      '(primera página).',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.studentId,
    this.saver,
    this.counselorReviewEnabled = false,
  });

  final ReportHistoryItem item;
  final int studentId;
  final VocationalPdfSaver? saver;
  final bool counselorReviewEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel =
        DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt.toLocal());
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.reportCode,
            key: ValueKey('report-code-${item.id}'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text('Sesión ${item.testSessionId} · Registro del $dateLabel'),
          const SizedBox(height: 4),
          Text(
            StudentReportsHistorySection.sessionDownloadNote,
            key: ValueKey('reports-history-session-note-${item.id}'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DownloadVocationalPdfButton(
                sessionId: item.testSessionId,
                saver: saver,
                idleLabel: 'Descargar PDF vigente',
                buttonKey: ValueKey(
                  'download-pdf-report-${item.id}-session-${item.testSessionId}',
                ),
              ),
              if (counselorReviewEnabled)
                OutlinedButton.icon(
                  key: ValueKey(
                    'counselor-review-session-${item.testSessionId}',
                  ),
                  onPressed: () => context.go(
                    RouteNames.counselorStudentSession(
                      studentId,
                      item.testSessionId,
                    ),
                  ),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Resultado y observaciones'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryNotice extends StatelessWidget {
  const _HistoryNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('reports-history-retry'),
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
