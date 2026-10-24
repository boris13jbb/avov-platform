import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/assignment_repository.dart';
import '../domain/counselor_assignment.dart';

class ApiAssignmentRepository implements AssignmentRepository {
  ApiAssignmentRepository(this._dio);

  final Dio _dio;

  @override
  Future<CounselorAssignmentPage> list(AssignmentListQuery query) {
    return _send(() async {
      final response = await _dio.get<dynamic>(
        '/assignments',
        queryParameters: <String, dynamic>{
          'page': query.page,
          'page_size': query.pageSize,
          if (query.studentId != null) 'student_id': query.studentId,
          if (query.counselorId != null) 'counselor_id': query.counselorId,
          if (query.status != null) 'status': query.status,
        },
      );
      return CounselorAssignmentPage.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<CounselorAssignment> create({
    required int studentId,
    required int counselorId,
  }) {
    return _send(() async {
      final response = await _dio.post<dynamic>(
        '/assignments',
        data: <String, dynamic>{
          'student_id': studentId,
          'counselor_id': counselorId,
        },
      );
      return CounselorAssignment.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<CounselorAssignment> updateStatus({
    required int assignmentId,
    required String status,
  }) {
    return _send(() async {
      final response = await _dio.patch<dynamic>(
        '/assignments/$assignmentId/status',
        data: <String, String>{'status': status},
      );
      return CounselorAssignment.fromJson(readSuccessData(response.data));
    });
  }

  Future<T> _send<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException(FailureMapper.unexpectedMessage);
    }
  }
}
