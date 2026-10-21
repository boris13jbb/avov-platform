import 'career_recommendation.dart';

abstract class RecommendationRepository {
  Future<CareerRecommendationPage> listForSession(int sessionId);

  Future<CareerRecommendationPage> generateForSession(int sessionId);
}
