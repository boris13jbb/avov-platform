class CareerRecommendation {
  const CareerRecommendation({
    required this.id,
    required this.careerId,
    required this.careerName,
    required this.careerArea,
    required this.careerRiasecProfile,
    required this.matchPercentage,
    this.qdrantScore,
    this.aiExplanation,
    this.source,
  });

  final int id;
  final int careerId;
  final String careerName;
  final String careerArea;
  final String careerRiasecProfile;
  final double matchPercentage;
  final double? qdrantScore;
  final String? aiExplanation;
  final String? source;

  factory CareerRecommendation.fromJson(Map<String, dynamic> json) {
    return CareerRecommendation(
      id: json['id'] as int,
      careerId: json['career_id'] as int,
      careerName: json['career_name'] as String? ?? '',
      careerArea: json['career_area'] as String? ?? '',
      careerRiasecProfile: json['career_riasec_profile'] as String? ?? '',
      matchPercentage: (json['match_percentage'] as num).toDouble(),
      qdrantScore: (json['qdrant_score'] as num?)?.toDouble(),
      aiExplanation: json['ai_explanation'] as String?,
      source: json['source'] as String?,
    );
  }
}

class CareerRecommendationPage {
  const CareerRecommendationPage({
    required this.testSessionId,
    required this.studentId,
    required this.riasecProfile,
    required this.usedFallback,
    required this.items,
    required this.total,
  });

  final int testSessionId;
  final int studentId;
  final String riasecProfile;
  final bool usedFallback;
  final List<CareerRecommendation> items;
  final int total;

  factory CareerRecommendationPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return CareerRecommendationPage(
      testSessionId: json['test_session_id'] as int,
      studentId: json['student_id'] as int,
      riasecProfile: json['riasec_profile'] as String? ?? '',
      usedFallback: json['used_fallback'] as bool? ?? false,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(CareerRecommendation.fromJson)
          .toList(),
      total: json['total'] as int? ?? rawItems.length,
    );
  }
}
