// url=https://www.figma.com/design/kZ0uYN2ZYLFcBjNBGhZEU3?node-id=4-2
// source=lib/features/assistant/presentation/widgets/chat_bubble.dart
// component=ChatBubble
// framework=flutter
import figma from 'figma'

const text = figma.selectedInstance?.findOne(n => n.type === 'TEXT')?.characters
  ?? 'Mensaje del asistente'

export default {
  example: figma.code`<ChatBubble message={AssistantMessage(content: '${text}', isFromUser: false)} />`,
  imports: [
    "import 'package:avov_frontend/core/models/assistant_message.dart';",
    "import 'package:avov_frontend/features/assistant/presentation/widgets/chat_bubble.dart';",
  ],
  metadata: {
    flutterWidget: 'ChatBubble',
    props: {
      message: 'AssistantMessage — mensaje del chat con isFromUser y source',
    },
    variants: {
      user: 'Alineación derecha, color primary',
      assistant: 'Alineación izquierda, surfaceContainerHighest',
      hint: 'Color tertiaryContainer',
    },
  },
}
