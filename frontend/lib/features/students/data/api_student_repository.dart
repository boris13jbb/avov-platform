import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/managed_student.dart';
import '../domain/student_repository.dart';

class ApiStudentRepository implements StudentRepository {
  ApiStudentRepository(this._dio);

  final Dio _dio;

  @override
  Future<ManagedStudentPage> list(StudentListQuery query) {
    return _send(() async {
      final search = query.search?.trim();
      final grade = query.grade?.trim();
      final response = await _dio.get<dynamic>(
        '/students',
        queryParameters: <String, dynamic>{
          'page': query.page,
          'page_size': query.pageSize,
          if (search != null && search.isNotEmpty)
            'search': search.length > 100 ? search.substring(0, 100) : search,
          if (query.institutionId != null) 'institution_id': query.institutionId,
          if (query.status != null) 'status': query.status,
          if (grade != null && grade.isNotEmpty)
            'grade': grade.length > 20 ? grade.substring(0, 20) : grade,
          if (query.gender != null) 'gender': query.gender,
        },
      );
      return _parsePage(response.data);
    });
  }

  @override
  Future<ManagedStudent> getOwn() {
    return _send(() async {
      final response = await _dio.get<dynamic>('/students/me');
      return ManagedStudent.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<ManagedStudent> getById(int id) {
    return _send(() async {
      final response = await _dio.get<dynamic>('/students/$id');
      return ManagedStudent.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<ManagedStudent> create(StudentDraft draft) {
    return _send(() async {
      final response = await _dio.post<dynamic>(
        '/students',
        data: draft.toCreateJson(),
      );
      return ManagedStudent.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<ManagedStudent> update(int id, StudentDraft draft) {
    return _send(() async {
      final response = await _dio.put<dynamic>(
        '/students/$id',
        data: draft.toUpdateJson(),
      );
      return ManagedStudent.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<ManagedStudent> updateStatus(int id, String status) {
    return _send(() async {
      final response = await _dio.patch<dynamic>(
        '/students/$id/status',
        data: <String, String>{'status': status},
      );
      return ManagedStudent.fromJson(readSuccessData(response.data));
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

  ManagedStudentPage _parsePage(Object? raw) {
    final data = readSuccessData(raw);
    final itemsRaw = data['items'];
    final total = data['total'];
    final page = data['page'];
    final pages = data['pages'];
    if (itemsRaw is! List || total is! int || page is! int || pages is! int) {
      throw const FormatException('Página de estudiantes incompleta');
    }
    return ManagedStudentPage(
      items: [
        for (final item in itemsRaw)
          if (item is Map<String, dynamic>)
            ManagedStudent.fromJson(item)
          else if (item is Map)
            ManagedStudent.fromJson(Map<String, dynamic>.from(item))
          else
            throw const FormatException('Estudiante incompleto'),
      ],
      total: total,
      page: page,
      pages: pages,
    );
  }
}
