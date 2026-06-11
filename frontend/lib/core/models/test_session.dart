enum TestSessionStatus {
  started('STARTED'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const TestSessionStatus(this.apiValue);

  final String apiValue;

  static TestSessionStatus fromApi(String? value) {
    for (final status in TestSessionStatus.values) {
      if (status.apiValue == value) return status;
    }
    return TestSessionStatus.started;
  }

  String get label {
    switch (this) {
      case TestSessionStatus.started:
        return 'Iniciado';
      case TestSessionStatus.inProgress:
        return 'En progreso';
      case TestSessionStatus.completed:
        return 'Completado';
      case TestSessionStatus.cancelled:
        return 'Cancelado';
    }
  }

  bool get isOpen =>
      this == TestSessionStatus.started || this == TestSessionStatus.inProgress;
}

class TestSession {
  const TestSession({
    required this.id,
    required this.studentId,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    required this.totalQuestions,
    required this.currentQuestion,
    required this.answeredCount,
    required this.progressPercent,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int studentId;
  final TestSessionStatus status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int totalQuestions;
  final int currentQuestion;
  final int answeredCount;
  final double progressPercent;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isComplete => answeredCount >= totalQuestions;

  factory TestSession.fromJson(Map<String, dynamic> json) {
    return TestSession(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      status: TestSessionStatus.fromApi(json['status'] as String?),
      startedAt: DateTime.parse(json['started_at'] as String),
      finishedAt: json['finished_at'] == null
          ? null
          : DateTime.parse(json['finished_at'] as String),
      totalQuestions: json['total_questions'] as int? ?? 60,
      currentQuestion: json['current_question'] as int? ?? 1,
      answeredCount: json['answered_count'] as int? ?? 0,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class TestQuestion {
  const TestQuestion({
    required this.id,
    required this.categoryId,
    required this.categoryCode,
    required this.categoryName,
    required this.text,
    required this.orderNumber,
    this.answerValue,
  });

  final int id;
  final int categoryId;
  final String categoryCode;
  final String categoryName;
  final String text;
  final int orderNumber;
  final int? answerValue;

  TestQuestion copyWith({int? answerValue}) {
    return TestQuestion(
      id: id,
      categoryId: categoryId,
      categoryCode: categoryCode,
      categoryName: categoryName,
      text: text,
      orderNumber: orderNumber,
      answerValue: answerValue ?? this.answerValue,
    );
  }

  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>? ?? {};
    return TestQuestion(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      categoryCode: category['code'] as String? ?? '',
      categoryName: category['name'] as String? ?? '',
      text: json['text'] as String,
      orderNumber: json['order_number'] as int,
      answerValue: json['answer_value'] as int?,
    );
  }
}

class SessionQuestions {
  const SessionQuestions({
    required this.session,
    required this.questions,
  });

  final TestSession session;
  final List<TestQuestion> questions;

  factory SessionQuestions.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    return SessionQuestions(
      session: TestSession.fromJson(
        json['session'] as Map<String, dynamic>,
      ),
      questions: rawQuestions
          .map((q) => TestQuestion.fromJson(q as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.orderNumber.compareTo(b.orderNumber)),
    );
  }
}

class RiasecResult {
  const RiasecResult({
    required this.id,
    required this.testSessionId,
    required this.studentId,
    required this.scoreR,
    required this.scoreI,
    required this.scoreA,
    required this.scoreS,
    required this.scoreE,
    required this.scoreC,
    this.dominantProfile,
    this.secondaryProfile,
    this.combinedProfile,
    this.interpretation,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int testSessionId;
  final int studentId;
  final int scoreR;
  final int scoreI;
  final int scoreA;
  final int scoreS;
  final int scoreE;
  final int scoreC;
  final String? dominantProfile;
  final String? secondaryProfile;
  final String? combinedProfile;
  final String? interpretation;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RiasecResult.fromJson(Map<String, dynamic> json) {
    return RiasecResult(
      id: json['id'] as int,
      testSessionId: json['test_session_id'] as int,
      studentId: json['student_id'] as int,
      scoreR: json['score_r'] as int? ?? 0,
      scoreI: json['score_i'] as int? ?? 0,
      scoreA: json['score_a'] as int? ?? 0,
      scoreS: json['score_s'] as int? ?? 0,
      scoreE: json['score_e'] as int? ?? 0,
      scoreC: json['score_c'] as int? ?? 0,
      dominantProfile: json['dominant_profile'] as String?,
      secondaryProfile: json['secondary_profile'] as String?,
      combinedProfile: json['combined_profile'] as String?,
      interpretation: json['interpretation'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
