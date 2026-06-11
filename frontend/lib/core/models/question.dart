enum QuestionStatus {
  active('ACTIVE'),
  inactive('INACTIVE');

  const QuestionStatus(this.apiValue);

  final String apiValue;

  static QuestionStatus fromApi(String? value) {
    for (final status in QuestionStatus.values) {
      if (status.apiValue == value) return status;
    }
    return QuestionStatus.active;
  }

  String get label {
    switch (this) {
      case QuestionStatus.active:
        return 'Activa';
      case QuestionStatus.inactive:
        return 'Inactiva';
    }
  }
}

class RiasecCategory {
  const RiasecCategory({
    required this.id,
    required this.code,
    required this.name,
    this.description,
  });

  final int id;
  final String code;
  final String name;
  final String? description;

  factory RiasecCategory.fromJson(Map<String, dynamic> json) {
    return RiasecCategory(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

class Question {
  const Question({
    required this.id,
    required this.categoryId,
    required this.category,
    required this.text,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int categoryId;
  final RiasecCategory category;
  final String text;
  final int orderNumber;
  final QuestionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      category: RiasecCategory.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      text: json['text'] as String,
      orderNumber: json['order_number'] as int,
      status: QuestionStatus.fromApi(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'category_id': categoryId,
      'text': text,
      'order_number': orderNumber,
      'status': status.apiValue,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'category_id': categoryId,
      'text': text,
      'order_number': orderNumber,
      'status': status.apiValue,
    };
  }
}

class PaginatedQuestions {
  const PaginatedQuestions({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
  });

  final List<Question> items;
  final int total;
  final int page;
  final int pageSize;
  final int pages;

  factory PaginatedQuestions.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PaginatedQuestions(
      items: rawItems
          .map((item) => Question.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      pages: json['pages'] as int? ?? 0,
    );
  }
}
