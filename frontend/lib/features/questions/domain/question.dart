class RiasecCategoryBrief {
  const RiasecCategoryBrief({
    required this.id,
    required this.code,
    required this.name,
  });

  final int id;
  final String code;
  final String name;

  String get label => '$code — $name';

  factory RiasecCategoryBrief.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final code = json['code'];
    final name = json['name'];
    if (id is! int || code is! String || name is! String) {
      throw const FormatException('Categoría RIASEC incompleta');
    }
    return RiasecCategoryBrief(id: id, code: code, name: name);
  }
}

class VocationalQuestion {
  const VocationalQuestion({
    required this.id,
    required this.categoryId,
    required this.category,
    required this.text,
    required this.orderNumber,
    required this.status,
  });

  final int id;
  final int categoryId;
  final RiasecCategoryBrief category;
  final String text;
  final int orderNumber;
  final String status;

  String get statusLabel => status == 'ACTIVE' ? 'Activa' : 'Inactiva';

  factory VocationalQuestion.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final categoryId = json['category_id'];
    final categoryRaw = json['category'];
    final text = json['text'];
    final orderNumber = json['order_number'];
    final status = json['status'];
    if (id is! int ||
        categoryId is! int ||
        text is! String ||
        orderNumber is! int ||
        status is! String) {
      throw const FormatException('Pregunta incompleta');
    }
    if (categoryRaw is! Map) {
      throw const FormatException('Categoría de pregunta incompleta');
    }
    return VocationalQuestion(
      id: id,
      categoryId: categoryId,
      category: RiasecCategoryBrief.fromJson(
        Map<String, dynamic>.from(categoryRaw),
      ),
      text: text,
      orderNumber: orderNumber,
      status: status,
    );
  }
}

class QuestionPage {
  const QuestionPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  final List<VocationalQuestion> items;
  final int total;
  final int page;
  final int pages;
}

class QuestionDraft {
  const QuestionDraft({
    required this.categoryId,
    required this.text,
    required this.orderNumber,
    this.status = 'ACTIVE',
  });

  final int categoryId;
  final String text;
  final int orderNumber;
  final String status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'category_id': categoryId,
      'text': text,
      'order_number': orderNumber,
      'status': status,
    };
  }

  Map<String, dynamic> toUpdateJson() => toJson();
}

const riasecCategoryFilterLabels = <String, String>{
  'R': 'Realista',
  'I': 'Investigador',
  'A': 'Artístico',
  'S': 'Social',
  'E': 'Emprendedor',
  'C': 'Convencional',
};

final riasecCategoryFilterCodes = riasecCategoryFilterLabels.keys.toList();
