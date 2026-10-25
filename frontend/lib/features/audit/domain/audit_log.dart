class AuditLogUserSummary {
  const AuditLogUserSummary({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.institutionId,
  });

  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final int? institutionId;

  String get displayName {
    final parts = <String>[
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!.trim(),
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
    ];
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    return email;
  }

  factory AuditLogUserSummary.fromJson(Map<String, dynamic> json) {
    return AuditLogUserSummary(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      institutionId: json['institution_id'] as int?,
    );
  }
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.entity,
    required this.createdAt,
    this.userId,
    this.entityId,
    this.ipAddress,
    this.userAgent,
    this.details,
    this.user,
  });

  final int id;
  final int? userId;
  final String action;
  final String entity;
  final int? entityId;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? details;
  final DateTime createdAt;
  final AuditLogUserSummary? user;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    if (created is! String) {
      throw const FormatException('Registro de auditoría incompleto');
    }
    final detailsRaw = json['details'];
    Map<String, dynamic>? details;
    if (detailsRaw is Map<String, dynamic>) {
      details = detailsRaw;
    } else if (detailsRaw is Map) {
      details = Map<String, dynamic>.from(detailsRaw);
    }
    final userRaw = json['user'];
    return AuditLogEntry(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      action: json['action'] as String? ?? '',
      entity: json['entity'] as String? ?? '',
      entityId: json['entity_id'] as int?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      details: details,
      createdAt: DateTime.parse(created),
      user: userRaw is Map<String, dynamic>
          ? AuditLogUserSummary.fromJson(userRaw)
          : userRaw is Map
              ? AuditLogUserSummary.fromJson(Map<String, dynamic>.from(userRaw))
              : null,
    );
  }
}

class AuditLogPage {
  const AuditLogPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
  });

  final List<AuditLogEntry> items;
  final int total;
  final int page;
  final int pageSize;
  final int pages;

  factory AuditLogPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <AuditLogEntry>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(AuditLogEntry.fromJson(item));
        } else if (item is Map) {
          items.add(AuditLogEntry.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return AuditLogPage(
      items: items,
      total: json['total'] as int? ?? items.length,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? items.length,
      pages: json['pages'] as int? ?? 0,
    );
  }
}

class AuditLogQuery {
  const AuditLogQuery({
    this.page = 1,
    this.pageSize = 20,
    this.action,
    this.entity,
  });

  final int page;
  final int pageSize;
  final String? action;
  final String? entity;
}
