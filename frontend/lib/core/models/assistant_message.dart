class AssistantReply {
  const AssistantReply({
    required this.answer,
    required this.source,
    required this.ethicalDisclaimer,
  });

  final String answer;
  final String source;
  final String ethicalDisclaimer;

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    return AssistantReply(
      answer: json['answer'] as String? ?? '',
      source: json['source'] as String? ?? 'fallback',
      ethicalDisclaimer: json['ethical_disclaimer'] as String? ?? '',
    );
  }

  bool get isAiSource => source == 'deepseek';

  String get sourceLabel {
    switch (source) {
      case 'deepseek':
        return 'IA DeepSeek';
      default:
        return 'Modo orientativo';
    }
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.isFromUser,
    this.source,
    required this.createdAt,
  });

  final String id;
  final String content;
  final bool isFromUser;
  final String? source;
  final DateTime createdAt;

  bool get isAiSource => source == 'deepseek';

  String? get sourceLabel {
    if (source == null) return null;
    switch (source) {
      case 'deepseek':
        return 'IA DeepSeek';
      default:
        return 'Modo orientativo';
    }
  }
}
