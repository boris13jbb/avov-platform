import '../../../../core/models/assistant_message.dart';
import '../datasources/assistant_remote_datasource.dart';

class AssistantRepository {
  AssistantRepository({required AssistantRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  final AssistantRemoteDatasource _remoteDatasource;

  Future<AssistantReply> sendChat({
    required String message,
    int? testSessionId,
  }) =>
      _remoteDatasource.sendChat(
        message: message,
        testSessionId: testSessionId,
      );

  Future<AssistantReply> explainProfile({int? testSessionId}) =>
      _remoteDatasource.explainProfile(testSessionId: testSessionId);

  Future<AssistantReply> explainCareers({
    required List<int> careerIds,
    int? testSessionId,
  }) =>
      _remoteDatasource.explainCareers(
        careerIds: careerIds,
        testSessionId: testSessionId,
      );
}
