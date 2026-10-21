import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../admin/presentation/providers/admin_dashboard_provider.dart';
import '../../../institutions/domain/institution.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../../domain/managed_student.dart';
import '../providers/students_provider.dart';
import '../widgets/student_form.dart';

class StudentCreateScreen extends ConsumerWidget {
  const StudentCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operator = ref.watch(currentOperatorProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear estudiante')),
      body: SafeArea(
        child: operator.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CreateNotice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(currentOperatorProvider),
          ),
          data: (profile) {
            final routes = StudentAreaRoutes.forRole(profile.role);
            if (profile.role == 'INSTITUTION_ADMIN') {
              final institutionId = profile.institutionId;
              if (institutionId == null || routes == null) {
                return const _CreateNotice(
                  message:
                      'Tu sesión no tiene una institución asignada. No se puede crear el estudiante.',
                  onRetry: null,
                );
              }
              return _form(
                ref,
                context,
                institutions: const [],
                fixedInstitutionId: institutionId,
                listRoute: routes.list,
              );
            }
            return _CatalogStudentCreate(
              listRoute: routes?.list ?? RouteNames.adminStudents,
            );
          },
        ),
      ),
    );
  }
}

Widget _form(
  WidgetRef ref,
  BuildContext context, {
  required List<Institution> institutions,
  required String listRoute,
  int? fixedInstitutionId,
}) {
  return StudentForm(
    institutions: institutions,
    includePassword: true,
    fixedInstitutionId: fixedInstitutionId,
    onSubmit: (StudentDraft draft) async {
      await ref.read(studentRepositoryProvider).create(draft);
      ref.invalidate(studentListProvider);
      ref.invalidate(adminDashboardProvider);
      ref.read(studentPageProvider.notifier).state = 1;
      if (context.mounted) {
        context.go(listRoute);
      }
    },
  );
}

class _CatalogStudentCreate extends ConsumerWidget {
  const _CatalogStudentCreate({required this.listRoute});

  final String listRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institutions = ref.watch(institutionChoicesProvider);
    return institutions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _CreateNotice(
        message: error is AppException
            ? error.message
            : FailureMapper.unexpectedMessage,
        onRetry: () => ref.invalidate(institutionChoicesProvider),
      ),
      data: (items) => _form(
        ref,
        context,
        institutions: [
          for (final item in items)
            if (item.status == 'ACTIVE') item,
        ],
        listRoute: listRoute,
      ),
    );
  }
}

class _CreateNotice extends StatelessWidget {
  const _CreateNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

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
            if (onRetry != null)
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
