import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../admin/presentation/providers/admin_dashboard_provider.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../../institutions/domain/institution.dart';
import '../../../users/domain/managed_user.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../../domain/managed_student.dart';
import '../providers/students_provider.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operator = ref.watch(currentOperatorProvider);
    final isSuperAdmin = operator.maybeWhen(
      data: (profile) => profile.role == 'SUPER_ADMIN',
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudiantes'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: isSuperAdmin
            ? const _SuperAdminStudentBody()
            : const _StudentListBody(
                showInstitutionFilter: false,
                institutionNames: {},
              ),
      ),
    );
  }
}

/// Mantiene el catálogo de instituciones vivo mientras el listado recarga.
/// Solo lo monta un superadministrador; el administrador institucional no llama a `/institutions`.
class _SuperAdminStudentBody extends ConsumerWidget {
  const _SuperAdminStudentBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institutionNames = ref.watch(institutionChoicesProvider).maybeWhen(
          data: (items) => {for (final item in items) item.id: item.name},
          orElse: () => const <int, String>{},
        );
    return _StudentListBody(
      showInstitutionFilter: true,
      institutionNames: institutionNames,
    );
  }
}

class _StudentListBody extends ConsumerWidget {
  const _StudentListBody({
    required this.showInstitutionFilter,
    required this.institutionNames,
  });

  final bool showInstitutionFilter;
  final Map<int, String> institutionNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(studentListProvider);
    final page = ref.watch(studentPageProvider);
    final operator = ref.watch(currentOperatorProvider);
    final canManage = operator.maybeWhen(
      data: (profile) => canManageStudents(profile.role),
      orElse: () => false,
    );
    final routes = operator.maybeWhen(
      data: (profile) => StudentAreaRoutes.forRole(profile.role),
      orElse: () => null,
    );

    return list.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Notice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            actionLabel: 'Reintentar',
            onPressed: () => ref.invalidate(studentListProvider),
          ),
          data: (result) {
            final filtering = ref.watch(studentSearchProvider).isNotEmpty ||
                ref.watch(studentInstitutionFilterProvider) != null ||
                ref.watch(studentStatusFilterProvider) != null ||
                ref.watch(studentGradeFilterProvider).isNotEmpty ||
                ref.watch(studentGenderFilterProvider) != null;
            if (result.total == 0 && !filtering) {
              return _Notice(
                message: 'Todavía no hay estudiantes.',
                actionLabel: canManage && routes != null ? 'Crear estudiante' : 'Actualizar',
                onPressed: canManage && routes != null
                    ? () => context.go(routes.create)
                    : () => ref.invalidate(studentListProvider),
              );
            }
            return _studentColumn(
              ref,
              context,
              result: result,
              page: page,
              canManage: canManage,
              routes: routes,
              isSuperAdmin: showInstitutionFilter,
              institutionNames: institutionNames,
            );
          },
        );
  }
}

Widget _studentColumn(
  WidgetRef ref,
  BuildContext context, {
  required ManagedStudentPage result,
  required int page,
  required bool canManage,
  required StudentAreaRoutes? routes,
  required bool isSuperAdmin,
  required Map<int, String> institutionNames,
}) {
  return Column(
              children: [
                _Filters(canManage: canManage, routes: routes, showInstitutionFilter: isSuperAdmin),
                Expanded(
                  child: result.items.isEmpty
                      ? const Center(
                          child: Text(
                            'Todavía no hay estudiantes que coincidan con la búsqueda.',
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: result.items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final student = result.items[index];
                            return _StudentTile(
                              student: student,
                              institutionName:
                                  institutionNames[student.institutionId] ??
                                      'Institución ${student.institutionId}',
                              canManage: canManage,
                              routes: routes,
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
                              ? () => ref.read(studentPageProvider.notifier).state =
                                  page - 1
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Página $page de ${result.pages}'),
                        IconButton(
                          onPressed: page < result.pages
                              ? () => ref.read(studentPageProvider.notifier).state =
                                  page + 1
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
              ],
            );
}

class _Filters extends ConsumerWidget {
  const _Filters({
    required this.canManage,
    required this.routes,
    required this.showInstitutionFilter,
  });

  final bool canManage;
  final StudentAreaRoutes? routes;
  final bool showInstitutionFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institutions = showInstitutionFilter
        ? ref.watch(institutionChoicesProvider).maybeWhen(
              data: (items) => items,
              orElse: () => const <Institution>[],
            )
        : const <Institution>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              key: const Key('student-search'),
              decoration: const InputDecoration(
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                final term = value.trim();
                ref.read(studentSearchProvider.notifier).state =
                    term.length > 100 ? term.substring(0, 100) : term;
                ref.read(studentPageProvider.notifier).state = 1;
              },
            ),
          ),
          if (showInstitutionFilter)
            SizedBox(
            width: 220,
            child: DropdownButtonFormField<int?>(
              key: const Key('student-institution-filter'),
              initialValue: ref.watch(studentInstitutionFilterProvider),
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Institución'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todas las instituciones'),
                ),
                for (final institution in institutions)
                  DropdownMenuItem<int?>(
                    value: institution.id,
                    child: Text(institution.name),
                  ),
              ],
              onChanged: (value) {
                ref.read(studentInstitutionFilterProvider.notifier).state = value;
                ref.read(studentPageProvider.notifier).state = 1;
              },
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String?>(
              key: const Key('student-status-filter'),
              initialValue: ref.watch(studentStatusFilterProvider),
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todos los estados'),
                ),
                for (final status in userStatuses)
                  DropdownMenuItem(
                    value: status,
                    child: Text(userStatusLabel(status)),
                  ),
              ],
              onChanged: (value) {
                ref.read(studentStatusFilterProvider.notifier).state = value;
                ref.read(studentPageProvider.notifier).state = 1;
              },
            ),
          ),
          SizedBox(
            width: 160,
            child: TextField(
              key: const Key('student-grade-filter'),
              decoration: const InputDecoration(labelText: 'Curso'),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                final term = value.trim();
                ref.read(studentGradeFilterProvider.notifier).state =
                    term.length > 20 ? term.substring(0, 20) : term;
                ref.read(studentPageProvider.notifier).state = 1;
              },
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String?>(
              key: const Key('student-gender-filter'),
              initialValue: ref.watch(studentGenderFilterProvider),
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Género'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                for (final gender in studentGenders)
                  DropdownMenuItem(
                    value: gender,
                    child: Text(studentGenderLabel(gender)),
                  ),
              ],
              onChanged: (value) {
                ref.read(studentGenderFilterProvider.notifier).state = value;
                ref.read(studentPageProvider.notifier).state = 1;
              },
            ),
          ),
          if (canManage && routes != null)
            FilledButton.icon(
              onPressed: () => context.go(routes!.create),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Crear estudiante'),
            ),
        ],
      ),
    );
  }
}

class _StudentTile extends ConsumerStatefulWidget {
  const _StudentTile({
    required this.student,
    required this.institutionName,
    required this.canManage,
    required this.routes,
  });

  final ManagedStudent student;
  final String institutionName;
  final bool canManage;
  final StudentAreaRoutes? routes;

  @override
  ConsumerState<_StudentTile> createState() => _StudentTileState();
}

class _StudentTileState extends ConsumerState<_StudentTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.fullName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(student.statusLabel),
            const SizedBox(height: 8),
            Text(
              '${student.email} · ${widget.institutionName} · Curso ${student.grade}',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _busy || widget.routes == null
                      ? null
                      : () => context.go(widget.routes!.detail(student.id)),
                  child: const Text('Ver'),
                ),
                if (widget.canManage)
                  OutlinedButton(
                    onPressed: _busy || widget.routes == null
                        ? null
                        : () => context.go(widget.routes!.edit(student.id)),
                    child: const Text('Editar'),
                  ),
                if (widget.canManage && student.isActive) ...[
                  FilledButton.tonal(
                    onPressed: _busy ? null : () => _setStatus('INACTIVE'),
                    child: const Text('Desactivar'),
                  ),
                  FilledButton.tonal(
                    onPressed: _busy ? null : () => _setStatus('BLOCKED'),
                    child: const Text('Bloquear'),
                  ),
                ],
                if (widget.canManage && !student.isActive)
                  FilledButton.tonal(
                    onPressed: _busy ? null : () => _setStatus('ACTIVE'),
                    child: const Text('Activar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setStatus(String status) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final copy = _statusCopy(status);
    final confirmed = await ConfirmDialog.show(
      context,
      title: copy.title,
      message: copy.message,
      confirmLabel: copy.confirm,
    );
    if (!confirmed || !mounted) {
      if (mounted) {
        setState(() => _busy = false);
      }
      return;
    }
    try {
      await ref.read(studentRepositoryProvider).updateStatus(widget.student.id, status);
      ref.invalidate(studentListProvider);
      ref.invalidate(studentDetailProvider(widget.student.id));
      ref.invalidate(adminDashboardProvider);
    } on AppException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError(FailureMapper.unexpectedMessage);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

({String title, String message, String confirm}) _statusCopy(String status) {
  switch (status) {
    case 'INACTIVE':
      return (
        title: 'Desactivar estudiante',
        message:
            'La cuenta quedará inactiva y no podrá iniciar sesión. El estudiante no se elimina.',
        confirm: 'Desactivar',
      );
    case 'BLOCKED':
      return (
        title: 'Bloquear estudiante',
        message:
            'La cuenta quedará bloqueada y no podrá iniciar sesión. El estudiante no se elimina.',
        confirm: 'Bloquear',
      );
    default:
      return (
        title: 'Activar estudiante',
        message: 'La cuenta volverá a estar activa y podrá iniciar sesión.',
        confirm: 'Activar',
      );
  }
}
