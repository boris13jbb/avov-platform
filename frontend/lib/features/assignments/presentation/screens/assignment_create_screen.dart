import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/app_navigation.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/internal_route_scope.dart';
import '../../../../shared/widgets/navigation_back_button.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../../students/domain/managed_student.dart';
import '../../../users/domain/managed_user.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../providers/assignment_provider.dart';

class AssignmentCreateScreen extends ConsumerStatefulWidget {
  const AssignmentCreateScreen({super.key, this.preselectedStudentId});

  final int? preselectedStudentId;

  @override
  ConsumerState<AssignmentCreateScreen> createState() =>
      _AssignmentCreateScreenState();
}

class _AssignmentCreateScreenState
    extends ConsumerState<AssignmentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _studentId;
  int? _counselorId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _studentId = widget.preselectedStudentId;
  }

  /// Ajusta la selección al catálogo actual sin lanzar la aserción del dropdown.
  int? _reconcileSelection(int? selectedId, Iterable<int> availableIds) {
    if (selectedId == null) {
      return null;
    }
    return availableIds.contains(selectedId) ? selectedId : null;
  }

  void _scheduleSelectionSync({
    required int? nextStudentId,
    required int? nextCounselorId,
  }) {
    if (nextStudentId == _studentId && nextCounselorId == _counselorId) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _studentId = nextStudentId;
        _counselorId = nextCounselorId;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentChoicesForAssignmentProvider);
    final counselors = ref.watch(counselorChoicesForAssignmentProvider);

    return InternalRouteScope(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: NavigationBackButton.maybeOf(context),
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
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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

                  final effectiveStudentId = _reconcileSelection(
                    _studentId,
                    studentItems.map((ManagedStudent s) => s.id),
                  );
                  final effectiveCounselorId = _reconcileSelection(
                    _counselorId,
                    counselorItems.map((ManagedUser c) => c.id),
                  );
                  _scheduleSelectionSync(
                    nextStudentId: effectiveStudentId,
                    nextCounselorId: effectiveCounselorId,
                  );

                  final studentOptionKey = studentItems
                      .map((ManagedStudent s) => s.id)
                      .join(',');
                  final counselorOptionKey = counselorItems
                      .map((ManagedUser c) => c.id)
                      .join(',');

                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        DropdownButtonFormField<int>(
                          key: ValueKey<String>(
                            'student-$effectiveStudentId-$studentOptionKey',
                          ),
                          initialValue: effectiveStudentId,
                          decoration: const InputDecoration(
                            labelText: 'Estudiante',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final student in studentItems)
                              DropdownMenuItem<int>(
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
                          key: ValueKey<String>(
                            'counselor-$effectiveCounselorId-$counselorOptionKey',
                          ),
                          initialValue: effectiveCounselorId,
                          decoration: const InputDecoration(
                            labelText: 'Orientador',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final counselor in counselorItems)
                              DropdownMenuItem<int>(
                                value: counselor.id,
                                child: Text(counselor.fullName),
                              ),
                          ],
                          onChanged: _submitting
                              ? null
                              : (value) =>
                                  setState(() => _counselorId = value),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
      AppNavigation.completeTo(
        context,
        listHref ?? RouteNames.institutionAssignments,
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
