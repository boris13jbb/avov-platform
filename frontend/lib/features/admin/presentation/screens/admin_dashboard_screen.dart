import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../providers/admin_dashboard_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(adminDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AVOV'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: overview.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DashboardMessage(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(adminDashboardProvider),
          ),
          data: (data) => _DashboardContent(data: data),
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
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel de superadministrador',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                fullName.isEmpty ? profile.email : fullName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                profile.email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (compact)
                Column(
                  children: [
                    _MetricCard(
                      label: 'Instituciones',
                      value: '${data.institutionTotal}',
                    ),
                    const SizedBox(height: 16),
                    _MetricCard(
                      label: 'Usuarios',
                      value: '${data.userTotal}',
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Instituciones',
                        value: '${data.institutionTotal}',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MetricCard(
                        label: 'Usuarios',
                        value: '${data.userTotal}',
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              if (data.institutionTotal == 0)
                const _EmptyInstitutions()
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => context.go(RouteNames.adminInstitutions),
                    icon: const Icon(Icons.apartment_outlined),
                    label: const Text('Gestionar instituciones'),
                  ),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => context.go(RouteNames.adminUsers),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Gestionar usuarios'),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => context.go(RouteNames.adminStudents),
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Gestionar estudiantes'),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Módulos pendientes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Carreras, preguntas RIASEC y auditoría '
                'aún no tienen pantalla. Esas secciones no aparecen como acciones.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Todavía no hay instituciones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando registres la primera institución, sus datos aparecerán aquí.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go(RouteNames.adminInstitutionNew),
              icon: const Icon(Icons.add),
              label: const Text('Crear institución'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.message,
    required this.onRetry,
  });

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
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
