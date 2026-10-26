import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/question.dart';
import '../domain/question_repository.dart';

class ApiQuestionRepository implements QuestionRepository {
  ApiQuestionRepository(this._dio);

  final Dio _dio;

  @override
  Future<QuestionPage> list({
    required int page,
    required int pageSize,
    String? search,
    String? categoryCode,
    String? status,
  }) {
    return _send(() async {
      final response = await _dio.get<dynamic>(
        '/questions',
        queryParameters: <String, dynamic>{
          'page': page,
          'page_size': pageSize,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (categoryCode != null && categoryCode.isNotEmpty)
            'category_code': categoryCode,
          if (status != null) 'status': status,
        },
      );
      return _parsePage(response.data);
    });
  }

  @override
  Future<VocationalQuestion> getById(int id) {
    return _send(() async {
      final response = await _dio.get<dynamic>('/questions/$id');
      return VocationalQuestion.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<List<RiasecCategoryBrief>> discoverCategories() {
    return _send(() async {
      final response = await _dio.get<dynamic>(
        '/questions',
        queryParameters: const <String, dynamic>{
          'page': 1,
          'page_size': 100,
        },
      );
      final page = _parsePage(response.data);
      final byId = <int, RiasecCategoryBrief>{};
      for (final item in page.items) {
        byId[item.category.id] = item.category;
      }
      final categories = byId.values.toList()
        ..sort((a, b) => a.code.compareTo(b.code));
      return categories;
    });
  }

  @override
  Future<VocationalQuestion> create(QuestionDraft draft) {
    return _send(() async {
      final response = await _dio.post<dynamic>(
        '/questions',
        data: draft.toJson(),
      );
      return VocationalQuestion.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<VocationalQuestion> update(int id, QuestionDraft draft) {
    return _send(() async {
      final response = await _dio.put<dynamic>(
        '/questions/$id',
        data: draft.toUpdateJson(),
      );
      return VocationalQuestion.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<VocationalQuestion> updateStatus({
    required int id,
    required String status,
  }) {
    return _send(() async {
      final response = await _dio.patch<dynamic>(
        '/questions/$id/status',
        data: <String, String>{'status': status},
      );
      return VocationalQuestion.fromJson(readSuccessData(response.data));
    });
  }

  Future<T> _send<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    } on FormatException {
      throw AppException(FailureMapper.unexpectedMessage);
    }
  }

  QuestionPage _parsePage(Object? raw) {
    final data = readSuccessData(raw);
    final itemsRaw = data['items'];
    final total = data['total'];
    final page = data['page'];
    final pages = data['pages'];
    if (itemsRaw is! List || total is! int || page is! int || pages is! int) {
      throw const FormatException('Página de preguntas incompleta');
    }
    return QuestionPage(
      items: [
        for (final item in itemsRaw)
          if (item is Map<String, dynamic>)
            VocationalQuestion.fromJson(item)
          else if (item is Map)
            VocationalQuestion.fromJson(Map<String, dynamic>.from(item))
          else
            throw const FormatException('Pregunta incompleta'),
      ],
      total: total,
      page: page,
      pages: pages,
    );
  }
}
