import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/route_names.dart';
import '../../domain/question.dart';
import '../providers/question_provider.dart';
import '../widgets/question_form.dart';
import '../../../../router/app_navigation.dart';
import '../../../../shared/widgets/internal_route_scope.dart';
import '../../../../shared/widgets/navigation_back_button.dart';

class QuestionCreateScreen extends ConsumerWidget {
  const QuestionCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InternalRouteScope(
        child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: NavigationBackButton.maybeOf(context),
        title: const Text('Crear pregunta'),
      ),
      body: SafeArea(
        child: QuestionForm(
          submitLabel: 'Crear pregunta',
          onSubmit: (QuestionDraft draft) async {
            await ref.read(questionRepositoryProvider).create(draft);
            ref.invalidate(questionListProvider);
            ref.invalidate(questionCategoryChoicesProvider);
            ref.read(questionPageProvider.notifier).state = 1;
            if (context.mounted) {
              AppNavigation.completeTo(context, RouteNames.adminQuestions);
            }
          },
        ),
      ),
    ));
  }
}
