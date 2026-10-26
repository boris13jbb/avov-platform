import 'package:avov_frontend/features/assistant/domain/assistant_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AssistantReply parsea fuente y disclaimer', () {
    final reply = AssistantReply.fromJson(<String, dynamic>{
      'answer': 'Tu perfil Social es destacado.',
      'source': 'deepseek',
      'ethical_disclaimer': 'Resultado orientativo.',
    });

    expect(reply.answer, contains('Social'));
    expect(reply.sourceLabel, 'DeepSeek');
    expect(reply.ethicalDisclaimer, 'Resultado orientativo.');
  });
}
