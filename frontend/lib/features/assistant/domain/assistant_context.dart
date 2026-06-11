class AssistantContext {
  const AssistantContext({
    this.studentId,
    this.completedSessionId,
    this.openSessionId,
    this.testStatus = 'Sin test',
    this.recommendationsCount = 0,
  });

  final int? studentId;
  final int? completedSessionId;
  final int? openSessionId;
  final String testStatus;
  final int recommendationsCount;

  bool get hasCompletedTest => completedSessionId != null;
  bool get hasRecommendations => recommendationsCount > 0;
  bool get hasOpenSession => openSessionId != null;

  bool get canExplainProfile => hasCompletedTest;
  bool get canExplainCareers => hasCompletedTest;

  String get testStatusLabel {
    switch (testStatus) {
      case 'COMPLETED':
        return 'Completado';
      case 'IN_PROGRESS':
        return 'En progreso';
      case 'STARTED':
        return 'Iniciado';
      default:
        return testStatus;
    }
  }

  String? get profileBlockReason {
    if (hasCompletedTest) return null;
    if (hasOpenSession) {
      return 'Tienes un test en progreso. Complétalo para que el asistente '
          'pueda explicar tu perfil RIASEC.';
    }
    return 'Debes completar el test vocacional para que el asistente '
        'pueda usar tu perfil RIASEC.';
  }

  String? get careersBlockReason {
    if (!hasCompletedTest) {
      return profileBlockReason;
    }
    if (!hasRecommendations) {
      return 'Aún no tienes recomendaciones de carreras. Puedes generarlas '
          'desde aquí y el asistente las explicará al instante.';
    }
    return null;
  }

  factory AssistantContext.fromDashboard(Map<String, dynamic>? dashboard) {
    if (dashboard == null) return const AssistantContext();

    final test = dashboard['test'] as Map<String, dynamic>? ?? {};
    final openSession = test['open_session'] as Map<String, dynamic>?;

    return AssistantContext(
      studentId: (dashboard['student_id'] as num?)?.toInt(),
      completedSessionId:
          (test['latest_completed_session_id'] as num?)?.toInt(),
      openSessionId: (openSession?['id'] as num?)?.toInt(),
      testStatus: test['status'] as String? ?? 'Sin test',
      recommendationsCount: (dashboard['recommendations_count'] as num?)?.toInt() ?? 0,
    );
  }
}
