import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../../data/api_student_repository.dart';
import '../../domain/managed_student.dart';
import '../../domain/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return ApiStudentRepository(ref.watch(dioClientProvider).dio);
});

final ownStudentProvider = FutureProvider.autoDispose<ManagedStudent>((ref) {
  return ref.watch(studentRepositoryProvider).getOwn();
});

final studentPageProvider = StateProvider<int>((ref) => 1);
final studentSearchProvider = StateProvider<String>((ref) => '');
final studentInstitutionFilterProvider = StateProvider<int?>((ref) => null);
final studentStatusFilterProvider = StateProvider<String?>((ref) => null);
final studentGradeFilterProvider = StateProvider<String>((ref) => '');
final studentGenderFilterProvider = StateProvider<String?>((ref) => null);

final studentListProvider = FutureProvider.autoDispose<ManagedStudentPage>((ref) async {
  final operator = await ref.watch(currentOperatorProvider.future);
  final requestedInstitution = ref.watch(studentInstitutionFilterProvider);
  return ref.watch(studentRepositoryProvider).list(
        StudentListQuery(
          page: ref.watch(studentPageProvider),
          pageSize: 20,
          search: ref.watch(studentSearchProvider),
          institutionId:
              operator.role == 'SUPER_ADMIN' ? requestedInstitution : null,
          status: ref.watch(studentStatusFilterProvider),
          grade: ref.watch(studentGradeFilterProvider),
          gender: ref.watch(studentGenderFilterProvider),
        ),
      );
});

final studentDetailProvider =
    FutureProvider.autoDispose.family<ManagedStudent, int>((ref, id) {
  return ref.watch(studentRepositoryProvider).getById(id);
});
