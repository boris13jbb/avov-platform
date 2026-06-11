import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/ethical_disclaimer_banner.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../../../results/presentation/providers/results_provider.dart';
import '../../domain/assistant_context.dart';
import '../providers/assistant_provider.dart';
import '../widgets/assistant_context_banner.dart';
import '../widgets/chat_bubble.dart';

class AssistantChatScreen extends ConsumerStatefulWidget {
  const AssistantChatScreen({super.key});

  @override
  ConsumerState<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _goToTest(AssistantContext assistantContext) {
    if (assistantContext.hasOpenSession && assistantContext.openSessionId != null) {
      context.go(RouteNames.studentTestSession(assistantContext.openSessionId!));
      return;
    }
    context.push(RouteNames.studentTestInstructions);
  }

  Future<void> _generateRecommendations(AssistantContext assistantContext) async {
    final sessionId = assistantContext.completedSessionId;
    if (sessionId == null) return;

    final result = await ref
        .read(resultsMutationProvider.notifier)
        .generateRecommendations(testSessionId: sessionId);

    if (!mounted) return;

    if (result != null) {
      ref.invalidate(studentDashboardProvider);
      final studentId = assistantContext.studentId;
      if (studentId != null) {
        ref.invalidate(studentRecommendationsProvider(studentId));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se generaron ${result.items.length} recomendaciones',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron generar las recomendaciones'),
        ),
      );
    }
  }

  Future<List<int>> _resolveCareerIds(AssistantContext assistantContext) async {
    final studentId = assistantContext.studentId;
    if (studentId == null) return [];

    final recommendations = await ref.read(
      studentRecommendationsProvider(studentId).future,
    );

    return recommendations.items.map((item) => item.careerId).take(5).toList();
  }

  Future<void> _handleExplainProfile({
    required AssistantContext assistantContext,
    required AssistantChatController chatNotifier,
  }) async {
    if (!assistantContext.canExplainProfile) {
      chatNotifier.addHintMessage(
        assistantContext.profileBlockReason ??
            'Completa el test vocacional para usar esta acción.',
      );
      return;
    }
    await chatNotifier.explainProfile();
  }

  Future<void> _handleExplainCareers({
    required AssistantContext assistantContext,
    required AssistantChatController chatNotifier,
  }) async {
    if (!assistantContext.hasCompletedTest) {
      chatNotifier.addHintMessage(
        assistantContext.profileBlockReason ??
            'Completa el test vocacional para usar esta acción.',
      );
      return;
    }

    var contextData = assistantContext;
    if (!contextData.hasRecommendations) {
      await _generateRecommendations(contextData);
      if (!mounted) return;

      final refreshedDashboard = await ref.read(studentDashboardProvider.future);
      contextData = AssistantContext.fromDashboard(refreshedDashboard);
      if (!contextData.hasRecommendations) {
        chatNotifier.addHintMessage(
          'No fue posible generar recomendaciones. Intenta de nuevo desde el panel '
          'o verifica tu conexión.',
        );
        return;
      }
    }

    try {
      final careerIds = await _resolveCareerIds(contextData);
      if (careerIds.isEmpty) {
        chatNotifier.addHintMessage(
          'No encontré carreras recomendadas para explicar. Genera tus '
          'recomendaciones e inténtalo nuevamente.',
        );
        return;
      }
      await chatNotifier.explainCareers(careerIds);
    } catch (_) {
      chatNotifier.addHintMessage(
        'No se pudieron cargar las carreras recomendadas. Verifica tu conexión '
        'e inténtalo de nuevo.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(studentDashboardProvider);
    final assistantContext =
        AssistantContext.fromDashboard(dashboardAsync.valueOrNull);
    final sessionId = assistantContext.completedSessionId;

    final chatState = ref.watch(assistantChatProvider(sessionId));
    final chatNotifier = ref.read(assistantChatProvider(sessionId).notifier);
    final isGeneratingRecommendations = ref.watch(resultsMutationProvider).isLoading;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isBusy = chatState.isLoading || isGeneratingRecommendations;

    ref.listen<AssistantChatState>(assistantChatProvider(sessionId), (_, __) {
      _scrollToBottom();
    });

    return DashboardShell(
      title: 'Asistente virtual',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: isBusy ? null : () => context.pop(),
      ),
      body: Column(
        children: [
          if (dashboardAsync.isLoading)
            const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                AssistantContextBanner(
                  assistantContext: assistantContext,
                  isGeneratingRecommendations: isGeneratingRecommendations,
                  onGoToTest: assistantContext.hasCompletedTest
                      ? null
                      : () => _goToTest(assistantContext),
                  onGenerateRecommendations: assistantContext.hasCompletedTest &&
                          !assistantContext.hasRecommendations
                      ? () => _generateRecommendations(assistantContext)
                      : null,
                ),
                if (chatState.usedFallback) const AssistantFallbackBanner(),
                _QuickActions(
                  enabled: !isBusy,
                  onExplainProfile: () => _handleExplainProfile(
                    assistantContext: assistantContext,
                    chatNotifier: chatNotifier,
                  ),
                  onExplainCareers: () => _handleExplainCareers(
                    assistantContext: assistantContext,
                    chatNotifier: chatNotifier,
                  ),
                ),
              ],
            ),
          ),
          if (chatState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ErrorBanner(
                message: chatState.errorMessage!,
                onDismiss: chatNotifier.clearError,
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (chatState.isLoading && index == chatState.messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('El asistente está pensando...'),
                        ],
                      ),
                    ),
                  );
                }
                return ChatBubble(message: chatState.messages[index]);
              },
            ),
          ),
          if (chatState.ethicalDisclaimer != null &&
              chatState.ethicalDisclaimer!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: EthicalDisclaimerBanner(
                message: chatState.ethicalDisclaimer,
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomInset),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !isBusy,
                      maxLength: 1000,
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: assistantContext.hasCompletedTest
                            ? 'Escribe tu pregunta...'
                            : 'Pregunta general (completa el test para respuestas personalizadas)',
                        counterText: '',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(chatNotifier),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: isBusy ? null : () => _send(chatNotifier),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(AssistantChatController notifier) async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    _messageController.clear();
    await notifier.sendMessage(text);
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.enabled,
    required this.onExplainProfile,
    required this.onExplainCareers,
  });

  final bool enabled;
  final VoidCallback onExplainProfile;
  final VoidCallback onExplainCareers;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.psychology_outlined, size: 18),
            label: const Text('Explicar mi perfil'),
            onPressed: enabled ? onExplainProfile : null,
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.school_outlined, size: 18),
            label: const Text('Explicar carreras'),
            onPressed: enabled ? onExplainCareers : null,
          ),
        ],
      ),
    );
  }
}
