// url=https://www.figma.com/design/kZ0uYN2ZYLFcBjNBGhZEU3?node-id=4-12
// source=lib/features/dashboard/presentation/widgets/metric_card.dart
// component=MetricCard
// framework=flutter
import figma from 'figma'

const instance = figma.selectedInstance

const label = instance?.findOne(n => n.type === 'TEXT' && n.name !== '128')?.characters ?? 'Estudiantes activos'
const value = instance?.findOne(n => n.type === 'TEXT' && n.characters.match(/^\d+$/))?.characters ?? '128'
const subtitle = instance?.findOne(n => n.type === 'TEXT' && n.characters === 'Este mes')?.characters

export default {
  example: figma.code`<MetricCard label="${label}" value="${value}"${subtitle ? ` subtitle="${subtitle}"` : ''} />`,
  imports: [
    "import 'package:avov_frontend/features/dashboard/presentation/widgets/metric_card.dart';",
  ],
  metadata: {
    flutterWidget: 'MetricCard',
    props: {
      label: 'String — etiqueta de la métrica',
      value: 'String — valor principal',
      icon: 'IconData? — icono opcional',
      subtitle: 'String? — texto secundario',
    },
  },
}
