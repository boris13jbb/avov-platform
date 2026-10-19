import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../../../admin/presentation/providers/admin_dashboard_provider.dart';
import '../../domain/institution.dart';
import '../widgets/institution_form.dart';

class InstitutionCreateScreen extends ConsumerWidget {
  const InstitutionCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear institución')),
      body: SafeArea(
        child: InstitutionForm(
          onSubmit: (InstitutionDraft draft) async {
            await ref.read(institutionRepositoryProvider).create(draft);
            ref.invalidate(institutionListProvider);
            ref.invalidate(adminDashboardProvider);
            ref.read(institutionPageProvider.notifier).state = 1;
            if (context.mounted) {
              context.go(RouteNames.adminInstitutions);
            }
          },
        ),
      ),
    );
  }
}
