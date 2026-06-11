import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/managed_user.dart';
import '../../../../core/models/student.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../../../institutions/presentation/providers/institution_provider.dart';
import '../../domain/student_management_config.dart';
import '../providers/student_provider.dart';
import '../widgets/assign_counselor_dialog.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({
    super.key,
    required this.config,
    required this.studentId,
  });

  final StudentManagementConfig config;
  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(studentDetailProvider(studentId));
    final mutationState = ref.watch(studentMutationProvider);

    return DashboardShell(
      title: config.detailTitle,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: detailAsync.when(
        data: (student) {
          final institutionAsync =
              ref.watch(institutionDetailProvider(student.institutionId));

          final institutionName = institutionAsync.when(
            data: (institution) => '${institution.name} (${institution.code})',
            loading: () => 'Cargando institución...',
            error: (_, __) => 'Institución #${student.institutionId}',
          );

          return _DetailBody(
            student: student,
            institutionName: institutionName,
            isProcessing: mutationState.isLoading,
            canAssignCounselor: config.canAssignCounselor,
            onEdit: () => context.push(config.editRoute(student.id)),
            onAssignCounselor: config.canAssignCounselor
                ? () async {
                    final counselorId = await AssignCounselorDialog.show(
                      context,
                      studentName: student.user.fullName,
                    );
                    if (counselorId == null || !context.mounted) return;

                    final success = await ref
                        .read(studentMutationProvider.notifier)
                        .assignCounselor(
                          studentId: student.id,
                          counselorId: counselorId,
                        );

                    if (!context.mounted) return;

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Orientador asignado correctamente'),
                        ),
                      );
                    } else {
                      final error = ref.read(studentMutationProvider).error;
                      final message = error is AppException
                          ? error.message
                          : 'No se pudo asignar el orientador';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    }
                  }
                : null,
            onStatusChange: (status) async {
              final label = UserAccountStatus.fromApi(status).label;
              final confirmed = await ConfirmDialog.show(
                context,
                title: 'Cambiar estado',
                message:
                    '¿Deseas cambiar el estado de "${student.user.fullName}" a $label?',
                confirmLabel: 'Confirmar',
              );
              if (!confirmed || !context.mounted) return;

              final success = await ref
                  .read(studentMutationProvider.notifier)
                  .updateStatus(student.id, status);

              if (!context.mounted) return;

              if (success) {
                ref.invalidate(studentDetailProvider(studentId));
                ref.invalidate(studentListProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Estado actualizado')),
                );
              } else {
                final error = ref.read(studentMutationProvider).error;
                final message = error is AppException
                    ? error.message
                    : 'No se pudo actualizar el estado';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No se pudo cargar el estudiante'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(studentDetailProvider(studentId)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.student,
    required this.institutionName,
    required this.isProcessing,
    required this.canAssignCounselor,
    required this.onEdit,
    required this.onAssignCounselor,
    required this.onStatusChange,
  });

  final ManagedStudent student;
  final String institutionName;
  final bool isProcessing;
  final bool canAssignCounselor;
  final VoidCallback onEdit;
  final VoidCallback? onAssignCounselor;
  final ValueChanged<String> onStatusChange;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isActive = student.user.status == UserAccountStatus.active;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          student.user.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        label: Text(student.user.status.label),
                        backgroundColor: isActive
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(label: 'Correo', value: student.user.email),
                  _InfoRow(label: 'Identificación', value: student.identification),
                  _InfoRow(label: 'Institución', value: institutionName),
                  _InfoRow(
                    label: 'Fecha nacimiento',
                    value: dateFormat.format(student.birthDate),
                  ),
                  _InfoRow(label: 'Género', value: student.gender.label),
                  _InfoRow(
                    label: 'Grado',
                    value:
                        '${student.grade}${student.parallel != null ? " - ${student.parallel}" : ""}',
                  ),
                  _InfoRow(label: 'Teléfono', value: student.user.phone ?? '—'),
                  _InfoRow(
                    label: 'Representante',
                    value: student.representativeName ?? '—',
                  ),
                  _InfoRow(
                    label: 'Tel. representante',
                    value: student.representativePhone ?? '—',
                  ),
                  _InfoRow(
                    label: 'Email representante',
                    value: student.representativeEmail ?? '—',
                  ),
                  _InfoRow(
                    label: 'Registrado',
                    value: dateTimeFormat.format(student.createdAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isProcessing ? null : onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar estudiante'),
            ),
          ),
          if (canAssignCounselor && onAssignCounselor != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isProcessing ? null : onAssignCounselor,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Asignar orientador'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Cambiar estado', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UserAccountStatus.values.map((status) {
              final selected = student.user.status == status;
              return FilterChip(
                label: Text(status.label),
                selected: selected,
                onSelected: selected || isProcessing
                    ? null
                    : (_) => onStatusChange(status.apiValue),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
