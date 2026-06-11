import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/models/student.dart';

class StudentRemoteDatasource {
  StudentRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PaginatedStudents> listStudents({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? institutionId,
    String? status,
    String? grade,
    String? gender,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/students',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          if (institutionId != null) 'institution_id': institutionId,
          if (status != null && status.isNotEmpty) 'status': status,
          if (grade != null && grade.isNotEmpty) 'grade': grade,
          if (gender != null && gender.isNotEmpty) 'gender': gender,
        },
      );
      return _parseData(
        response.data,
        PaginatedStudents.fromJson,
        'No se pudieron cargar los estudiantes',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<ManagedStudent> getStudent(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/students/$id');
      return _parseData(
        response.data,
        ManagedStudent.fromJson,
        'No se pudo cargar el estudiante',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<ManagedStudent> createStudent(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/students',
        data: body,
      );
      return _parseData(
        response.data,
        ManagedStudent.fromJson,
        'No se pudo crear el estudiante',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<ManagedStudent> updateStudent(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/students/$id',
        data: body,
      );
      return _parseData(
        response.data,
        ManagedStudent.fromJson,
        'No se pudo actualizar el estudiante',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<ManagedStudent> updateStudentStatus(int id, String status) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/students/$id/status',
        data: {'status': status},
      );
      return _parseData(
        response.data,
        ManagedStudent.fromJson,
        'No se pudo actualizar el estado del estudiante',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<ManagedStudent> assignCounselor(int studentId, int counselorId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/students/$studentId/assign-counselor',
        data: {'counselor_id': counselorId},
      );
      return _parseData(
        response.data,
        ManagedStudent.fromJson,
        'No se pudo asignar el orientador',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  T _parseData<T>(
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>) fromJson,
    String fallbackMessage,
  ) {
    if (body == null || body['success'] != true) {
      throw AppException(body?['message'] as String? ?? fallbackMessage);
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw AppException('Respuesta de estudiante inválida');
    }
    return fromJson(data);
  }
}
