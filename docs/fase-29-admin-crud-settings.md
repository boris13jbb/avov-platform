# FASE 29 — CRUD Admin Carreras/Preguntas y Configuración del Sistema

## Resumen

Se completó el CRUD administrativo de carreras y preguntas RIASEC en Flutter, conectado a los endpoints existentes del backend. Se añadió la API de configuración global (`system_settings`) y el listado de categorías RIASEC para formularios.

## Backend

### Nuevos endpoints

| Método | Ruta | Rol |
|--------|------|-----|
| GET | `/api/v1/riasec-categories` | Autenticado |
| GET | `/api/v1/settings` | SUPER_ADMIN |
| PUT | `/api/v1/settings/{key}` | SUPER_ADMIN |

### Parámetros configurables (whitelist)

- `app_display_name`
- `ethical_disclaimer`
- `max_recommendations_per_session`
- `maintenance_mode`

## Frontend

### Rutas nuevas

- `/admin/careers/new`, `/admin/careers/:id`, `/admin/careers/:id/edit`
- `/admin/questions/new`, `/admin/questions/:id`, `/admin/questions/:id/edit`
- Configuración del sistema editable en `/admin/settings`

### Modelos

- `core/models/career.dart`
- `core/models/question.dart`
- `core/models/system_setting.dart`

## Validaciones

```bash
cd frontend && flutter analyze && flutter test
docker compose exec -T backend pytest tests/test_system_settings.py tests/test_riasec_categories.py -q
```

## Sincronización Qdrant

Al crear, actualizar o desactivar una carrera, el backend sincroniza automáticamente el punto en Qdrant.
La respuesta incluye `vector_synced` y un mensaje indicando si la sincronización fue exitosa.
La reconstrucción manual del índice sigue disponible como respaldo.

## Preguntas RIASEC

`DELETE /api/v1/questions/{id}` desactiva la pregunta (baja lógica), alineado con el patrón de carreras.
No se elimina físicamente para preservar respuestas históricas en `test_answers`.

## Huecos cerrados (post-Fase 29)

- `GET /api/v1/settings/public` — configuración pública sin auth
- Modo mantenimiento aplicado en login, API y Flutter
- Auditoría en mutaciones de carreras y preguntas
- `GET /api/v1/audit/logs/{id}`
- Dashboard estudiante: `download_pdf` con reporte existente

## Siguiente fase

**Fase 30** — Documentación operativa y QA ([fase-30-documentacion.md](fase-30-documentacion.md))
