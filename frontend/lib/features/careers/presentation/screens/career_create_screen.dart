import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../../domain/career.dart';
import '../providers/career_provider.dart';
import '../widgets/career_form.dart';

class CareerCreateScreen extends ConsumerWidget {
  const CareerCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear carrera')),
      body: SafeArea(
        child: CareerForm(
          submitLabel: 'Crear carrera',
          onSubmit: (CareerDraft draft) async {
            await ref.read(careerRepositoryProvider).create(draft);
            ref.invalidate(careerListProvider);
            ref.read(careerPageProvider.notifier).state = 1;
            if (context.mounted) {
              context.go(RouteNames.adminCareers);
            }
          },
        ),
      ),
    );
  }
}
