import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/domain/auth_tokens.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../../students/domain/managed_student.dart';
import '../../../students/presentation/providers/students_provider.dart';

class CounselorDashboardData {
  const CounselorDashboardData({
    required this.profile,
    required this.assignedStudentTotal,
  });

  final UserProfile profile;
  final int assignedStudentTotal;
}

/// Total de estudiantes asignados al orientador autenticado.
///
/// `GET /students` aplica en el servidor la institución y el `counselor_id`
/// de la sesión. El `total` de la página es el recuento fiable.
/// La gestión de altas/bajas de asignación es `GET|POST|PATCH /assignments`
/// (roles de administración); el orientador solo consulta las suyas.
final counselorDashboardProvider =
    FutureProvider.autoDispose<CounselorDashboardData>((ref) async {
  final profile = await ref.watch(authRepositoryProvider).currentProfile();
  if (profile.role != 'COUNSELOR') {
    throw AppException('No tienes permiso para ver este panel.');
  }
  final students = await ref.watch(studentRepositoryProvider).list(
        const StudentListQuery(page: 1, pageSize: 1),
      );
  return CounselorDashboardData(
    profile: profile,
    assignedStudentTotal: students.total,
  );
});
