/// Metadatos de un informe PDF en el historial (sin rutas de archivo).
class ReportHistoryItem {
  const ReportHistoryItem({
    required this.id,
    required this.studentId,
    required this.testSessionId,
    required this.reportCode,
    required this.generatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int studentId;
  final int testSessionId;
  final String reportCode;
  final int generatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ReportHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReportHistoryItem(
      id: _asInt(json['id']),
      studentId: _asInt(json['student_id']),
      testSessionId: _asInt(json['test_session_id']),
      reportCode: (json['report_code'] as String? ?? '').trim(),
      generatedBy: _asInt(json['generated_by']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw const FormatException('Entero inválido en historial de informes');
  }
}

class ReportHistoryPage {
  const ReportHistoryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
  });

  final List<ReportHistoryItem> items;
  final int total;
  final int page;
  final int pageSize;
  final int pages;

  factory ReportHistoryPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <ReportHistoryItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(ReportHistoryItem.fromJson(item));
        } else if (item is Map) {
          items.add(
            ReportHistoryItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return ReportHistoryPage(
      items: items,
      total: ReportHistoryItem._asInt(json['total']),
      page: ReportHistoryItem._asInt(json['page']),
      pageSize: ReportHistoryItem._asInt(json['page_size']),
      pages: ReportHistoryItem._asInt(json['pages']),
    );
  }
}
