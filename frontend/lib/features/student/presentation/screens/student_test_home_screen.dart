import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../shared/widgets/student_scaffold.dart';
import '../../../vocational/presentation/providers/vocational_provider.dart';
import '../widgets/open_vocational_session_tile.dart';
import '../widgets/student_test_launcher.dart';
import '../widgets/vocational_history_load_more.dart';

/// Lista las evaluaciones abiertas sin crear una sesión al cargar.
class StudentTestHomeScreen extends ConsumerWidget {
  const StudentTestHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(vocationalHistoryProvider);
    return StudentScaffold(
      title: 'Test vocacional',
      section: StudentSection.test,
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
            final open =
                state.items.where((session) => session.isOpen).toList();
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Evaluaciones en curso',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (open.isEmpty)
                  const Text('No tienes una evaluación en curso.')
                else ...[
                  if (open.length > 1) const MultipleOpenSessionsNotice(),
                  for (var i = 0; i < open.length; i++)
                    OpenVocationalSessionTile(
                      session: open[i],
                      continueKey: ValueKey('continue-open-${open[i].id}'),
                    ),
                ],
                VocationalHistoryLoadMore(history: state),
                const SizedBox(height: 8),
                StudentTestLauncher(openCount: open.length),
              ],
            );
          },
        ),
      ),
    );
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
