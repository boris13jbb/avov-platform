// url=https://www.figma.com/design/kZ0uYN2ZYLFcBjNBGhZEU3?node-id=pending
// source=lib/features/dashboard/presentation/screens/student_dashboard_screen.dart
// component=StudentDashboardScreen
// framework=flutter
import figma from 'figma'

export default {
  example: figma.code`<StudentDashboardScreen />`,
  imports: [
    "import 'package:avov_frontend/features/dashboard/presentation/screens/student_dashboard_screen.dart';",
  ],
  metadata: {
    flutterWidget: 'StudentDashboardScreen',
    shell: 'DashboardShell',
    widgets: ['DashboardBody', 'DashboardMetricsGrid', 'MetricCard', 'EthicalDisclaimerBanner'],
    sections: [
      'AppBar — Mi panel',
      'Estado de orientación vocacional',
      'Grid de métricas',
      'Tarjeta estado del test',
      'Acciones siguientes',
      'Aviso ético',
    ],
  },
}
