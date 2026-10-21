# FASE 14 / S-21 — Recomendaciones de carreras

## Diagnóstico (2026-10-21)

### Causa raíz del mensaje «no disponibles»

1. `backend/app/api/routes/recommendations.py` solo declara el router **sin handlers**.
2. Ese router **no** está en `main.py` (`include_router`).
3. No existía `RecommendationService` ni contratos HTTP publicados.
4. La UI hardcodea el aviso en `student_dashboard_screen.dart` y `vocational_result_screen.dart`.

La tabla MySQL `recommendations` y `VectorService.search_careers` (Qdrant + fallback MySQL) **sí** existían; faltaba el orquestador de Fase 14.

### Dependencia de PR #1

La UI estudiante vive en `docs/windows-continuity` (PR [#1](https://github.com/boris13jbb/avov-platform/pull/1)), no en `main` (`4226c49`).  
Rama de trabajo: `feature/s21-career-recommendations` creada **desde** `docs/windows-continuity`.  
El PR de S-21 debe ir **hacia** `docs/windows-continuity` (diff solo S-21), no mezclar commits de S-20 en un segundo PR a `main`. Merge a `main` tras integrar #1.

### Arquitectura reutilizada

| Pieza | Uso |
|-------|-----|
| `RiasecResult` / `GET /tests/{id}/result` | Perfil dominante/secundario/combined |
| `VectorService.search_careers` | Qdrant primero; fallback MySQL por letras RIASEC |
| Tabla `recommendations` | Persistencia `match_percentage`, `qdrant_score`, `ai_explanation` |
| Auth | Mismos roles que ver resultado (`STUDENT` dueño, admin institución, counselor asignado, SUPER_ADMIN) |

### Decisiones de alcance (MVP)

- Fórmula híbrida documentada: `0.6 * riasec_score + 0.4 * qdrant_score` (ambos 0–100).
- Explicación: plantilla ética en español (sin exigir DeepSeek en el camino crítico).
- Sin Redis cache ni campo `counselor_observations` (no está en el esquema).
- Si no hay carreras activas compatibles: lista vacía explícita, **sin** inventar datos.

## Contratos HTTP

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/v1/recommendations/sessions/{session_id}/generate` | Genera (reemplaza) recomendaciones de la sesión completada |
| GET | `/api/v1/recommendations/sessions/{session_id}` | Lista persistida |

Respuesta estándar AVOV (`success`, `message`, `data`, `errors`).

## Criterios de aceptación

- [x] Router registrado; OpenAPI expone las rutas.
- [x] STUDENT solo accede a sus sesiones (pytest aislamiento).
- [x] Qdrant usable; si falla o vacío, fallback MySQL (pytest).
- [x] Lista vacía coherente si no hay carreras (pytest + widget).
- [x] UI: sección en resultado vocacional; dashboard apunta a Resultados.
- [x] Pruebas en `avov_test` (`tests/test_recommendations.py`).
