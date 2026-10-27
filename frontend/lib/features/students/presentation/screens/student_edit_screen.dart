import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../admin/presentation/providers/admin_dashboard_provider.dart';
import '../../../institutions/domain/institution.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../../domain/managed_student.dart';
import '../providers/students_provider.dart';
import '../widgets/student_form.dart';
import '../../../../router/app_navigation.dart';
import '../../../../shared/widgets/internal_route_scope.dart';
import '../../../../shared/widgets/navigation_back_button.dart';

class StudentEditScreen extends ConsumerWidget {
  const StudentEditScreen({super.key, required this.studentId});

  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(studentDetailProvider(studentId));

    return InternalRouteScope(
        child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: NavigationBackButton.maybeOf(context),
        title: const Text('Editar estudiante'),
      ),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _EditNotice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(studentDetailProvider(studentId)),
          ),
          data: (student) {
            final operator = ref.watch(currentOperatorProvider);
            final routes = operator.maybeWhen(
              data: (profile) => StudentAreaRoutes.forRole(profile.role),
              orElse: () => null,
            );
            final isSuperAdmin = operator.maybeWhen(
              data: (profile) => profile.role == 'SUPER_ADMIN',
              orElse: () => false,
            );
            if (!isSuperAdmin) {
              return _editForm(
                ref,
                context,
                student: student,
                institutions: const [],
                fixedInstitutionId: student.institutionId,
                listRoute: routes?.list ?? RouteNames.institutionStudents,
              );
            }
            return _CatalogStudentEdit(
              student: student,
              listRoute: routes?.list ?? RouteNames.adminStudents,
            );
          },
        ),
      ),
    ));
  }
}

Widget _editForm(
  WidgetRef ref,
  BuildContext context, {
  required ManagedStudent student,
  required List<Institution> institutions,
  required String listRoute,
  int? fixedInstitutionId,
}) {
  return StudentForm(
    key: ValueKey('${student.id}-${student.email}-${student.grade}'),
    initial: student,
    institutions: institutions,
    lockInstitution: true,
    fixedInstitutionId: fixedInstitutionId,
    submitLabel: 'Guardar cambios',
    onSubmit: (StudentDraft draft) async {
      await ref.read(studentRepositoryProvider).update(student.id, draft);
      ref.invalidate(studentListProvider);
      ref.invalidate(studentDetailProvider(student.id));
      ref.invalidate(adminDashboardProvider);
      if (context.mounted) {
        AppNavigation.completeTo(context, listRoute);
      }
    },
  );
}

List<Institution> _choices(List<Institution> source, ManagedStudent student) {
  final choices = <Institution>[
    for (final item in source)
      if (item.status == 'ACTIVE' || item.id == student.institutionId) item,
  ];
  if (choices.any((item) => item.id == student.institutionId)) {
    return choices;
  }
  return [
    ...choices,
    Institution(
      id: student.institutionId,
      name: 'Institución ${student.institutionId}',
      code: '-',
      province: '-',
      city: '-',
      status: 'ACTIVE',
    ),
  ];
}

class _CatalogStudentEdit extends ConsumerWidget {
  const _CatalogStudentEdit({required this.student, required this.listRoute});

  final ManagedStudent student;
  final String listRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institutions = ref.watch(institutionChoicesProvider);
    return institutions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _EditNotice(
        message: error is AppException
            ? error.message
            : FailureMapper.unexpectedMessage,
        onRetry: () => ref.invalidate(institutionChoicesProvider),
      ),
      data: (items) => _editForm(
        ref,
        context,
        student: student,
        institutions: _choices(items, student),
        listRoute: listRoute,
      ),
    );
  }
}

class _EditNotice extends StatelessWidget {
  const _EditNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
