class AssistantReply {
  const AssistantReply({
    required this.answer,
    required this.source,
    required this.ethicalDisclaimer,
  });

  final String answer;
  final String source;
  final String ethicalDisclaimer;

  String get sourceLabel {
    switch (source) {
      case 'deepseek':
        return 'DeepSeek';
      case 'fallback':
        return 'Respuesta básica (fallback)';
      default:
        return source;
    }
  }

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    return AssistantReply(
      answer: json['answer'] as String? ?? '',
      source: json['source'] as String? ?? 'fallback',
      ethicalDisclaimer: json['ethical_disclaimer'] as String? ?? '',
    );
  }
}
