import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../domain/question.dart';
import '../providers/question_provider.dart';
import '../widgets/question_form.dart';
import '../../../../router/app_navigation.dart';
import '../../../../shared/widgets/internal_route_scope.dart';
import '../../../../shared/widgets/navigation_back_button.dart';

class QuestionEditScreen extends ConsumerWidget {
  const QuestionEditScreen({super.key, required this.questionId});

  final int questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(questionDetailProvider(questionId));

    return InternalRouteScope(
        child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: NavigationBackButton.maybeOf(context),
        title: const Text('Editar pregunta'),
      ),
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
                        ref.invalidate(questionDetailProvider(questionId)),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (question) => QuestionForm(
            key: ValueKey(
              '${question.id}-${question.orderNumber}-${question.status}',
            ),
            initial: question,
            submitLabel: 'Guardar cambios',
            onSubmit: (QuestionDraft draft) async {
              await ref
                  .read(questionRepositoryProvider)
                  .update(question.id, draft);
              ref.invalidate(questionListProvider);
              ref.invalidate(questionDetailProvider(questionId));
              ref.invalidate(questionCategoryChoicesProvider);
              if (context.mounted) {
                AppNavigation.completeTo(context, RouteNames.adminQuestions);
              }
            },
          ),
        ),
      ),
    ));
  }
}
