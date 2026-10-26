import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/student_scaffold.dart';
import '../../../vocational/presentation/providers/recommendation_provider.dart';
import '../../domain/assistant_message.dart';
import '../providers/assistant_provider.dart';

class AssistantChatScreen extends ConsumerStatefulWidget {
  const AssistantChatScreen({super.key, this.testSessionId});

  final int? testSessionId;

  @override
  ConsumerState<AssistantChatScreen> createState() =>
      _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _messages = <_ChatEntry>[];
  bool _busy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendUserMessage(String text) async {
    setState(() {
      _busy = true;
      _errorMessage = null;
      _messages.add(_ChatEntry.user(text));
    });
    try {
      final reply = await ref.read(assistantRepositoryProvider).chat(
            message: text,
            testSessionId: widget.testSessionId,
          );
      if (!mounted) {
        return;
      }
      setState(() => _messages.add(_ChatEntry.assistant(reply)));
    } on AppException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = FailureMapper.unexpectedMessage);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _explainProfile() async {
    await _runAssistantAction(() {
      return ref.read(assistantRepositoryProvider).explainProfile(
            testSessionId: widget.testSessionId,
          );
    }, userLabel: 'Explicar mi perfil RIASEC');
  }

  Future<void> _explainCareers() async {
    final sessionId = widget.testSessionId;
    if (sessionId == null) {
      setState(
        () => _errorMessage =
            'Selecciona una evaluación completada para explicar carreras recomendadas.',
      );
      return;
    }
    try {
      final page =
          await ref.read(sessionRecommendationsProvider(sessionId).future);
      final ids = page.items.map((item) => item.careerId).take(10).toList();
      if (ids.isEmpty) {
        setState(
          () => _errorMessage =
              'No hay carreras recomendadas persistidas para esta sesión.',
        );
        return;
      }
      await _runAssistantAction(
        () => ref.read(assistantRepositoryProvider).explainCareers(
              careerIds: ids,
              testSessionId: sessionId,
            ),
        userLabel: 'Explicar carreras recomendadas',
      );
    } on AppException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = FailureMapper.unexpectedMessage);
    }
  }

  Future<void> _runAssistantAction(
    Future<AssistantReply> Function() action, {
    required String userLabel,
  }) async {
    setState(() {
      _busy = true;
      _errorMessage = null;
      _messages.add(_ChatEntry.user(userLabel));
    });
    try {
      final reply = await action();
      if (!mounted) {
        return;
      }
      setState(() => _messages.add(_ChatEntry.assistant(reply)));
    } on AppException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = FailureMapper.unexpectedMessage);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final text = _controller.text.trim();
    _controller.clear();
    await _sendUserMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return StudentScaffold(
      title: 'Asistente vocacional',
      section: StudentSection.assistant,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.testSessionId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Contexto: evaluación ${widget.testSessionId}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        key: const Key('assistant-explain-profile'),
                        onPressed: _busy ? null : _explainProfile,
                        child: const Text('Explicar perfil RIASEC'),
                      ),
                      OutlinedButton(
                        key: const Key('assistant-explain-careers'),
                        onPressed: _busy ? null : _explainCareers,
                        child: const Text('Explicar carreras'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_messages.isEmpty)
                    Text(
                      'Escribe una pregunta sobre orientación vocacional. '
                      'Las respuestas son orientativas.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  for (final entry in _messages) _ChatBubble(entry: entry),
                ],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ErrorBanner(message: _errorMessage!),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('assistant-message'),
                        controller: _controller,
                        enabled: !_busy,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          labelText: 'Tu mensaje',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            AppValidators.required(value, fieldName: 'mensaje'),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('assistant-send'),
                      onPressed: _busy ? null : _submit,
                      icon: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatEntry {
  const _ChatEntry._({required this.isUser, required this.text, this.reply});

  factory _ChatEntry.user(String text) =>
      _ChatEntry._(isUser: true, text: text);

  factory _ChatEntry.assistant(AssistantReply reply) => _ChatEntry._(
        isUser: false,
        text: reply.answer,
        reply: reply,
      );

  final bool isUser;
  final String text;
  final AssistantReply? reply;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.entry});

  final _ChatEntry entry;

  @override
  Widget build(BuildContext context) {
    final alignment =
        entry.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = entry.isUser
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.text),
            if (entry.reply != null) ...[
              const SizedBox(height: 8),
              Text(
                entry.reply!.ethicalDisclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Fuente: ${entry.reply!.sourceLabel}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
