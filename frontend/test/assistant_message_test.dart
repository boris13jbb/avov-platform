import 'package:flutter_test/flutter_test.dart';

import 'package:avov_frontend/core/models/assistant_message.dart';

void main() {
  group('AssistantReply', () {
    test('fromJson parsea respuesta del asistente', () {
      final reply = AssistantReply.fromJson({
        'answer': 'Tu perfil es Investigador-Artístico.',
        'source': 'deepseek',
        'ethical_disclaimer': 'Esta orientación no sustituye asesoría profesional.',
      });

      expect(reply.answer, contains('Investigador'));
      expect(reply.source, 'deepseek');
      expect(reply.sourceLabel, 'IA DeepSeek');
      expect(reply.ethicalDisclaimer, isNotEmpty);
    });

    test('sourceLabel usa fallback para fuentes desconocidas', () {
      final reply = AssistantReply.fromJson({
        'answer': 'Respuesta local',
        'source': 'fallback',
        'ethical_disclaimer': '',
      });

      expect(reply.sourceLabel, 'Modo orientativo');
    });
  });
}
