import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/app_navigation.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/student_scaffold.dart';
import '../../../students/domain/managed_student.dart';
import '../../../students/presentation/providers/students_provider.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../../../vocational/domain/vocational_test.dart';
import '../../../vocational/presentation/providers/vocational_provider.dart';
import '../widgets/open_vocational_session_tile.dart';
import '../widgets/student_test_launcher.dart';
import '../widgets/vocational_history_load_more.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentOperatorProvider);
    return StudentScaffold(
      title: 'Panel del estudiante',
      section: StudentSection.home,
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Notice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(currentOperatorProvider),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                '${data.firstName} ${data.lastName}'.trim(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(data.email),
              const SizedBox(height: 16),
              Text(
                'Ficha académica',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _RecordSection(
                record: ref.watch(ownStudentProvider),
                onRetry: () => ref.invalidate(ownStudentProvider),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => AppNavigation.open(
                    context,
                    RouteNames.studentProfile,
                  ),
                  child: const Text('Ver mi ficha'),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Evaluaciones vocacionales',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _HistorySection(
                history: ref.watch(vocationalHistoryProvider),
                onRetry: () =>
                    ref.read(vocationalHistoryProvider.notifier).refresh(),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: const Key('student-open-assistant'),
                  onPressed: () => AppNavigation.open(
                    context,
                    RouteNames.studentAssistant,
                  ),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Abrir asistente vocacional'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Las recomendaciones de carreras se generan en el resultado '
                'de cada evaluación completada (menú Resultados). '
                'El asistente con IA también está en el menú lateral.',
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordSection extends StatelessWidget {
  const _RecordSection({required this.record, required this.onRetry});

  final AsyncValue<ManagedStudent> record;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return record.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => _Notice(
        message: error is AppException
            ? error.message
            : FailureMapper.unexpectedMessage,
        onRetry: onRetry,
      ),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Identificación: ${data.identification}'),
          Text('Curso: ${data.grade}'),
          if (data.parallel != null && data.parallel!.isNotEmpty)
            Text('Paralelo: ${data.parallel}'),
          Text('Fecha de nacimiento: ${data.birthDate}'),
          Text('Género: ${data.genderLabel}'),
          Text(
            'Institución: identificador ${data.institutionId}. '
            'El nombre no está incluido en la ficha.',
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history, required this.onRetry});

  final AsyncValue<VocationalHistoryState> history;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return history.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => _Notice(
        message: error is AppException
            ? error.message
            : FailureMapper.unexpectedMessage,
        onRetry: onRetry,
      ),
      data: (data) {
        final open = data.items.where((session) => session.isOpen).toList();
        if (data.items.isEmpty && !data.hasMore) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No tienes evaluaciones registradas.'),
              SizedBox(height: 12),
              StudentTestLauncher(openCount: 0),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (open.length > 1) const MultipleOpenSessionsNotice(),
            for (final session in data.items) _SessionTile(session: session),
            VocationalHistoryLoadMore(history: data),
            const SizedBox(height: 8),
            StudentTestLauncher(openCount: open.length),
          ],
        );
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final VocationalSession session;

  @override
  Widget build(BuildContext context) {
    if (session.isOpen) {
      return OpenVocationalSessionTile(
        session: session,
        continueKey: ValueKey('dash-continue-${session.id}'),
      );
    }
    final when = formatVocationalStartedAt(session.startedAt);
    final title = when == null
        ? 'Evaluación ${session.statusLabel}'
        : 'Evaluación ${session.statusLabel} · $when';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Text(
            'Respuestas guardadas: ${session.answeredCount} de ${session.totalQuestions}',
          ),
          if (session.isCompleted)
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
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.onRetry});

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
