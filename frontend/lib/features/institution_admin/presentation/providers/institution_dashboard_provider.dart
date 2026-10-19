import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/auth_tokens.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../../students/domain/managed_student.dart';
import '../../../students/presentation/providers/students_provider.dart';
import '../../../users/domain/managed_user.dart';
import '../../../users/presentation/providers/users_provider.dart';

class InstitutionDashboardData {
  const InstitutionDashboardData({
    required this.profile,
    required this.studentTotal,
    required this.counselorTotal,
  });

  final UserProfile profile;
  final int studentTotal;
  final int counselorTotal;
}

/// Totales de la institución del administrador.
///
/// `GET /students` y `GET /users?role=COUNSELOR` devuelven `total`.
/// El backend ignora un `institution_id` ajeno y aplica el de la sesión.
/// El nombre de la institución no viene en `/auth/me` y el catálogo
/// de instituciones solo lo puede leer un superadministrador.
final institutionDashboardProvider =
    FutureProvider.autoDispose<InstitutionDashboardData>((ref) async {
  final profile = await ref.watch(authRepositoryProvider).currentProfile();
  final students = await ref.watch(studentRepositoryProvider).list(
        const StudentListQuery(page: 1, pageSize: 1),
      );
  final counselors = await ref.watch(userAccountRepositoryProvider).list(
        const UserListQuery(page: 1, pageSize: 1, role: 'COUNSELOR'),
      );
  return InstitutionDashboardData(
    profile: profile,
    studentTotal: students.total,
    counselorTotal: counselors.total,
  );
});
