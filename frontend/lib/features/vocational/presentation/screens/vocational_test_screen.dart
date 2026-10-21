import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/student_scaffold.dart';
import '../../domain/vocational_test.dart';
import '../providers/vocational_provider.dart';
import '../vocational_test_leave_guard.dart';

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
  bool _promptOpen = false;

  @override
  void initState() {
    super.initState();
    VocationalTestLeaveGuard.register(widget.sessionId, _allowLeave);
  }

  @override
  void dispose() {
    VocationalTestLeaveGuard.unregister(widget.sessionId);
    super.dispose();
  }

  bool get _hasUnsavedSelection {
    final questions = _questions;
    if (questions == null || questions.isEmpty) {
      return false;
    }
    final question = questions[_index.clamp(0, questions.length - 1)];
    return _selected != null && _selected != question.answerValue;
  }

  @override
  Widget build(BuildContext context) {
    final questionnaire = ref.watch(vocationalQuestionsProvider(widget.sessionId));
    return PopScope(
      canPop: !_hasUnsavedSelection && !_busy,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _busy) {
          return;
        }
        final leave = await _confirmLeaveOrStay();
        if (leave && mounted && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: StudentScaffold(
        title: 'Test vocacional',
        section: StudentSection.test,
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
                    ? () => context.go(
                          RouteNames.studentTestResult(widget.sessionId),
                        )
                    : () => ref.invalidate(
                          vocationalQuestionsProvider(widget.sessionId),
                        ),
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
              final saved =
                  questions.where((item) => item.answerValue != null).length;
              final currentSaved = question.answerValue;
              final selection = _selected ?? currentSaved;
              final dirty = _selected != null && _selected != currentSaved;
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text('Respuestas guardadas: $saved de ${questions.length}'),
                  const SizedBox(height: 8),
                  Text('Pregunta ${_index + 1} de ${questions.length}'),
                  const SizedBox(height: 8),
                  Text('${question.categoryName} (${question.categoryCode})'),
                  const SizedBox(height: 16),
                  Text(
                    question.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  RadioGroup<int>(
                    groupValue: selection,
                    onChanged: (value) {
                      if (_busy || value == null) {
                        return;
                      }
                      setState(() {
                        _selected = value;
                        _error = null;
                      });
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
                  const SizedBox(height: 8),
                  Text(
                    dirty
                        ? 'Selección pendiente de guardar. '
                            'Pulsa «Guardar respuesta» para confirmarla en el servidor.'
                        : currentSaved == null
                            ? 'Aún no hay una respuesta confirmada por el servidor '
                                'para esta pregunta.'
                            : 'Respuesta confirmada por el servidor.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: dirty
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
                            : () => _moveTo(_index - 1),
                        child: const Text('Anterior'),
                      ),
                      FilledButton(
                        key: const Key('vocational-save-answer'),
                        onPressed: _busy ||
                                selection == null ||
                                selection == currentSaved
                            ? null
                            : () => _save(question.id, selection),
                        child: const Text('Guardar respuesta'),
                      ),
                      if (_index < questions.length - 1)
                        OutlinedButton(
                          onPressed: _busy ||
                                  (question.answerValue == null && !dirty)
                              ? null
                              : () => _moveTo(_index + 1),
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
      ),
    );
  }

  Future<bool> _allowLeave() async {
    if (_completed || !_hasUnsavedSelection) {
      return true;
    }
    if (_busy) {
      return false;
    }
    return _confirmLeaveOrStay();
  }

  Future<void> _moveTo(int nextIndex) async {
    if (_busy) {
      return;
    }
    if (!_hasUnsavedSelection) {
      setState(() {
        _index = nextIndex;
        _selected = null;
        _error = null;
      });
      return;
    }
    final action = await _askUnsavedAction();
    if (!mounted) {
      return;
    }
    switch (action) {
      case _UnsavedAction.cancel:
        return;
      case _UnsavedAction.discard:
        setState(() {
          _index = nextIndex;
          _selected = null;
          _error = null;
        });
        return;
      case _UnsavedAction.save:
        final questions = _questions;
        if (questions == null) {
          return;
        }
        final question = questions[_index.clamp(0, questions.length - 1)];
        final value = _selected;
        if (value == null) {
          return;
        }
        final ok = await _save(question.id, value);
        if (!mounted || !ok) {
          return;
        }
        setState(() {
          _index = nextIndex;
          _selected = null;
          _error = null;
        });
    }
  }

  Future<bool> _confirmLeaveOrStay() async {
    final action = await _askUnsavedAction();
    if (!mounted) {
      return false;
    }
    switch (action) {
      case _UnsavedAction.cancel:
        return false;
      case _UnsavedAction.discard:
        setState(() {
          _selected = null;
          _error = null;
        });
        return true;
      case _UnsavedAction.save:
        final questions = _questions;
        if (questions == null) {
          return false;
        }
        final question = questions[_index.clamp(0, questions.length - 1)];
        final value = _selected;
        if (value == null) {
          return false;
        }
        return _save(question.id, value);
    }
  }

  Future<_UnsavedAction> _askUnsavedAction() async {
    if (_promptOpen) {
      return _UnsavedAction.cancel;
    }
    _promptOpen = true;
    try {
      final result = await showDialog<_UnsavedAction>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Respuesta sin guardar'),
            content: const Text(
              'Tienes una selección que aún no se ha confirmado en el servidor. '
              'Si sales ahora, esa selección se perderá.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_UnsavedAction.cancel),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_UnsavedAction.discard),
                child: const Text('Descartar'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_UnsavedAction.save),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
      return result ?? _UnsavedAction.cancel;
    } finally {
      _promptOpen = false;
    }
  }

  /// Persiste en el servidor. Devuelve true solo si el servidor confirmó.
  Future<bool> _save(int questionId, int value) async {
    if (_busy || value < 1 || value > 5) {
      return false;
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
        return false;
      }
      final position = questions.indexWhere((item) => item.id == questionId);
      if (position >= 0) {
        questions[position] = questions[position].copyWithAnswer(value);
      }
      if (_selected == value) {
        _selected = null;
      }
      return true;
    } on AppException catch (error) {
      _error =
          '${error.message} No se confirmó el guardado; tu selección se conserva.';
      return false;
    } catch (_) {
      _error =
          '${FailureMapper.unexpectedMessage} No se confirmó el guardado; tu selección se conserva.';
      return false;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _finish() async {
    if (_busy || _completed) {
      return;
    }
    if (_hasUnsavedSelection) {
      final action = await _askUnsavedAction();
      if (!mounted) {
        return;
      }
      switch (action) {
        case _UnsavedAction.cancel:
          return;
        case _UnsavedAction.discard:
          setState(() {
            _selected = null;
            _error = null;
          });
          break;
        case _UnsavedAction.save:
          final questions = _questions;
          if (questions == null) {
            return;
          }
          final question = questions[_index.clamp(0, questions.length - 1)];
          final value = _selected;
          if (value == null) {
            return;
          }
          final ok = await _save(question.id, value);
          if (!mounted || !ok) {
            return;
          }
          break;
      }
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
      // Invalidar fuerza un build limpio desde la página 1 (sin mezclar loadMore).
      final historySynced = await _reloadHistoryFromFirstPage();
      if (!mounted) {
        return;
      }
      if (!historySynced) {
        final continueToResult = await _confirmHistorySyncFailure();
        if (!mounted) {
          return;
        }
        if (!continueToResult) {
          // Reintento solo del historial; no vuelve a llamar finish.
          final retried = await _reloadHistoryFromFirstPage();
          if (!mounted) {
            return;
          }
          if (!retried) {
            setState(() {
              _error =
                  'La evaluación ya está finalizada, pero el historial no se pudo actualizar. '
                  'Puedes ver el resultado y reintentar el historial más tarde.';
            });
          }
        }
      }
      if (!mounted) {
        return;
      }
      context.go(RouteNames.studentTestResult(widget.sessionId));
    } on AppException catch (error) {
      if (!_completed) {
        _error = error.message;
      }
    } catch (_) {
      if (!_completed) {
        _error = FailureMapper.unexpectedMessage;
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<bool> _reloadHistoryFromFirstPage() async {
    ref.invalidate(vocationalHistoryProvider);
    try {
      await ref.read(vocationalHistoryProvider.future);
      final value = ref.read(vocationalHistoryProvider);
      return value.hasValue && !value.hasError;
    } catch (_) {
      return false;
    }
  }

  /// true = ir al resultado; false = reintentar solo el historial.
  Future<bool> _confirmHistorySyncFailure() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Evaluación finalizada'),
          content: const Text(
            'El servidor confirmó el cierre de la evaluación, pero no se pudo '
            'actualizar el historial. Puedes reintentar la actualización o ver '
            'el resultado ahora.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Reintentar historial'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Ver resultado'),
            ),
          ],
        );
      },
    );
    return result ?? true;
  }
}

enum _UnsavedAction { save, discard, cancel }

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
