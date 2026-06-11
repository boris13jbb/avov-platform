// url=https://www.figma.com/design/kZ0uYN2ZYLFcBjNBGhZEU3?node-id=pending
// source=lib/features/vocational_test/presentation/screens/test_session_screen.dart
// component=TestSessionScreen
// framework=flutter
import figma from 'figma'

export default {
  example: figma.code`<TestSessionScreen sessionId={1} />`,
  imports: [
    "import 'package:avov_frontend/features/vocational_test/presentation/screens/test_session_screen.dart';",
  ],
  metadata: {
    flutterWidget: 'TestSessionScreen',
    props: {
      sessionId: 'int — ID de la sesión de test',
    },
    widgets: ['ScaleAnswerSelector', 'ErrorBanner', 'LoadingOverlay'],
    sections: [
      'AppBar — Test vocacional',
      'Progreso (pregunta X de 60)',
      'Categoría RIASEC',
      'Tarjeta de pregunta',
      'Selector escala 1–5',
      'Navegación Anterior / Siguiente',
    ],
  },
}
