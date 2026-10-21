import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../admin/presentation/providers/admin_dashboard_provider.dart';
import '../../domain/institution.dart';
import '../widgets/institution_form.dart';

class InstitutionEditScreen extends ConsumerWidget {
  const InstitutionEditScreen({super.key, required this.institutionId});

  final int institutionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(institutionDetailProvider(institutionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Editar institución')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is AppException
                        ? error.message
                        : FailureMapper.unexpectedMessage,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(
                      institutionDetailProvider(institutionId),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (institution) => InstitutionForm(
            key: ValueKey(
              '${institution.id}-${institution.name}-${institution.code}-${institution.status}',
            ),
            initial: institution,
            submitLabel: 'Guardar cambios',
            onSubmit: (InstitutionDraft draft) async {
              await ref
                  .read(institutionRepositoryProvider)
                  .update(institution.id, draft);
              ref.invalidate(institutionListProvider);
              ref.invalidate(adminDashboardProvider);
              ref.invalidate(institutionDetailProvider(institutionId));
              if (context.mounted) {
                context.go(RouteNames.adminInstitutions);
              }
            },
          ),
        ),
      ),
    );
  }
}
