import 'package:flutter/material.dart';

import '../../../../core/theme/responsive_breakpoints.dart';
import 'metric_card.dart';

class DashboardMetricsGrid extends StatelessWidget {
  const DashboardMetricsGrid({super.key, required this.metrics});

  final List<MetricCard> metrics;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = ResponsiveBreakpoints.isDesktop(width)
        ? 4
        : ResponsiveBreakpoints.isTablet(width)
            ? 2
            : 1;

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: columns == 1 ? 2.4 : 1.5,
      children: metrics,
    );
  }
}
