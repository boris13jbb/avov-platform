import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../router/app_navigation.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/root_exit_scope.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../providers/counselor_dashboard_provider.dart';

class CounselorDashboardScreen extends ConsumerWidget {
  const CounselorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(counselorDashboardProvider);
    return RootExitScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel del orientador'),
          actions: const [SessionMenuButton()],
        ),
        body: SafeArea(
          child: dashboard.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AppStateView.error(
              message: error is AppException
                  ? error.message
                  : FailureMapper.unexpectedMessage,
              onRetry: () => ref.invalidate(counselorDashboardProvider),
            ),
            data: (data) {
              final fullName =
                  '${data.profile.firstName} ${data.profile.lastName}'.trim();
              final institutionLabel = data.profile.institutionId == null
                  ? 'Tu sesión no tiene una institución asignada.'
                  : 'Institución asignada: identificador ${data.profile.institutionId}. '
                      'El nombre no está disponible para este rol.';
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                children: [
                  AppPageHeader(
                    title: fullName.isEmpty ? data.profile.email : fullName,
                    subtitle: data.profile.email,
                    caption: institutionLabel,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppMetricCard(
                    label: 'Estudiantes asignados',
                    value: '${data.assignedStudentTotal}',
                    icon: Icons.school_outlined,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => AppNavigation.open(
                        context,
                        RouteNames.counselorStudents,
                      ),
                      icon: const Icon(Icons.school_outlined),
                      label: const Text('Ver estudiantes asignados'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Orientación vocacional',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Desde la ficha de cada estudiante asignado puedes consultar '
                    'el historial de informes PDF, abrir el resultado de una '
                    'evaluación completada, ver recomendaciones de carreras y '
                    'registrar u actualizar observaciones.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'El test RIASEC lo inicia y responde el propio estudiante '
                    'en su espacio. Este panel no aplica evaluaciones en su '
                    'nombre.',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
