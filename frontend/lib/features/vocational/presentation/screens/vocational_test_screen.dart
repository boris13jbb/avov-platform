import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../domain/vocational_test.dart';
import '../providers/vocational_provider.dart';

class VocationalTestScreen extends ConsumerStatefulWidget {
  const VocationalTestScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<VocationalTestScreen> createState() => _VocationalTestScreenState();
}

class _VocationalTestScreenState extends ConsumerState<VocationalTestScreen> {
  List<VocationalQuestion>? _questions;
  int _index = 0;
  int? _selected;
  bool _busy = false;
  String? _error;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final questionnaire = ref.watch(vocationalQuestionsProvider(widget.sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Test vocacional')),
      body: SafeArea(
        child: questionnaire.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            final message = error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage;
            final completed = message == 'El test ya fue completado';
            return _Notice(
              message: message,
              actionLabel: completed ? 'Ver resultado' : 'Reintentar',
              onPressed: completed
                  ? () => context.go(RouteNames.studentTestResult(widget.sessionId))
                  : () => ref.invalidate(vocationalQuestionsProvider(widget.sessionId)),
            );
          },
          data: (data) {
            _questions ??= [...data.questions];
            final questions = _questions!;
            if (questions.isEmpty) {
              return const _Notice(
                message: 'Esta evaluación no tiene preguntas activas.',
                actionLabel: 'Volver',
                onPressed: null,
              );
            }
            final question = questions[_index.clamp(0, questions.length - 1)];
            final saved = questions.where((item) => item.answerValue != null).length;
            final currentSaved = question.answerValue;
            final selection = _selected ?? currentSaved;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Respuestas guardadas: $saved de ${questions.length}'),
                const SizedBox(height: 8),
                Text('Pregunta ${_index + 1} de ${questions.length}'),
                const SizedBox(height: 8),
                Text('${question.categoryName} (${question.categoryCode})'),
                const SizedBox(height: 16),
                Text(question.text, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                RadioGroup<int>(
                  groupValue: selection,
                  onChanged: (value) {
                    if (_busy || value == null) {
                      return;
                    }
                    setState(() => _selected = value);
                  },
                  child: Column(
                    children: [
                      for (final entry in answerScaleLabels.entries)
                        RadioListTile<int>(
                          value: entry.key,
                          enabled: !_busy,
                          title: Text(entry.value),
                        ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: _busy || _index == 0
                          ? null
                          : () => setState(() {
                                _index -= 1;
                                _selected = null;
                                _error = null;
                              }),
                      child: const Text('Anterior'),
                    ),
                    FilledButton(
                      onPressed: _busy || selection == null || selection == currentSaved
                          ? null
                          : () => _save(question.id, selection),
                      child: const Text('Guardar respuesta'),
                    ),
                    if (_index < questions.length - 1)
                      OutlinedButton(
                        onPressed: _busy || question.answerValue == null
                            ? null
                            : () => setState(() {
                                  _index += 1;
                                  _selected = null;
                                  _error = null;
                                }),
                        child: const Text('Siguiente'),
                      ),
                    if (saved == questions.length)
                      FilledButton(
                        onPressed: _busy || _completed ? null : _finish,
                        child: const Text('Finalizar test'),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _save(int questionId, int value) async {
    if (_busy || value < 1 || value > 5) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(vocationalRepositoryProvider).saveAnswer(
            sessionId: widget.sessionId,
            questionId: questionId,
            answerValue: value,
          );
      final questions = _questions;
      if (questions == null) {
        return;
      }
      final position = questions.indexWhere((item) => item.id == questionId);
      if (position >= 0) {
        questions[position] = questions[position].copyWithAnswer(value);
      }
      _selected = null;
    } on AppException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = FailureMapper.unexpectedMessage;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _finish() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(vocationalRepositoryProvider).finish(widget.sessionId);
      _completed = true;
      if (!mounted) {
        return;
      }
      context.go(RouteNames.studentTestResult(widget.sessionId));
    } on AppException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = FailureMapper.unexpectedMessage;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback? onPressed;

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
            if (onPressed != null)
              FilledButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
