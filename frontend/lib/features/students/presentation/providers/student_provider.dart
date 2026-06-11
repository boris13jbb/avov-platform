import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/student.dart';
import '../../../../core/providers/providers.dart';
import '../../data/datasources/student_remote_datasource.dart';
import '../../data/repositories/student_repository.dart';

final studentRemoteDatasourceProvider = Provider<StudentRemoteDatasource>((ref) {
  return StudentRemoteDatasource(ref.watch(dioClientProvider).dio);
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(
    remoteDatasource: ref.watch(studentRemoteDatasourceProvider),
  );
});

class StudentListQuery {
  const StudentListQuery({
    this.page = 1,
    this.search,
    this.status,
    this.grade,
    this.gender,
  });

  final int page;
  final String? search;
  final String? status;
  final String? grade;
  final String? gender;

  StudentListQuery copyWith({
    int? page,
    String? search,
    String? status,
    String? grade,
    String? gender,
    bool clearSearch = false,
    bool clearStatus = false,
    bool clearGrade = false,
    bool clearGender = false,
  }) {
    return StudentListQuery(
      page: page ?? this.page,
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      grade: clearGrade ? null : (grade ?? this.grade),
      gender: clearGender ? null : (gender ?? this.gender),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StudentListQuery &&
        other.page == page &&
        other.search == search &&
        other.status == status &&
        other.grade == grade &&
        other.gender == gender;
  }

  @override
  int get hashCode => Object.hash(page, search, status, grade, gender);
}

final studentListProvider =
    FutureProvider.family<PaginatedStudents, StudentListQuery>((ref, query) {
  return ref.watch(studentRepositoryProvider).listStudents(
        page: query.page,
        search: query.search,
        status: query.status,
        grade: query.grade,
        gender: query.gender,
      );
});

final studentDetailProvider =
    FutureProvider.family<ManagedStudent, int>((ref, id) {
  return ref.watch(studentRepositoryProvider).getStudent(id);
});

final studentMutationProvider =
    StateNotifierProvider<StudentMutationController, AsyncValue<void>>(
  (ref) => StudentMutationController(ref.watch(studentRepositoryProvider)),
);

class StudentMutationController extends StateNotifier<AsyncValue<void>> {
  StudentMutationController(this._repository) : super(const AsyncData(null));

  final StudentRepository _repository;

  Future<ManagedStudent?> create(
    ManagedStudent student, {
    required int institutionId,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final created = await _repository.createStudent(
        student,
        institutionId: institutionId,
        password: password,
      );
      state = const AsyncData(null);
      return created;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<ManagedStudent?> update(ManagedStudent student) async {
    state = const AsyncLoading();
    try {
      final updated = await _repository.updateStudent(student);
      state = const AsyncData(null);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<bool> updateStatus(int id, String status) async {
    state = const AsyncLoading();
    try {
      await _repository.updateStudentStatus(id, status);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> assignCounselor({
    required int studentId,
    required int counselorId,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.assignCounselor(
        studentId: studentId,
        counselorId: counselorId,
      );
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }
}
