# FASE 25 — Asistente virtual (Flutter)

## Objetivo

Pantalla de chat con el asistente de orientación vocacional para estudiantes.

## Ruta

| Pantalla | Ruta |
|----------|------|
| Asistente virtual | `/student/assistant` |

## Endpoints integrados

| Método | Ruta | Uso |
|--------|------|-----|
| POST | `/assistant/chat` | Enviar mensaje libre |
| POST | `/assistant/explain-profile` | Acción rápida: explicar perfil RIASEC |
| POST | `/assistant/explain-careers` | Acción rápida: explicar carreras recomendadas |

## Arquitectura Flutter

```
frontend/lib/features/assistant/
  data/
    datasources/assistant_remote_datasource.dart
    repositories/assistant_repository.dart
  presentation/
    providers/assistant_provider.dart
    screens/assistant_chat_screen.dart
    widgets/chat_bubble.dart
frontend/lib/core/models/assistant_message.dart
```

## Funcionalidades

- Chat con historial local de mensajes (usuario / asistente)
- Input de texto con límite de 1000 caracteres
- Contexto automático con `test_session_id` del dashboard
- Chips de acción rápida: perfil RIASEC y carreras recomendadas
- Banner contextual si falta test o recomendaciones, con acciones directas
- Generación automática de recomendaciones al usar "Explicar carreras"
- Indicador de fuente (`IA DeepSeek` vs `Modo orientativo`)
- Banner visible cuando la respuesta usa fallback (sin DeepSeek)
- Mensajes guía en el chat si una acción aún no está disponible
- Banner de disclaimer ético en cada respuesta
- Estados: carga, error y mensaje de bienvenida

## Validación manual

Login: `estudiante.test.fase11@instituto.edu.co` / `Estud1234!`

1. Mi panel → **Asistente virtual**
2. Escribir una pregunta (ej. "¿Qué carreras van con mi perfil?") y enviar
3. Ver respuesta con etiqueta de fuente y disclaimer
4. Probar chip **Explicar mi perfil**
5. Probar chip **Explicar carreras** (requiere recomendaciones generadas)

## Siguiente fase

**FASE 26 — Panel orientador (Flutter)**
