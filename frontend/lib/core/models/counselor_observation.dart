class CounselorObservation {
  const CounselorObservation({
    required this.id,
    required this.testSessionId,
    required this.counselorId,
    required this.observation,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int testSessionId;
  final int counselorId;
  final String observation;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CounselorObservation.fromJson(Map<String, dynamic> json) {
    return CounselorObservation(
      id: json['id'] as int,
      testSessionId: json['test_session_id'] as int,
      counselorId: json['counselor_id'] as int,
      observation: json['observation'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
