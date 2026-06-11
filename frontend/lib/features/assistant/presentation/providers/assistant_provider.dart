import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/assistant_message.dart';
import '../../../../core/providers/providers.dart';
import '../../data/datasources/assistant_remote_datasource.dart';
import '../../data/repositories/assistant_repository.dart';

final assistantRemoteDatasourceProvider =
    Provider<AssistantRemoteDatasource>((ref) {
  return AssistantRemoteDatasource(ref.watch(dioClientProvider).dio);
});

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepository(
    remoteDatasource: ref.watch(assistantRemoteDatasourceProvider),
  );
});

class AssistantChatState {
  const AssistantChatState({
    required this.messages,
    required this.isLoading,
    this.errorMessage,
    this.testSessionId,
    this.ethicalDisclaimer,
    this.lastSource,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final int? testSessionId;
  final String? ethicalDisclaimer;
  final String? lastSource;

  bool get usedFallback => lastSource != null && lastSource != 'deepseek';

  factory AssistantChatState.initial({int? testSessionId}) {
    return AssistantChatState(
      messages: [
        ChatMessage(
          id: 'welcome',
          content:
              'Hola, soy tu asistente de orientación vocacional. Puedo ayudarte '
              'a entender tu perfil RIASEC, tus carreras recomendadas o resolver '
              'dudas sobre tu proceso vocacional.',
          isFromUser: false,
          createdAt: DateTime.now(),
        ),
      ],
      isLoading: false,
      testSessionId: testSessionId,
    );
  }

  AssistantChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    int? testSessionId,
    String? ethicalDisclaimer,
    String? lastSource,
  }) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      testSessionId: testSessionId ?? this.testSessionId,
      ethicalDisclaimer: ethicalDisclaimer ?? this.ethicalDisclaimer,
      lastSource: lastSource ?? this.lastSource,
    );
  }
}

final assistantChatProvider =
    StateNotifierProvider.family<AssistantChatController, AssistantChatState, int?>(
  (ref, testSessionId) {
    return AssistantChatController(
      ref.watch(assistantRepositoryProvider),
      testSessionId: testSessionId,
    );
  },
);

class AssistantChatController extends StateNotifier<AssistantChatState> {
  AssistantChatController(
    this._repository, {
    int? testSessionId,
  }) : super(AssistantChatState.initial(testSessionId: testSessionId));

  final AssistantRepository _repository;

  Future<void> sendMessage(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || state.isLoading) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      isFromUser: true,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    try {
      final reply = await _repository.sendChat(
        message: message,
        testSessionId: state.testSessionId,
      );
      _appendAssistantReply(reply);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error is AppException
            ? error.message
            : 'No se pudo enviar el mensaje',
      );
    }
  }

  Future<void> explainProfile() async {
    if (state.isLoading) return;

    const prompt = 'Explica mi perfil RIASEC';
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: prompt,
      isFromUser: true,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    try {
      final reply = await _repository.explainProfile(
        testSessionId: state.testSessionId,
      );
      _appendAssistantReply(reply);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error is AppException
            ? error.message
            : 'No se pudo explicar el perfil',
      );
    }
  }

  Future<void> explainCareers(List<int> careerIds) async {
    if (state.isLoading || careerIds.isEmpty) return;

    const prompt = 'Explica mis carreras recomendadas';
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: prompt,
      isFromUser: true,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    try {
      final reply = await _repository.explainCareers(
        careerIds: careerIds,
        testSessionId: state.testSessionId,
      );
      _appendAssistantReply(reply);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error is AppException
            ? error.message
            : 'No se pudieron explicar las carreras',
      );
    }
  }

  void _appendAssistantReply(AssistantReply reply) {
    final assistantMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}-assistant',
      content: reply.answer,
      isFromUser: false,
      source: reply.source,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, assistantMessage],
      isLoading: false,
      ethicalDisclaimer: reply.ethicalDisclaimer,
      lastSource: reply.source,
      clearError: true,
    );
  }

  void addHintMessage(String content) {
    final hint = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}-hint',
      content: content,
      isFromUser: false,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, hint],
      clearError: true,
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }
}
