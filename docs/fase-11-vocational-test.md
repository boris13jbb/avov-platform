# FASE 11 — Motor test vocacional RIASEC

## Objetivo

Implementar el flujo completo del test vocacional: sesiones, respuestas (escala 1-5), finalización y cálculo del perfil RIASEC.

## Componentes implementados

| Capa | Archivo | Responsabilidad |
|------|---------|-----------------|
| Schema | `schemas/test_session.py` | Sesión, respuestas, preguntas, resultado |
| Repository | `repositories/test_session_repository.py` | Sesiones, respuestas, resultados |
| Calculator | `services/riasec_calculator.py` | Algoritmo RIASEC puro |
| Service | `services/test_session_service.py` | Reglas de negocio y permisos |
| Routes | `api/routes/tests.py` | Endpoints REST |

## Endpoints

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| POST | `/api/v1/tests/start` | STUDENT | Iniciar o continuar test |
| GET | `/api/v1/tests/{session_id}/questions` | STUDENT (owner) | Preguntas + progreso |
| POST | `/api/v1/tests/{session_id}/answers` | STUDENT (owner) | Guardar respuesta 1-5 |
| POST | `/api/v1/tests/{session_id}/finish` | STUDENT (owner) | Finalizar y calcular RIASEC |
| GET | `/api/v1/tests/{session_id}/result` | STUDENT, COUNSELOR, Admin | Resultado RIASEC |

## Algoritmo RIASEC

1. Sumar `answer_value` (1-5) por categoría — 10 preguntas × 6 categorías.
2. Puntaje máximo por categoría: **50**. Mínimo: **10**.
3. `dominant_profile`: categoría con mayor puntaje.
4. Desempate: **R > I > A > S > E > C**.
5. `secondary_profile`: segunda categoría más alta.
6. `combined_profile`: tres letras del ranking (ej. RIS, SEC).

## Reglas de negocio

- Un estudiante con sesión `STARTED` o `IN_PROGRESS` continúa la misma sesión.
- No puede finalizar sin las 60 respuestas activas.
- No puede modificar un test `COMPLETED`.
- `answer_value` siempre entre 1 y 5.
- Orientador solo ve resultados de estudiantes asignados.

## Escala de respuesta

| Valor | Significado |
|-------|-------------|
| 1 | No me gusta nada |
| 2 | Me gusta poco |
| 3 | Me es indiferente |
| 4 | Me gusta |
| 5 | Me gusta mucho |

## Criterios de validación

- [x] Inicio/continuación de sesión
- [x] Guardado de respuestas con progreso
- [x] Finalización con cálculo RIASEC
- [x] Consulta de resultado con permisos
- [x] Tests pytest pasan

## Siguiente fase

**FASE 12 — Vector / Qdrant (reconstrucción índice y búsqueda semántica)**
