// url=https://www.figma.com/design/kZ0uYN2ZYLFcBjNBGhZEU3?node-id=4-4
// source=lib/shared/widgets/error_banner.dart
// component=ErrorBanner
// framework=flutter
import figma from 'figma'

const message = figma.selectedInstance?.findOne(n => n.type === 'TEXT')?.characters
  ?? 'No se pudo completar la operación'

export default {
  example: figma.code`<ErrorBanner message="${message}" onDismiss={() {}} />`,
  imports: [
    "import 'package:avov_frontend/shared/widgets/error_banner.dart';",
  ],
  metadata: {
    flutterWidget: 'ErrorBanner',
    props: {
      message: 'String — mensaje de error en español',
      onDismiss: 'VoidCallback? — cerrar el banner',
    },
  },
}
