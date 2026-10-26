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
import '../providers/admin_dashboard_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(adminDashboardProvider);

    return RootExitScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AVOV'),
          actions: const [SessionMenuButton()],
        ),
        body: SafeArea(
          child: overview.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AppStateView.error(
              message: error is AppException
                  ? error.message
                  : FailureMapper.unexpectedMessage,
              onRetry: () => ref.invalidate(adminDashboardProvider),
            ),
            data: (data) => _DashboardContent(data: data),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;
    final profile = data.profile;
    final fullName = '${profile.firstName} ${profile.lastName}'.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                title: 'Panel de superadministrador',
                subtitle: fullName.isEmpty ? profile.email : fullName,
                caption: profile.email,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (compact)
                Column(
                  children: [
                    AppMetricCard(
                      label: 'Instituciones',
                      value: '${data.institutionTotal}',
                      icon: Icons.apartment_outlined,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppMetricCard(
                      label: 'Usuarios',
                      value: '${data.userTotal}',
                      icon: Icons.people_outline,
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppMetricCard(
                        label: 'Instituciones',
                        value: '${data.institutionTotal}',
                        icon: Icons.apartment_outlined,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppMetricCard(
                        label: 'Usuarios',
                        value: '${data.userTotal}',
                        icon: Icons.people_outline,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.xl),
              if (data.institutionTotal == 0)
                const _EmptyInstitutions()
              else
                _ActionButton(
                  icon: Icons.apartment_outlined,
                  label: 'Gestionar instituciones',
                  onPressed: () => AppNavigation.open(
                    context,
                    RouteNames.adminInstitutions,
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              _ActionButton(
                icon: Icons.people_outline,
                label: 'Gestionar usuarios',
                onPressed: () =>
                    AppNavigation.open(context, RouteNames.adminUsers),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ActionButton(
                icon: Icons.school_outlined,
                label: 'Gestionar estudiantes',
                onPressed: () =>
                    AppNavigation.open(context, RouteNames.adminStudents),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ActionButton(
                icon: Icons.link_outlined,
                label: 'Gestionar asignaciones',
                onPressed: () =>
                    AppNavigation.open(context, RouteNames.adminAssignments),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ActionButton(
                icon: Icons.work_outline,
                label: 'Gestionar carreras',
                onPressed: () =>
                    AppNavigation.open(context, RouteNames.adminCareers),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ActionButton(
                icon: Icons.quiz_outlined,
                label: 'Gestionar preguntas RIASEC',
                onPressed: () =>
                    AppNavigation.open(context, RouteNames.adminQuestions),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ActionButton(
                icon: Icons.hub_outlined,
                label: 'Reconstruir índice vectorial',
                onPressed: () =>
                    AppNavigation.open(context, RouteNames.adminVectorRebuild),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ActionButton(
                icon: Icons.fact_check_outlined,
                label: 'Auditoría del sistema',
                onPressed: () =>
                    AppNavigation.open(context, RouteNames.adminAudit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _EmptyInstitutions extends StatelessWidget {
  const _EmptyInstitutions();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Todavía no hay instituciones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Cuando registres la primera institución, sus datos aparecerán aquí.',
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => AppNavigation.open(
                context,
                RouteNames.adminInstitutionNew,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Crear institución'),
            ),
          ],
        ),
      ),
    );
  }
}
