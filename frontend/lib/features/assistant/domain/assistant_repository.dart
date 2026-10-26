import 'assistant_message.dart';

abstract class AssistantRepository {
  Future<AssistantReply> chat({
    required String message,
    int? testSessionId,
  });

  Future<AssistantReply> explainProfile({int? testSessionId});

  Future<AssistantReply> explainCareers({
    required List<int> careerIds,
    int? testSessionId,
  });
}
