import '../../../../core/models/test_session.dart';
import '../datasources/test_remote_datasource.dart';

class TestRepository {
  TestRepository({required TestRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  final TestRemoteDatasource _remoteDatasource;

  Future<TestSession> startTest() => _remoteDatasource.startTest();

  Future<SessionQuestions> getSessionQuestions(int sessionId) =>
      _remoteDatasource.getSessionQuestions(sessionId);

  Future<void> saveAnswer({
    required int sessionId,
    required int questionId,
    required int answerValue,
  }) =>
      _remoteDatasource.saveAnswer(
        sessionId: sessionId,
        questionId: questionId,
        answerValue: answerValue,
      );

  Future<RiasecResult> finishTest(int sessionId) =>
      _remoteDatasource.finishTest(sessionId);

  Future<RiasecResult> getResult(int sessionId) =>
      _remoteDatasource.getResult(sessionId);
}
