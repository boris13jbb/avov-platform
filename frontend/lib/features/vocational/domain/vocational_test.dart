class VocationalSession {
  const VocationalSession({
    required this.id,
    required this.studentId,
    required this.status,
    required this.totalQuestions,
    required this.answeredCount,
    required this.progressPercent,
  });

  final int id;
  final int studentId;
  final String status;
  final int totalQuestions;
  final int answeredCount;
  final double progressPercent;

  bool get isCompleted => status == 'COMPLETED';

  bool get isOpen => status == 'STARTED' || status == 'IN_PROGRESS';

  factory VocationalSession.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final studentId = json['student_id'];
    final status = json['status'];
    final total = json['total_questions'];
    final answered = json['answered_count'];
    final progress = json['progress_percent'];
    if (id is! int || studentId is! int || status is! String || total is! int) {
      throw const FormatException('Sesión de test incompleta');
    }
    return VocationalSession(
      id: id,
      studentId: studentId,
      status: status,
      totalQuestions: total,
      answeredCount: answered is int ? answered : 0,
      progressPercent: progress is num ? progress.toDouble() : 0,
    );
  }
}

class VocationalQuestion {
  const VocationalQuestion({
    required this.id,
    required this.text,
    required this.orderNumber,
    required this.categoryCode,
    required this.categoryName,
    this.answerValue,
  });

  final int id;
  final String text;
  final int orderNumber;
  final String categoryCode;
  final String categoryName;
  final int? answerValue;

  VocationalQuestion copyWithAnswer(int? answerValue) {
    return VocationalQuestion(
      id: id,
      text: text,
      orderNumber: orderNumber,
      categoryCode: categoryCode,
      categoryName: categoryName,
      answerValue: answerValue,
    );
  }

  factory VocationalQuestion.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final text = json['text'];
    final orderNumber = json['order_number'];
    final category = json['category'];
    if (id is! int || text is! String || orderNumber is! int || category is! Map) {
      throw const FormatException('Pregunta de test incompleta');
    }
    final categoryMap = Map<String, dynamic>.from(category);
    final code = categoryMap['code'];
    final name = categoryMap['name'];
    if (code is! String || name is! String) {
      throw const FormatException('Categoría de pregunta incompleta');
    }
    final answer = json['answer_value'];
    return VocationalQuestion(
      id: id,
      text: text,
      orderNumber: orderNumber,
      categoryCode: code,
      categoryName: name,
      answerValue: answer is int ? answer : null,
    );
  }
}

class VocationalSessionPage {
  const VocationalSessionPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  final List<VocationalSession> items;
  final int total;
  final int page;
  final int pages;

  factory VocationalSessionPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final total = json['total'];
    final page = json['page'];
    final pages = json['pages'];
    if (items is! List || total is! int || page is! int || pages is! int) {
      throw const FormatException('Historial de evaluaciones incompleto');
    }
    return VocationalSessionPage(
      items: [
        for (final item in items)
          if (item is Map)
            VocationalSession.fromJson(Map<String, dynamic>.from(item))
          else
            throw const FormatException('Sesión de test incompleta'),
      ],
      total: total,
      page: page,
      pages: pages,
    );
  }
}

class VocationalQuestionnaire {
  const VocationalQuestionnaire({
    required this.session,
    required this.questions,
  });

  final VocationalSession session;
  final List<VocationalQuestion> questions;

  factory VocationalQuestionnaire.fromJson(Map<String, dynamic> json) {
    final session = json['session'];
    final questions = json['questions'];
    if (session is! Map || questions is! List) {
      throw const FormatException('Cuestionario incompleto');
    }
    final parsed = [
      for (final item in questions)
        if (item is Map)
          VocationalQuestion.fromJson(Map<String, dynamic>.from(item))
        else
          throw const FormatException('Pregunta de test incompleta'),
    ]..sort((a, b) {
        final byOrder = a.orderNumber.compareTo(b.orderNumber);
        if (byOrder != 0) {
          return byOrder;
        }
        return a.id.compareTo(b.id);
      });
    return VocationalQuestionnaire(
      session: VocationalSession.fromJson(Map<String, dynamic>.from(session)),
      questions: parsed,
    );
  }
}

class VocationalResult {
  const VocationalResult({
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
  });

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

  factory VocationalResult.fromJson(Map<String, dynamic> json) {
    int score(String key) {
      final value = json[key];
      if (value is! int) {
        throw const FormatException('Resultado RIASEC incompleto');
      }
      return value;
    }

    final sessionId = json['test_session_id'];
    final studentId = json['student_id'];
    if (sessionId is! int || studentId is! int) {
      throw const FormatException('Resultado RIASEC incompleto');
    }
    String? text(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        return null;
      }
      return value.trim();
    }

    return VocationalResult(
      testSessionId: sessionId,
      studentId: studentId,
      scoreR: score('score_r'),
      scoreI: score('score_i'),
      scoreA: score('score_a'),
      scoreS: score('score_s'),
      scoreE: score('score_e'),
      scoreC: score('score_c'),
      dominantProfile: text('dominant_profile'),
      secondaryProfile: text('secondary_profile'),
      combinedProfile: text('combined_profile'),
      interpretation: text('interpretation'),
    );
  }
}

const answerScaleLabels = <int, String>{
  1: '1 — No me gusta nada',
  2: '2',
  3: '3',
  4: '4',
  5: '5 — Me gusta mucho',
};
