import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../../domain/question.dart';
import '../providers/question_provider.dart';
import '../widgets/question_form.dart';

class QuestionCreateScreen extends ConsumerWidget {
  const QuestionCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear pregunta')),
      body: SafeArea(
        child: QuestionForm(
          submitLabel: 'Crear pregunta',
          onSubmit: (QuestionDraft draft) async {
            await ref.read(questionRepositoryProvider).create(draft);
            ref.invalidate(questionListProvider);
            ref.invalidate(questionCategoryChoicesProvider);
            ref.read(questionPageProvider.notifier).state = 1;
            if (context.mounted) {
              context.go(RouteNames.adminQuestions);
            }
          },
        ),
      ),
    );
  }
}
