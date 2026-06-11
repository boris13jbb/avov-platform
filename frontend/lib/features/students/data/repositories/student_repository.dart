import '../../../../core/models/student.dart';
import '../datasources/student_remote_datasource.dart';

class StudentRepository {
  StudentRepository({required StudentRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  final StudentRemoteDatasource _remoteDatasource;

  Future<PaginatedStudents> listStudents({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? institutionId,
    String? status,
    String? grade,
    String? gender,
  }) {
    return _remoteDatasource.listStudents(
      page: page,
      pageSize: pageSize,
      search: search,
      institutionId: institutionId,
      status: status,
      grade: grade,
      gender: gender,
    );
  }

  Future<ManagedStudent> getStudent(int id) => _remoteDatasource.getStudent(id);

  Future<ManagedStudent> createStudent(
    ManagedStudent student, {
    required int institutionId,
    required String password,
  }) =>
      _remoteDatasource.createStudent(
        student.toCreateJson(
          institutionId: institutionId,
          password: password,
        ),
      );

  Future<ManagedStudent> updateStudent(ManagedStudent student) =>
      _remoteDatasource.updateStudent(student.id, student.toUpdateJson());

  Future<ManagedStudent> updateStudentStatus(int id, String status) =>
      _remoteDatasource.updateStudentStatus(id, status);

  Future<ManagedStudent> assignCounselor({
    required int studentId,
    required int counselorId,
  }) =>
      _remoteDatasource.assignCounselor(studentId, counselorId);
}
