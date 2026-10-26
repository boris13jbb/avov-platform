import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/route_names.dart';
import '../../domain/career.dart';
import '../providers/career_provider.dart';
import '../widgets/career_form.dart';
import '../../../../router/app_navigation.dart';
import '../../../../shared/widgets/internal_route_scope.dart';
import '../../../../shared/widgets/navigation_back_button.dart';

class CareerCreateScreen extends ConsumerWidget {
  const CareerCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InternalRouteScope(
        child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: NavigationBackButton.maybeOf(context),
        title: const Text('Crear carrera'),
      ),
      body: SafeArea(
        child: CareerForm(
          submitLabel: 'Crear carrera',
          onSubmit: (CareerDraft draft) async {
            await ref.read(careerRepositoryProvider).create(draft);
            ref.invalidate(careerListProvider);
            ref.read(careerPageProvider.notifier).state = 1;
            if (context.mounted) {
              AppNavigation.completeTo(context, RouteNames.adminCareers);
            }
          },
        ),
      ),
    ));
  }
}
