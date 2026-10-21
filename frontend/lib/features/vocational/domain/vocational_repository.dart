import 'vocational_test.dart';

/// Contrato de `/tests`.
///
/// El historial solo incluye las sesiones del estudiante autenticado.
/// La escala de respuesta es 1 a 5.
/// Las recomendaciones de carreras usan `/recommendations` (Fase 14 / S-21).
abstract class VocationalRepository {
  Future<VocationalSessionPage> listSessions({int page = 1, int pageSize = 20});

  Future<VocationalSession> start();

  Future<VocationalQuestionnaire> questions(int sessionId);

  Future<void> saveAnswer({
    required int sessionId,
    required int questionId,
    required int answerValue,
  });

  Future<VocationalResult> finish(int sessionId);

  Future<VocationalResult> result(int sessionId);
}
