import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/app_navigation.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/student_scaffold.dart';
import '../../../vocational/domain/vocational_test.dart';
import '../../../vocational/presentation/providers/vocational_provider.dart';
import '../widgets/student_test_launcher.dart';
import '../widgets/vocational_history_load_more.dart';

/// Resultados ya calculados por el servidor. No inventa puntajes.
class StudentResultsScreen extends ConsumerWidget {
  const StudentResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(vocationalHistoryProvider);
    return StudentScaffold(
      title: 'Resultados',
      section: StudentSection.results,
      body: SafeArea(
        child: history.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Message(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () =>
                ref.read(vocationalHistoryProvider.notifier).refresh(),
          ),
          data: (state) {
            final completed =
                state.items.where((session) => session.isCompleted).toList();
            final openCount =
                state.items.where((session) => session.isOpen).length;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (completed.isEmpty && !state.hasMore)
                  const Text(
                    'No tienes resultados de evaluaciones completadas.',
                  ),
                if (completed.isEmpty && state.hasMore)
                  const Text(
                    'Aún no hay resultados en las evaluaciones cargadas. '
                    'Puedes cargar más páginas del historial.',
                  ),
                for (final session in completed)
                  _CompletedSession(session: session),
                VocationalHistoryLoadMore(history: state),
                if (completed.isEmpty) ...[
                  const SizedBox(height: 16),
                  StudentTestLauncher(openCount: openCount),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CompletedSession extends StatelessWidget {
  const _CompletedSession({required this.session});

  final VocationalSession session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_completedTitle(session)),
          OutlinedButton(
            onPressed: () => AppNavigation.open(
              context,
              RouteNames.studentTestResult(session.id),
            ),
            child: const Text('Ver resultado'),
          ),
        ],
      ),
    );
  }

  static String _completedTitle(VocationalSession session) {
    final when = formatVocationalStartedAt(session.startedAt);
    if (when == null) {
      return 'Evaluación Completada';
    }
    return 'Evaluación Completada · $when';
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
