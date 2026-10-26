import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/responsive_breakpoints.dart';
import '../../features/auth/presentation/widgets/session_menu_button.dart';
import '../../router/app_navigation.dart';
import '../../router/route_names.dart';
import 'internal_route_scope.dart';
import 'root_exit_scope.dart';

enum StudentSection { home, test, results, assistant, profile }

/// Barra y menú del estudiante.
///
/// En pantallas menores a escritorio el menú es un panel lateral.
/// En escritorio permanece visible. Cerrar sesión sigue en la barra.
class StudentScaffold extends StatelessWidget {
  const StudentScaffold({
    super.key,
    required this.title,
    required this.section,
    required this.body,
  });

  final String title;
  final StudentSection section;
  final Widget body;

  static const sections = <StudentSection, _StudentLink>{
    StudentSection.home: _StudentLink(
      'Inicio',
      Icons.home_outlined,
      Icons.home,
      RouteNames.studentDashboard,
    ),
    StudentSection.test: _StudentLink(
      'Test vocacional',
      Icons.quiz_outlined,
      Icons.quiz,
      RouteNames.studentTestHome,
    ),
    StudentSection.results: _StudentLink(
      'Resultados',
      Icons.assessment_outlined,
      Icons.assessment,
      RouteNames.studentResults,
    ),
    StudentSection.assistant: _StudentLink(
      'Asistente IA',
      Icons.smart_toy_outlined,
      Icons.smart_toy,
      RouteNames.studentAssistant,
    ),
    StudentSection.profile: _StudentLink(
      'Perfil',
      Icons.person_outline,
      Icons.person,
      RouteNames.studentProfile,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final desktop =
        ResponsiveBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    final showBack = section != StudentSection.home;
    final showMenu = !desktop;
    final scaffold = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: showBack && showMenu ? 112 : 56,
        leading: Builder(
          builder: (barContext) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showBack)
                  IconButton(
                    tooltip: 'Volver',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => AppNavigation.back(barContext),
                  ),
                if (showMenu)
                  IconButton(
                    tooltip: 'Abrir menú',
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(barContext).openDrawer(),
                  ),
              ],
            );
          },
        ),
        title: Text(title),
        actions: const [SessionMenuButton()],
      ),
      drawer: showMenu ? _menu(context, closeOnSelect: true) : null,
      body: desktop
          ? Row(
              children: [
                _rail(context),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
    );
    if (section == StudentSection.home) {
      return RootExitScope(child: scaffold);
    }
    return InternalRouteScope(child: scaffold);
  }

  Widget _rail(BuildContext context) {
    final selected = StudentSection.values.indexOf(section);
    return NavigationRail(
      selectedIndex: selected,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (index) {
        _open(context, sections[StudentSection.values[index]]!.route);
      },
      destinations: [
        for (final section in StudentSection.values)
          NavigationRailDestination(
            icon: Icon(sections[section]!.icon),
            selectedIcon: Icon(sections[section]!.selectedIcon),
            label: Text(sections[section]!.label),
          ),
      ],
    );
  }

  Widget _menu(BuildContext context, {required bool closeOnSelect}) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text('Navegación'),
              ),
            ),
            for (final section in StudentSection.values)
              Builder(
                builder: (drawerContext) => ListTile(
                  leading: Icon(
                    this.section == section
                        ? sections[section]!.selectedIcon
                        : sections[section]!.icon,
                  ),
                  title: Text(sections[section]!.label),
                  selected: this.section == section,
                  onTap: () {
                    if (closeOnSelect) {
                      Navigator.of(drawerContext).pop();
                    }
                    _open(context, sections[section]!.route);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Cambio entre secciones del menú: reemplaza la raíz del espacio estudiante.
  void _open(BuildContext context, String route) {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }
    final current = GoRouterState.of(context).uri.path;
    if (current != route) {
      router.go(route);
    }
  }
}

class _StudentLink {
  const _StudentLink(this.label, this.icon, this.selectedIcon, this.route);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}
