import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/test_session.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../providers/test_provider.dart';
import '../widgets/scale_answer_selector.dart';

class TestSessionScreen extends ConsumerStatefulWidget {
  const TestSessionScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<TestSessionScreen> createState() => _TestSessionScreenState();
}

class _TestSessionScreenState extends ConsumerState<TestSessionScreen> {
  int _currentIndex = 0;
  bool _indexInitialized = false;
  bool _isSaving = false;
  String? _errorMessage;

  int _initialIndex(SessionQuestions data) {
    final firstUnanswered = data.questions.indexWhere(
      (question) => question.answerValue == null,
    );
    if (firstUnanswered >= 0) return firstUnanswered;
    return 0;
  }

  Future<void> _saveAnswer(TestQuestion question, int value) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final success = await ref.read(testMutationProvider.notifier).saveAnswer(
          sessionId: widget.sessionId,
          questionId: question.id,
          answerValue: value,
        );

    if (!mounted) return;

    if (success) {
      ref.invalidate(sessionQuestionsProvider(widget.sessionId));
      final data = await ref.read(
        sessionQuestionsProvider(widget.sessionId).future,
      );
      if (!mounted) return;

      final updatedQuestions = data.questions;
      final allAnswered = updatedQuestions.every((q) => q.answerValue != null);

      if (allAnswered) {
        context.go(RouteNames.studentTestFinish(widget.sessionId));
        return;
      }

      final nextUnanswered = updatedQuestions.indexWhere(
        (q) => q.answerValue == null,
        _currentIndex,
      );
      setState(() {
        _isSaving = false;
        if (nextUnanswered >= 0) {
          _currentIndex = nextUnanswered;
        } else if (_currentIndex < updatedQuestions.length - 1) {
          _currentIndex++;
        }
      });
    } else {
      final error = ref.read(testMutationProvider).error;
      setState(() {
        _isSaving = false;
        _errorMessage = error is AppException
            ? error.message
            : 'No se pudo guardar la respuesta';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(sessionQuestionsProvider(widget.sessionId));
    final mutationLoading = ref.watch(testMutationProvider).isLoading;
    final isBusy = _isSaving || mutationLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test vocacional'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: isBusy
              ? null
              : () => context.go(RouteNames.studentDashboard),
        ),
      ),
      body: SafeArea(
        child: questionsAsync.when(
          data: (data) {
            if (!_indexInitialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _currentIndex = _initialIndex(data);
                    _indexInitialized = true;
                  });
                }
              });
            }

            final question = data.questions[_currentIndex];
            final session = data.session;
            final progress = session.progressPercent / 100;

            return Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pregunta ${question.orderNumber} de ${session.totalQuestions}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${session.answeredCount}/${session.totalQuestions}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(
                              '${question.categoryCode} · ${question.categoryName}',
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_errorMessage != null) ...[
                              ErrorBanner(
                                message: _errorMessage!,
                                onDismiss: () =>
                                    setState(() => _errorMessage = null),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              question.text,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 24),
                            ScaleAnswerSelector(
                              selectedValue: question.answerValue,
                              enabled: !isBusy,
                              onSelected: (value) => _saveAnswer(question, value),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        8 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isBusy || _currentIndex == 0
                                  ? null
                                  : () => setState(() => _currentIndex--),
                              icon: const Icon(Icons.chevron_left),
                              label: const Text('Anterior'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: isBusy ||
                                      _currentIndex >= data.questions.length - 1
                                  ? null
                                  : () => setState(() => _currentIndex++),
                              icon: const Icon(Icons.chevron_right),
                              label: const Text('Siguiente'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (session.isComplete)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isBusy
                                ? null
                                : () => context.go(
                                      RouteNames.studentTestFinish(
                                        widget.sessionId,
                                      ),
                                    ),
                            child: const Text('Finalizar test'),
                          ),
                        ),
                      ),
                  ],
                ),
                if (isBusy) const LoadingOverlay(message: 'Guardando respuesta...'),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No se pudieron cargar las preguntas'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(
                    sessionQuestionsProvider(widget.sessionId),
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
