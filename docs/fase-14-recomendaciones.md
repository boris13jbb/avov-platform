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
- [x] Qdrant usable; si falla o vacío, fallback MySQL (pytest + validación hits obsoletos).
- [x] Lista vacía coherente si no hay carreras (pytest + widget).
- [x] UI: sección en resultado vocacional; dashboard apunta a Resultados.
- [x] Pruebas en `avov_test` (`tests/test_recommendations.py`).
- [x] E2E UI+HTTP en `:3001` / `:8001` con sesión desechable **156** (no 137/138/139).

## Defecto corregido en revisión S-21 (2026-10-21)

### Causa raíz (HTTP 500 al generar)

Qdrant devolvía `career_id` ausentes en `avov_test.careers` (índice compartido / IDs de otras corridas).
`RecommendationService` intentaba `INSERT` → FK `recommendations_ibfk_1` → HTTP 500.

### Corrección

1. `VectorService.search_careers`: valida hits Qdrant contra carreras **ACTIVE** en MySQL; si ninguno es válido, usa fallback MySQL (`used_fallback=true`).
2. `RecommendationService.generate_for_session`: filtro defensivo antes de persistir.
3. Prueba de regresión: `test_generate_falls_back_when_qdrant_returns_stale_career_ids`.

## Evidencia E2E (2026-10-21) — entorno aislado

| Ítem | Valor |
|------|--------|
| Flutter | `http://localhost:3001` (Chrome hijo del `flutter run` E2E) |
| API | `http://127.0.0.1:8001/api/v1` |
| Schema | `avov_test` |
| Sesión desechable | **156** `COMPLETED` / 60 respuestas / RIASEC presente |
| Marcador local | `%LOCALAPPDATA%\AVOV\e2e\s21-disposable-session.json` (solo `session_id`) |
| Script preparación | `backend/scripts/prepare_e2e_s21_disposable_session.py` |

### HTTP (sin tokens)

| Paso | Solicitud | Código | Observado |
|------|-----------|--------|-----------|
| Login QA | `POST /auth/login` | 200 | Rol `STUDENT` |
| Lista vacía inicial | `GET /recommendations/sessions/156` | 200 | `total=0` |
| Generar (tras fix) | `POST /recommendations/sessions/156/generate` | 200 | `total=8`, `used_fallback=false`, perfil `RI`, carreras del catálogo (p. ej. id 85) |
| Relistar | `GET /recommendations/sessions/156` | 200 | `total=8` |
| Evidencia 139 | `GET /recommendations/sessions/139` | 200 | `total=0` (sin generate sobre 139) |
| UI resultado 156 | `GET /tests/156/result` + `GET /recommendations/sessions/156` | 200 | Captura UI con «Carreras recomendadas» e «Ing. Sistemas Rec · 60%» |
| Regreso historial | hash `#/student/results` | — | Sin tráfico a `/tests/start`, `/answers`, `/finish` |

### Qdrant y fallback MySQL

| Prueba | Resultado |
|--------|-----------|
| Generate E2E 156 con Qdrant sano + hits válidos | `used_fallback=false`, `source=qdrant`, carreras ACTIVE en MySQL |
| Hits Qdrant con `career_id` inexistente (antes del fix) | HTTP 500 FK |
| Tras fix + pytest stale IDs | HTTP 200 + `used_fallback=true` |
| `VectorService` in-process con `is_available=False` | `used_fallback=true`, `source=mysql_fallback`, ids ACTIVE |

### Autorización / aislamiento

| Prueba | Resultado |
|--------|-----------|
| `test_student_cannot_access_other_student_recommendations` | 403 |
| Sesiones 137/138/139 tras E2E | intactas (status/answers); `recommendations` de 139 = 0 |

### Pruebas automatizadas ejecutadas

| Suite | Resultado |
|-------|-----------|
| `pytest tests/test_recommendations.py` | **7 passed** (exit 0) |
| `flutter test` career_recommendations + student_space + student_test_imperative_url | **aprobados** (tras actualizar expectativas del mensaje antiguo) |

### Limitaciones

- No hay workflows GitHub Actions en el repo; `statusCheckRollup` de PR #1 y #2 está vacío (no declarar CI verde).
- Abrir un resultado COMPLETED vacío dispara `POST .../generate` desde el provider Flutter: **no** abrir 139 en UI con API S-21 si se quiere conservar `recommendations=0` en esa sesión.
- Duplicados de nombre en catálogo E2E (varios «Ing. Sistemas Rec») son datos de prueba, no defecto del ranking.

## Estado de PRs (solo lectura, sin merge)

| PR | Base ← Head | Commit cabeza | Checks | Independencia |
|----|-------------|---------------|--------|---------------|
| [#1](https://github.com/boris13jbb/avov-platform/pull/1) | `main` ← `docs/windows-continuity` | `bbff722` (+ fix URL S-20) | Ninguno | Contiene UI estudiante; **no** incluye motor S-21 |
| [#2](https://github.com/boris13jbb/avov-platform/pull/2) | `docs/windows-continuity` ← `feature/s21-career-recommendations` | `95f4796` | Ninguno | Diff S-21 (~21 archivos); depende de UI de #1 |

## Decisión recomendada para cerrar S-21

1. Incorporar el fix de hits Qdrant obsoletos (+ tests Flutter actualizados) en un commit de la rama `feature/s21-career-recommendations` (requiere autorización de commit).
2. Fusionar **primero PR #1** a `main` (autorización independiente); luego retarget/rebase de PR #2 a `main` y fusionar PR #2.
3. No declarar S-21 «cerrada en producción» hasta ese merge; el E2E aislado de esta pasada **sí** valida el producto en `:3001`/`:8001`/`avov_test`.
4. Siguiente fase de producto: **Fase 15 (PDF)** tras cierre formal S-21.
