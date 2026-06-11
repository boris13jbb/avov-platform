class CareerBrief {
  const CareerBrief({
    required this.id,
    required this.name,
    required this.area,
    required this.riasecProfile,
    required this.degreeType,
    required this.institutionType,
    required this.employmentField,
  });

  final int id;
  final String name;
  final String area;
  final String riasecProfile;
  final String degreeType;
  final String institutionType;
  final String employmentField;

  factory CareerBrief.fromJson(Map<String, dynamic> json) {
    return CareerBrief(
      id: json['id'] as int,
      name: json['name'] as String,
      area: json['area'] as String? ?? '',
      riasecProfile: json['riasec_profile'] as String? ?? '',
      degreeType: json['degree_type'] as String? ?? '',
      institutionType: json['institution_type'] as String? ?? '',
      employmentField: json['employment_field'] as String? ?? '',
    );
  }
}

class CareerRecommendation {
  const CareerRecommendation({
    required this.id,
    required this.testSessionId,
    required this.studentId,
    required this.careerId,
    required this.career,
    required this.matchPercentage,
    required this.riasecScore,
    this.qdrantScore,
    this.aiExplanation,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int testSessionId;
  final int studentId;
  final int careerId;
  final CareerBrief career;
  final double matchPercentage;
  final double riasecScore;
  final double? qdrantScore;
  final String? aiExplanation;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CareerRecommendation.fromJson(Map<String, dynamic> json) {
    return CareerRecommendation(
      id: json['id'] as int,
      testSessionId: json['test_session_id'] as int,
      studentId: json['student_id'] as int,
      careerId: json['career_id'] as int,
      career: CareerBrief.fromJson(json['career'] as Map<String, dynamic>),
      matchPercentage: (json['match_percentage'] as num).toDouble(),
      riasecScore: (json['riasec_score'] as num).toDouble(),
      qdrantScore: (json['qdrant_score'] as num?)?.toDouble(),
      aiExplanation: json['ai_explanation'] as String?,
      source: json['source'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class RecommendationList {
  const RecommendationList({
    required this.studentId,
    required this.testSessionId,
    required this.items,
    this.aiSummary,
    this.aiSource,
    required this.usedFallback,
    required this.fromCache,
    required this.ethicalDisclaimer,
  });

  final int studentId;
  final int testSessionId;
  final List<CareerRecommendation> items;
  final String? aiSummary;
  final String? aiSource;
  final bool usedFallback;
  final bool fromCache;
  final String ethicalDisclaimer;

  factory RecommendationList.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return RecommendationList(
      studentId: json['student_id'] as int,
      testSessionId: json['test_session_id'] as int,
      items: rawItems
          .map(
            (item) =>
                CareerRecommendation.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      aiSummary: json['ai_summary'] as String?,
      aiSource: json['ai_source'] as String?,
      usedFallback: json['used_fallback'] as bool? ?? false,
      fromCache: json['from_cache'] as bool? ?? false,
      ethicalDisclaimer: json['ethical_disclaimer'] as String? ?? '',
    );
  }
}
