import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/route_names.dart';
import '../../../admin/presentation/providers/admin_dashboard_provider.dart';
import '../../domain/institution.dart';
import '../widgets/institution_form.dart';
import '../../../../router/app_navigation.dart';
import '../../../../shared/widgets/internal_route_scope.dart';
import '../../../../shared/widgets/navigation_back_button.dart';

class InstitutionCreateScreen extends ConsumerWidget {
  const InstitutionCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InternalRouteScope(
        child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: NavigationBackButton.maybeOf(context),
        title: const Text('Crear institución'),
      ),
      body: SafeArea(
        child: InstitutionForm(
          onSubmit: (InstitutionDraft draft) async {
            await ref.read(institutionRepositoryProvider).create(draft);
            ref.invalidate(institutionListProvider);
            ref.invalidate(adminDashboardProvider);
            ref.read(institutionPageProvider.notifier).state = 1;
            if (context.mounted) {
              AppNavigation.completeTo(context, RouteNames.adminInstitutions);
            }
          },
        ),
      ),
    ));
  }
}
