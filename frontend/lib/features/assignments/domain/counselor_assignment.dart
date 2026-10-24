class CounselorAssignment {
  const CounselorAssignment({
    required this.id,
    required this.counselorId,
    required this.studentId,
    required this.institutionId,
    required this.status,
    required this.assignedAt,
    this.counselorName,
    this.counselorEmail,
    this.studentName,
    this.studentIdentification,
  });

  final int id;
  final int counselorId;
  final int studentId;
  final int institutionId;
  final String status;
  final String assignedAt;
  final String? counselorName;
  final String? counselorEmail;
  final String? studentName;
  final String? studentIdentification;

  bool get isActive => status == 'ACTIVE';

  String get statusLabel => isActive ? 'Activa' : 'Inactiva';

  factory CounselorAssignment.fromJson(Map<String, dynamic> json) {
    final counselor = json['counselor'] as Map<String, dynamic>?;
    final student = json['student'] as Map<String, dynamic>?;
    final studentUser = student?['user'] as Map<String, dynamic>?;

    String? fullName(Map<String, dynamic>? person) {
      if (person == null) {
        return null;
      }
      final first = (person['first_name'] as String?)?.trim() ?? '';
      final last = (person['last_name'] as String?)?.trim() ?? '';
      final name = '$first $last'.trim();
      return name.isEmpty ? null : name;
    }

    return CounselorAssignment(
      id: json['id'] as int,
      counselorId: json['counselor_id'] as int,
      studentId: json['student_id'] as int,
      institutionId: json['institution_id'] as int,
      status: json['status'] as String,
      assignedAt: json['assigned_at'] as String? ?? '',
      counselorName: fullName(counselor),
      counselorEmail: counselor?['email'] as String?,
      studentName: fullName(studentUser),
      studentIdentification: student?['identification'] as String?,
    );
  }
}

class CounselorAssignmentPage {
  const CounselorAssignmentPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
  });

  final List<CounselorAssignment> items;
  final int total;
  final int page;
  final int pageSize;
  final int pages;

  factory CounselorAssignmentPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return CounselorAssignmentPage(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(CounselorAssignment.fromJson)
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      pages: json['pages'] as int? ?? 0,
    );
  }
}
