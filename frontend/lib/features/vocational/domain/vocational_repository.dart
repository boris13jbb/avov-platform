import 'vocational_test.dart';

/// Contrato de `/tests`.
///
/// No hay listado de sesiones ni de recomendaciones. El estudiante solo
/// puede operar la sesión cuyo identificador devolvió el backend y que
/// le pertenece. La escala de respuesta es 1 a 5.
abstract class VocationalRepository {
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
