import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../../../vocational/presentation/widgets/student_reports_history_section.dart';
import '../../domain/managed_student.dart';
import '../providers/students_provider.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(studentDetailProvider(studentId));
    final operator = ref.watch(currentOperatorProvider);
    final canManage = operator.maybeWhen(
          data: (profile) => canManageStudents(profile.role),
          orElse: () => false,
        );
    final operatorRole = operator.maybeWhen(
          data: (profile) => profile.role,
          orElse: () => null,
        );
    final isCounselor = operatorRole == 'COUNSELOR';

    return Scaffold(
      appBar: AppBar(title: const Text('Estudiante')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DetailNotice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(studentDetailProvider(studentId)),
          ),
          data: (student) {
            final isSuperAdmin = operator.maybeWhen(
              data: (profile) => profile.role == 'SUPER_ADMIN',
              orElse: () => false,
            );
            final assignHref = AssignmentAreaRoutes.createLocation(
              role: operatorRole,
              studentId: student.id,
            );
            if (!isSuperAdmin) {
              return _detailBody(
                context,
                ref,
                student,
                'Institución ${student.institutionId}',
                canManage,
                assignHref,
                isCounselor,
              );
            }
            return Consumer(
              builder: (context, ref, _) {
                final institutionName = ref.watch(institutionChoicesProvider).maybeWhen(
                      data: (items) {
                        for (final item in items) {
                          if (item.id == student.institutionId) {
                            return item.name;
                          }
                        }
                        return 'Institución ${student.institutionId}';
                      },
                      orElse: () => 'Institución ${student.institutionId}',
                    );
                return _detailBody(
                  context,
                  ref,
                  student,
                  institutionName,
                  canManage,
                  assignHref,
                  isCounselor,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

Widget _detailBody(
  BuildContext context,
  WidgetRef ref,
  ManagedStudent student,
  String institutionName,
  bool canManage,
  String? assignHref,
  bool counselorReviewEnabled,
) {
  return ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(student.fullName, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text(student.email),
      const SizedBox(height: 8),
      Text('Estado: ${student.statusLabel}'),
      Text('Institución: $institutionName'),
      Text('Identificación: ${student.identification}'),
      Text('Nacimiento: ${student.birthDate}'),
      Text('Género: ${student.genderLabel}'),
      Text('Curso: ${student.grade}'),
      if (student.parallel != null) Text('Paralelo: ${student.parallel}'),
      if (student.phone != null) Text('Teléfono: ${student.phone}'),
      if (student.representativeName != null)
        Text('Representante: ${student.representativeName}'),
      const SizedBox(height: 24),
      StudentReportsHistorySection(
        studentId: student.id,
        counselorReviewEnabled: counselorReviewEnabled,
      ),
      const SizedBox(height: 24),
      if (assignHref != null) ...[
        OutlinedButton.icon(
          onPressed: () => context.go(assignHref),
          icon: const Icon(Icons.link_outlined),
          label: const Text('Asignar orientador'),
        ),
        const SizedBox(height: 12),
      ],
      if (canManage)
        FilledButton(
          onPressed: () {
            final routes = ref.read(currentOperatorProvider).maybeWhen(
                  data: (profile) => StudentAreaRoutes.forRole(profile.role),
                  orElse: () => null,
                );
            if (routes != null) {
              context.go(routes.edit(student.id));
            }
          },
          child: const Text('Editar'),
        ),
    ],
  );
}

class _DetailNotice extends StatelessWidget {
  const _DetailNotice({required this.message, required this.onRetry});

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
