import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../domain/career.dart';
import '../providers/career_provider.dart';
import '../widgets/career_form.dart';

class CareerEditScreen extends ConsumerWidget {
  const CareerEditScreen({super.key, required this.careerId});

  final int careerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(careerDetailProvider(careerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Editar carrera')),
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
                    onPressed: () =>
                        ref.invalidate(careerDetailProvider(careerId)),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (career) => CareerForm(
            key: ValueKey('${career.id}-${career.name}-${career.status}'),
            initial: career,
            submitLabel: 'Guardar cambios',
            onSubmit: (CareerDraft draft) async {
              await ref
                  .read(careerRepositoryProvider)
                  .update(career.id, draft);
              ref.invalidate(careerListProvider);
              ref.invalidate(careerDetailProvider(careerId));
              if (context.mounted) {
                context.go(RouteNames.adminCareers);
              }
            },
          ),
        ),
      ),
    );
  }
}
