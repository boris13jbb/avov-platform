import 'counselor_assignment.dart';

class AssignmentListQuery {
  const AssignmentListQuery({
    this.page = 1,
    this.pageSize = 20,
    this.studentId,
    this.counselorId,
    this.status,
  });

  final int page;
  final int pageSize;
  final int? studentId;
  final int? counselorId;
  final String? status;
}

abstract class AssignmentRepository {
  Future<CounselorAssignmentPage> list(AssignmentListQuery query);

  Future<CounselorAssignment> create({
    required int studentId,
    required int counselorId,
  });

  Future<CounselorAssignment> updateStatus({
    required int assignmentId,
    required String status,
  });
}
