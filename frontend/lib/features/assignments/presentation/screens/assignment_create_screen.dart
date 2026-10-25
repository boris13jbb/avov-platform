import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../providers/assignment_provider.dart';

class AssignmentCreateScreen extends ConsumerStatefulWidget {
  const AssignmentCreateScreen({super.key, this.preselectedStudentId});

  final int? preselectedStudentId;

  @override
  ConsumerState<AssignmentCreateScreen> createState() =>
      _AssignmentCreateScreenState();
}

class _AssignmentCreateScreenState extends ConsumerState<AssignmentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _studentId;
  int? _counselorId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _studentId = widget.preselectedStudentId;
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentChoicesForAssignmentProvider);
    final counselors = ref.watch(counselorChoicesForAssignmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva asignación'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: students.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorBody(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () {
              ref.invalidate(studentChoicesForAssignmentProvider);
              ref.invalidate(counselorChoicesForAssignmentProvider);
            },
          ),
          data: (studentItems) {
            return counselors.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorBody(
                message: error is AppException
                    ? error.message
                    : FailureMapper.unexpectedMessage,
                onRetry: () =>
                    ref.invalidate(counselorChoicesForAssignmentProvider),
              ),
              data: (counselorItems) {
                if (studentItems.isEmpty || counselorItems.isEmpty) {
                  return _ErrorBody(
                    message: studentItems.isEmpty
                        ? 'No hay estudiantes activos para asignar.'
                        : 'No hay orientadores activos para asignar.',
                    onRetry: () {
                      ref.invalidate(studentChoicesForAssignmentProvider);
                      ref.invalidate(counselorChoicesForAssignmentProvider);
                    },
                  );
                }
                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      DropdownButtonFormField<int>(
                        key: ValueKey<int?>(_studentId),
                        initialValue: _studentId != null &&
                                studentItems.any((s) => s.id == _studentId)
                            ? _studentId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Estudiante',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final student in studentItems)
                            DropdownMenuItem(
                              value: student.id,
                              child: Text(
                                '${student.fullName} (${student.identification})',
                              ),
                            ),
                        ],
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => _studentId = value),
                        validator: (value) => value == null
                            ? 'Selecciona un estudiante'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        key: ValueKey<int?>(_counselorId),
                        initialValue: _counselorId != null &&
                                counselorItems.any((c) => c.id == _counselorId)
                            ? _counselorId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Orientador',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final counselor in counselorItems)
                            DropdownMenuItem(
                              value: counselor.id,
                              child: Text(counselor.fullName),
                            ),
                        ],
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => _counselorId = value),
                        validator: (value) => value == null
                            ? 'Selecciona un orientador'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Asignar'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final studentId = _studentId;
    final counselorId = _counselorId;
    if (studentId == null || counselorId == null) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(assignmentRepositoryProvider).create(
            studentId: studentId,
            counselorId: counselorId,
          );
      ref.invalidate(assignmentListProvider);
      ref.invalidate(studentAssignmentListProvider(studentId));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asignación creada correctamente'),
        ),
      );
      final listHref = ref.read(currentOperatorProvider).maybeWhen(
            data: (profile) => AssignmentAreaRoutes.forRole(profile.role)?.list,
            orElse: () => null,
          );
      context.go(listHref ?? RouteNames.institutionAssignments);
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
        setState(() => _submitting = false);
      }
    }
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

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
