# FASE 13 — IA / Asistente (DeepSeek)

## Objetivo

Integrar el asistente virtual vocacional con adaptador DeepSeek, fallback local y endpoints REST seguros.

## Componentes implementados

| Capa | Archivo | Responsabilidad |
|------|---------|-----------------|
| Prompts | `services/llm/prompts.py` | Mensajes seguros para IA |
| LLM | `services/llm/llm_service.py` | Llamadas DeepSeek + fallback |
| Provider | `services/llm/deepseek_provider.py` | Adaptador `LLMProvider` |
| Schema | `schemas/assistant.py` | Chat y explicaciones |
| Service | `services/assistant_service.py` | Permisos, contexto y sanitización |
| Routes | `api/routes/assistant.py` | Endpoints REST |

## Endpoints

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| POST | `/api/v1/assistant/chat` | STUDENT | Chat orientativo |
| POST | `/api/v1/assistant/explain-profile` | STUDENT, COUNSELOR | Explicar perfil RIASEC |
| POST | `/api/v1/assistant/explain-careers` | STUDENT, COUNSELOR | Explicar carreras |

## Payloads

### Chat
```json
{
  "message": "¿Qué carreras van con mi perfil?",
  "test_session_id": 17
}
```

### Explicar perfil
```json
{ "test_session_id": 17 }
```
Si el estudiante omite `test_session_id`, se usa su último test completado.

### Explicar carreras
```json
{ "career_ids": [6], "test_session_id": 17 }
```

## Respuesta estándar

```json
{
  "answer": "Texto explicativo...",
  "source": "deepseek",
  "ethical_disclaimer": "Este resultado es orientativo..."
}
```

`source` puede ser `deepseek` o `fallback`.

## Reglas

- DeepSeek solo desde backend (`DEEPSEEK_API_KEY` en `.env`).
- Si la API falla o no hay clave → respuesta `fallback` sin romper el flujo.
- Mensajes sanitizados (máx. 1000 caracteres).
- Advertencia ética en cada respuesta.
- Orientador debe enviar `test_session_id` para explicar perfil de un estudiante.

## Criterios de validación

- [x] Chat restringido a STUDENT
- [x] Explicación de perfil y carreras operativa
- [x] Fallback automático
- [x] Tests pytest pasan

## Siguiente fase

**FASE 14 — Motor de recomendaciones (RIASEC + Qdrant + IA)**
