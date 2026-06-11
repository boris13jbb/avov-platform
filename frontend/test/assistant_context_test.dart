import 'package:flutter_test/flutter_test.dart';

import 'package:avov_frontend/features/assistant/domain/assistant_context.dart';

void main() {
  group('AssistantContext', () {
    test('detecta test completado y recomendaciones', () {
      final context = AssistantContext.fromDashboard({
        'student_id': 81,
        'recommendations_count': 3,
        'test': {
          'status': 'COMPLETED',
          'latest_completed_session_id': 17,
        },
      });

      expect(context.hasCompletedTest, isTrue);
      expect(context.hasRecommendations, isTrue);
      expect(context.profileBlockReason, isNull);
      expect(context.careersBlockReason, isNull);
    });

    test('indica bloqueo cuando falta test', () {
      final context = AssistantContext.fromDashboard({
        'student_id': 81,
        'recommendations_count': 0,
        'test': {
          'status': 'IN_PROGRESS',
          'open_session': {'id': 20},
        },
      });

      expect(context.hasCompletedTest, isFalse);
      expect(context.hasOpenSession, isTrue);
      expect(context.profileBlockReason, contains('test en progreso'));
    });

    test('indica bloqueo cuando faltan recomendaciones', () {
      final context = AssistantContext.fromDashboard({
        'student_id': 81,
        'recommendations_count': 0,
        'test': {
          'status': 'COMPLETED',
          'latest_completed_session_id': 17,
        },
      });

      expect(context.hasCompletedTest, isTrue);
      expect(context.hasRecommendations, isFalse);
      expect(context.careersBlockReason, contains('recomendaciones'));
    });
  });
}
