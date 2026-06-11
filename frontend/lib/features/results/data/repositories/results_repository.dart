import '../../../../core/models/counselor_observation.dart';
import '../../../../core/models/recommendation.dart';
import '../datasources/recommendation_remote_datasource.dart';
import '../datasources/report_remote_datasource.dart';

class ResultsRepository {
  ResultsRepository({
    required RecommendationRemoteDatasource recommendationDatasource,
    required ReportRemoteDatasource reportDatasource,
  })  : _recommendationDatasource = recommendationDatasource,
        _reportDatasource = reportDatasource;

  final RecommendationRemoteDatasource _recommendationDatasource;
  final ReportRemoteDatasource _reportDatasource;

  Future<RecommendationList> generateRecommendations({int? testSessionId}) =>
      _recommendationDatasource.generateRecommendations(
        testSessionId: testSessionId,
      );

  Future<RecommendationList> listStudentRecommendations(int studentId) =>
      _recommendationDatasource.listStudentRecommendations(studentId);

  Future<CounselorObservation> addCounselorObservation({
    required int recommendationId,
    required String observation,
  }) =>
      _recommendationDatasource.addCounselorObservation(
        recommendationId: recommendationId,
        observation: observation,
      );

  Future<CounselorObservation> addCounselorObservationBySession({
    required int testSessionId,
    required String observation,
  }) =>
      _recommendationDatasource.addCounselorObservationBySession(
        testSessionId: testSessionId,
        observation: observation,
      );

  Future<ReportPdfFile> downloadPdf(int testSessionId) =>
      _reportDatasource.downloadPdf(testSessionId);
}
