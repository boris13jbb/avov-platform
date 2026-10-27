import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../../students/domain/managed_student.dart';
import '../../../students/presentation/providers/students_provider.dart';
import '../../../users/domain/managed_user.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../../data/api_assignment_repository.dart';
import '../../domain/assignment_repository.dart';
import '../../domain/counselor_assignment.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return ApiAssignmentRepository(ref.watch(dioClientProvider).dio);
});

final assignmentPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final assignmentStatusFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final assignmentListProvider =
    FutureProvider.autoDispose<CounselorAssignmentPage>((ref) async {
  final page = ref.watch(assignmentPageProvider);
  final status = ref.watch(assignmentStatusFilterProvider);
  return ref.watch(assignmentRepositoryProvider).list(
        AssignmentListQuery(page: page, pageSize: 20, status: status),
      );
});

final studentAssignmentListProvider = FutureProvider.autoDispose
    .family<CounselorAssignmentPage, int>((ref, studentId) async {
  return ref.watch(assignmentRepositoryProvider).list(
        AssignmentListQuery(page: 1, pageSize: 50, studentId: studentId),
      );
});

/// Conserva el primer registro por ``id`` (estable) para alimentar dropdowns.
///
/// [DropdownButtonFormField] exige exactamente un ítem por valor seleccionado;
/// entradas duplicadas del mismo id provocan la aserción en tiempo de ejecución.
List<T> uniqueByEntityId<T>(
  Iterable<T> items,
  int Function(T item) idOf,
) {
  final seen = <int>{};
  final unique = <T>[];
  for (final item in items) {
    if (seen.add(idOf(item))) {
      unique.add(item);
    }
  }
  return unique;
}

final counselorChoicesForAssignmentProvider =
    FutureProvider.autoDispose<List<ManagedUser>>((ref) async {
  final profile = await ref.watch(authRepositoryProvider).currentProfile();
  if (profile.role != 'INSTITUTION_ADMIN' && profile.role != 'SUPER_ADMIN') {
    return const [];
  }
  final page = await ref.watch(userAccountRepositoryProvider).list(
        const UserListQuery(page: 1, pageSize: 100, role: 'COUNSELOR'),
      );
  final active = page.items.where((user) => user.status == 'ACTIVE');
  return uniqueByEntityId(active, (user) => user.id);
});

final studentChoicesForAssignmentProvider =
    FutureProvider.autoDispose<List<ManagedStudent>>((ref) async {
  final profile = await ref.watch(authRepositoryProvider).currentProfile();
  if (profile.role != 'INSTITUTION_ADMIN' && profile.role != 'SUPER_ADMIN') {
    return const [];
  }
  final page = await ref.watch(studentRepositoryProvider).list(
        const StudentListQuery(page: 1, pageSize: 100, status: 'ACTIVE'),
      );
  return uniqueByEntityId(page.items, (student) => student.id);
});

bool canManageAssignments(String? role) {
  return role == 'SUPER_ADMIN' || role == 'INSTITUTION_ADMIN';
}
