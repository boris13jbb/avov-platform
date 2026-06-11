// url=https://www.figma.com/design/kZ0uYN2ZYLFcBjNBGhZEU3?node-id=5-1
// source=lib/features/auth/presentation/screens/login_screen.dart
// component=LoginScreen
// framework=flutter
import figma from 'figma'

export default {
  example: figma.code`<LoginScreen />`,
  imports: [
    "import 'package:avov_frontend/features/auth/presentation/screens/login_screen.dart';",
  ],
  metadata: {
    flutterWidget: 'LoginScreen',
    sections: [
      'Icono escuela (Icons.school_outlined)',
      'Título appName (AVOV)',
      'Subtítulo orientación vocacional',
      'Campo correo electrónico',
      'Campo contraseña con toggle visibilidad',
      'Enlace ¿Olvidaste tu contraseña?',
      'Botón Ingresar (FilledButton)',
      'ErrorBanner condicional',
      'LoadingOverlay durante login',
    ],
    figmaComponents: {
      emailField: '4:4 — Input / Text',
      passwordField: '4:8 — Input / Text',
      submitButton: '4:2 — Button / Primary',
    },
    colors: {
      primary: '#1E3A5F',
      background: '#F5F7FA',
      surface: '#FFFFFF',
    },
  },
}
