import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../../domain/counselor_assignment.dart';
import '../providers/assignment_provider.dart';

class AssignmentListScreen extends ConsumerStatefulWidget {
  const AssignmentListScreen({super.key});

  @override
  ConsumerState<AssignmentListScreen> createState() =>
      _AssignmentListScreenState();
}

class _AssignmentListScreenState extends ConsumerState<AssignmentListScreen> {
  bool _busyId = false;

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(assignmentListProvider);
    final page = ref.watch(assignmentPageProvider);
    final statusFilter = ref.watch(assignmentStatusFilterProvider);
    final routes = ref.watch(currentOperatorProvider).maybeWhen(
          data: (profile) => AssignmentAreaRoutes.forRole(profile.role),
          orElse: () => null,
        );
    final canManage = routes != null;
    final createHref = routes?.create;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignaciones'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: statusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'ACTIVE',
                          child: Text('Activas'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'INACTIVE',
                          child: Text('Inactivas'),
                        ),
                      ],
                      onChanged: (value) {
                        ref.read(assignmentStatusFilterProvider.notifier).state =
                            value;
                        ref.read(assignmentPageProvider.notifier).state = 1;
                      },
                    ),
                  ),
                  if (createHref != null) ...[
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => context.go(createHref),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('Nueva'),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: list.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => _Notice(
                  message: error is AppException
                      ? error.message
                      : FailureMapper.unexpectedMessage,
                  actionLabel: 'Reintentar',
                  onPressed: () => ref.invalidate(assignmentListProvider),
                ),
                data: (result) {
                  if (result.total == 0) {
                    return _Notice(
                      message: 'No hay asignaciones para mostrar.',
                      actionLabel:
                          createHref != null ? 'Crear asignación' : 'Reintentar',
                      onPressed: createHref != null
                          ? () => context.go(createHref)
                          : () => ref.invalidate(assignmentListProvider),
                    );
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: result.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = result.items[index];
                            return _AssignmentTile(
                              assignment: item,
                              canManage: canManage,
                              busy: _busyId,
                              onToggle: () => _toggleStatus(item),
                            );
                          },
                        ),
                      ),
                      if (result.pages > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: page > 1
                                    ? () => ref
                                        .read(assignmentPageProvider.notifier)
                                        .state = page - 1
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Text('Página $page de ${result.pages}'),
                              IconButton(
                                onPressed: page < result.pages
                                    ? () => ref
                                        .read(assignmentPageProvider.notifier)
                                        .state = page + 1
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(CounselorAssignment assignment) async {
    if (_busyId) {
      return;
    }
    final nextStatus = assignment.isActive ? 'INACTIVE' : 'ACTIVE';
    final confirmed = await ConfirmDialog.show(
      context,
      title: assignment.isActive
          ? 'Desactivar asignación'
          : 'Reactivar asignación',
      message: assignment.isActive
          ? 'El orientador dejará de ver a este estudiante.'
          : 'El orientador volverá a ver a este estudiante.',
      confirmLabel: assignment.isActive ? 'Desactivar' : 'Reactivar',
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busyId = true);
    try {
      await ref.read(assignmentRepositoryProvider).updateStatus(
            assignmentId: assignment.id,
            status: nextStatus,
          );
      ref.invalidate(assignmentListProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextStatus == 'INACTIVE'
                ? 'Asignación desactivada correctamente'
                : 'Asignación reactivada correctamente',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is AppException
          ? error.message
          : FailureMapper.unexpectedMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _busyId = false);
      }
    }
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({
    required this.assignment,
    required this.canManage,
    required this.busy,
    required this.onToggle,
  });

  final CounselorAssignment assignment;
  final bool canManage;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final studentLabel =
        assignment.studentName ?? 'Estudiante #${assignment.studentId}';
    final counselorLabel =
        assignment.counselorName ?? 'Orientador #${assignment.counselorId}';
    return Card(
      child: ListTile(
        title: Text(studentLabel),
        subtitle: Text(
          '$counselorLabel\nEstado: ${assignment.statusLabel}',
        ),
        isThreeLine: true,
        trailing: canManage
            ? TextButton(
                onPressed: busy ? null : onToggle,
                child: Text(assignment.isActive ? 'Desactivar' : 'Reactivar'),
              )
            : null,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

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
            FilledButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
