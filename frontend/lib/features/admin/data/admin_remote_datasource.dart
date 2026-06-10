import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/models/career.dart';
import '../../../core/models/question.dart';
import '../../../core/models/system_setting.dart';

class AdminRemoteDatasource {
  AdminRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PaginatedCareers> listCareers({
    int page = 1,
    String? search,
    String? status,
  }) async {
    return _getPaginated(
      '/careers',
      queryParameters: {
        'page': page,
        'page_size': 20,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      fallback: 'No se pudieron cargar las carreras',
      parser: PaginatedCareers.fromJson,
    );
  }

  Future<Career> getCareer(int id) async {
    return _getItem(
      '/careers/$id',
      fallback: 'No se pudo cargar la carrera',
      parser: Career.fromJson,
    );
  }

  Future<CareerMutationResult> createCareer(Map<String, dynamic> body) async {
    return _mutateCareer(
      () => _dio.post<Map<String, dynamic>>('/careers', data: body),
      fallback: 'No se pudo crear la carrera',
    );
  }

  Future<CareerMutationResult> updateCareer(
    int id,
    Map<String, dynamic> body,
  ) async {
    return _mutateCareer(
      () => _dio.put<Map<String, dynamic>>('/careers/$id', data: body),
      fallback: 'No se pudo actualizar la carrera',
    );
  }

  Future<CareerMutationResult> deactivateCareer(int id) async {
    return _mutateCareer(
      () => _dio.delete<Map<String, dynamic>>('/careers/$id'),
      fallback: 'No se pudo desactivar la carrera',
    );
  }

  Future<CareerMutationResult> _mutateCareer(
    Future<Response<Map<String, dynamic>>> Function() request, {
    required String fallback,
  }) async {
    try {
      final response = await request();
      final body = response.data;
      if (body == null || body['success'] != true) {
        throw AppException(body?['message'] as String? ?? fallback);
      }
      return CareerMutationResult.fromApiBody(body);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<PaginatedQuestions> listQuestions({
    int page = 1,
    String? search,
    String? status,
  }) async {
    return _getPaginated(
      '/questions',
      queryParameters: {
        'page': page,
        'page_size': 20,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      fallback: 'No se pudieron cargar las preguntas',
      parser: PaginatedQuestions.fromJson,
    );
  }

  Future<Question> getQuestion(int id) async {
    return _getItem(
      '/questions/$id',
      fallback: 'No se pudo cargar la pregunta',
      parser: Question.fromJson,
    );
  }

  Future<Question> createQuestion(Map<String, dynamic> body) async {
    return _postItem(
      '/questions',
      data: body,
      fallback: 'No se pudo crear la pregunta',
      parser: Question.fromJson,
    );
  }

  Future<Question> updateQuestion(int id, Map<String, dynamic> body) async {
    return _putItem(
      '/questions/$id',
      data: body,
      fallback: 'No se pudo actualizar la pregunta',
      parser: Question.fromJson,
    );
  }

  Future<Question> deleteQuestion(int id) async {
    return _deleteItem(
      '/questions/$id',
      fallback: 'No se pudo desactivar la pregunta',
      parser: Question.fromJson,
    );
  }

  Future<List<RiasecCategory>> listRiasecCategories() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/riasec-categories',
      );
      final data = _parseListData(
        response.data,
        'No se pudieron cargar las categorías RIASEC',
      );
      return data
          .map((item) => RiasecCategory.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<List<SystemSetting>> listSystemSettings() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/settings');
      final data = _parseListData(
        response.data,
        'No se pudo cargar la configuración del sistema',
      );
      return data
          .map((item) => SystemSetting.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<SystemSetting> updateSystemSetting({
    required String key,
    required String value,
  }) async {
    return _putItem(
      '/settings/$key',
      data: {'value': value},
      fallback: 'No se pudo actualizar el parámetro',
      parser: SystemSetting.fromJson,
    );
  }

  Future<Map<String, dynamic>> rebuildVectorIndex() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/vector/rebuild-careers',
      );
      return _parseMapData(response.data, 'No se pudo reconstruir el índice');
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<Map<String, dynamic>> getAuditLog(int id) async {
    return _getItem(
      '/audit/logs/$id',
      fallback: 'No se pudo cargar el registro de auditoría',
      parser: (data) => data,
    );
  }

  Future<Map<String, dynamic>> listAuditLogs({
    int page = 1,
    String? action,
    String? entity,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/audit/logs',
        queryParameters: {
          'page': page,
          'page_size': 20,
          if (action != null && action.isNotEmpty) 'action': action,
          if (entity != null && entity.isNotEmpty) 'entity': entity,
        },
      );
      return _parseMapData(
        response.data,
        'No se pudieron cargar los registros de auditoría',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<T> _getPaginated<T>(
    String path, {
    required Map<String, dynamic> queryParameters,
    required String fallback,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final data = _parseMapData(response.data, fallback);
      return parser(data);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<T> _getItem<T>(
    String path, {
    required String fallback,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      final data = _parseMapData(response.data, fallback);
      return parser(data);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<T> _postItem<T>(
    String path, {
    required Map<String, dynamic> data,
    required String fallback,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      final parsed = _parseMapData(response.data, fallback);
      return parser(parsed);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<T> _putItem<T>(
    String path, {
    required Map<String, dynamic> data,
    required String fallback,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(path, data: data);
      final parsed = _parseMapData(response.data, fallback);
      return parser(parsed);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<T> _deleteItem<T>(
    String path, {
    required String fallback,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(path);
      final parsed = _parseMapData(response.data, fallback);
      return parser(parsed);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  List<dynamic> _parseListData(
    Map<String, dynamic>? body,
    String fallbackMessage,
  ) {
    if (body == null || body['success'] != true) {
      throw AppException(body?['message'] as String? ?? fallbackMessage);
    }
    final data = body['data'];
    if (data is! List<dynamic>) {
      throw AppException('Respuesta inválida del servidor');
    }
    return data;
  }

  Map<String, dynamic> _parseMapData(
    Map<String, dynamic>? body,
    String fallbackMessage,
  ) {
    if (body == null || body['success'] != true) {
      throw AppException(body?['message'] as String? ?? fallbackMessage);
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw AppException('Respuesta inválida del servidor');
    }
    return data;
  }
}
