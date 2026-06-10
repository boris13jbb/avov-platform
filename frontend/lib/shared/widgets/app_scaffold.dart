import 'package:flutter/material.dart';

import '../../core/theme/responsive_breakpoints.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.navigationItems = const [],
    this.selectedNavigationIndex = 0,
    this.onNavigationSelected,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final List<NavigationDestination> navigationItems;
  final int selectedNavigationIndex;
  final ValueChanged<int>? onNavigationSelected;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useSidebar = ResponsiveBreakpoints.isDesktop(width);

    if (useSidebar && navigationItems.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedNavigationIndex,
              onDestinationSelected: onNavigationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: navigationItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: item.icon,
                      selectedIcon: item.selectedIcon ?? item.icon,
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: body,
      bottomNavigationBar: navigationItems.isEmpty
          ? null
          : NavigationBar(
              selectedIndex: selectedNavigationIndex,
              onDestinationSelected: onNavigationSelected,
              destinations: navigationItems,
            ),
    );
  }
}
