class ObservationCounselorSummary {
  const ObservationCounselorSummary({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
  });

  final int id;
  final String? email;
  final String? firstName;
  final String? lastName;

  String get displayName {
    final parts = <String>[
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!.trim(),
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
    ];
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    return email ?? 'Orientador $id';
  }

  factory ObservationCounselorSummary.fromJson(Map<String, dynamic> json) {
    return ObservationCounselorSummary(
      id: json['id'] as int,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }
}

class CounselorObservation {
  const CounselorObservation({
    required this.id,
    required this.testSessionId,
    required this.counselorId,
    required this.observation,
    required this.createdAt,
    required this.updatedAt,
    this.counselor,
  });

  final int id;
  final int testSessionId;
  final int counselorId;
  final String observation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ObservationCounselorSummary? counselor;

  factory CounselorObservation.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    final updated = json['updated_at'];
    if (created is! String || updated is! String) {
      throw const FormatException('Observación incompleta');
    }
    final counselorRaw = json['counselor'];
    return CounselorObservation(
      id: json['id'] as int,
      testSessionId: json['test_session_id'] as int,
      counselorId: json['counselor_id'] as int,
      observation: json['observation'] as String? ?? '',
      createdAt: DateTime.parse(created),
      updatedAt: DateTime.parse(updated),
      counselor: counselorRaw is Map<String, dynamic>
          ? ObservationCounselorSummary.fromJson(counselorRaw)
          : counselorRaw is Map
              ? ObservationCounselorSummary.fromJson(
                  Map<String, dynamic>.from(counselorRaw),
                )
              : null,
    );
  }
}

class ObservationPage {
  const ObservationPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
  });

  final List<CounselorObservation> items;
  final int total;
  final int page;
  final int pageSize;
  final int pages;

  factory ObservationPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <CounselorObservation>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(CounselorObservation.fromJson(item));
        } else if (item is Map) {
          items.add(
            CounselorObservation.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return ObservationPage(
      items: items,
      total: json['total'] as int? ?? items.length,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? items.length,
      pages: json['pages'] as int? ?? 0,
    );
  }
}

class ObservationDraft {
  const ObservationDraft({
    required this.testSessionId,
    required this.observation,
  });

  final int testSessionId;
  final String observation;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'test_session_id': testSessionId,
        'observation': observation,
      };
}
