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
import '../providers/institution_dashboard_provider.dart';

class InstitutionDashboardScreen extends ConsumerWidget {
  const InstitutionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(institutionDashboardProvider);
    return RootExitScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de la institución'),
          actions: const [SessionMenuButton()],
        ),
        body: SafeArea(
          child: dashboard.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AppStateView.error(
              message: error is AppException
                  ? error.message
                  : FailureMapper.unexpectedMessage,
              onRetry: () => ref.invalidate(institutionDashboardProvider),
            ),
            data: (data) {
              final compact = MediaQuery.sizeOf(context).width < 700;
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
                  if (compact)
                    Column(
                      children: [
                        AppMetricCard(
                          label: 'Estudiantes',
                          value: '${data.studentTotal}',
                          icon: Icons.school_outlined,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppMetricCard(
                          label: 'Orientadores',
                          value: '${data.counselorTotal}',
                          icon: Icons.support_agent_outlined,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: AppMetricCard(
                            label: 'Estudiantes',
                            value: '${data.studentTotal}',
                            icon: Icons.school_outlined,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: AppMetricCard(
                            label: 'Orientadores',
                            value: '${data.counselorTotal}',
                            icon: Icons.support_agent_outlined,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => AppNavigation.open(
                        context,
                        RouteNames.institutionStudents,
                      ),
                      icon: const Icon(Icons.school_outlined),
                      label: const Text('Gestionar estudiantes'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => AppNavigation.open(
                        context,
                        RouteNames.institutionCounselors,
                      ),
                      icon: const Icon(Icons.support_agent_outlined),
                      label: const Text('Gestionar orientadores'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => AppNavigation.open(
                        context,
                        RouteNames.institutionAssignments,
                      ),
                      icon: const Icon(Icons.link_outlined),
                      label: const Text('Gestionar asignaciones'),
                    ),
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
