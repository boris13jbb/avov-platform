# FASE 10 — CRUD preguntas RIASEC

## Objetivo

Implementar gestión de las 60 preguntas del test vocacional RIASEC (10 por categoría) con CRUD administrativo.

## Componentes implementados

| Capa | Archivo | Responsabilidad |
|------|---------|-----------------|
| Seed | `db/seeds/riasec_questions.py` | 60 textos de preguntas |
| Migración | `f4b5c6d7e8f9_seed_riasec_questions.py` | Inserta preguntas en BD |
| Schema | `schemas/question.py` | Create, Update, Status, Response |
| Repository | `repositories/question_repository.py` | CRUD y filtros |
| Service | `services/question_service.py` | Reglas de negocio |
| Routes | `api/routes/questions.py` | Endpoints REST |

## Endpoints

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/api/v1/questions` | Autenticado | Listar (activas por defecto) |
| GET | `/api/v1/questions/{id}` | Autenticado | Detalle |
| POST | `/api/v1/questions` | SUPER_ADMIN | Crear |
| PUT | `/api/v1/questions/{id}` | SUPER_ADMIN | Actualizar |
| PATCH | `/api/v1/questions/{id}/status` | SUPER_ADMIN | Activar/inactivar |

## Parámetros de listado

| Parámetro | Descripción |
|-----------|-------------|
| `page`, `page_size` | Paginación |
| `search` | Busca en el texto de la pregunta |
| `category_id` | Filtro por categoría |
| `category_code` | R, I, A, S, E o C |
| `status` | ACTIVE/INACTIVE (solo SUPER_ADMIN puede filtrar INACTIVE) |

## Seed RIASEC

- **60 preguntas** — 10 por cada categoría (R, I, A, S, E, C)
- Escala de respuesta 1-5 definida en aplicación (Fase 11)

## Validaciones

- Texto mínimo 10 caracteres
- `order_number` único por categoría
- Categoría RIASEC debe existir
- Usuarios no admin solo ven preguntas ACTIVE

## Criterios de validación

- [x] 60 preguntas seed en BD
- [x] CRUD SUPER_ADMIN operativo
- [x] Listado autenticado con filtros
- [x] Tests pytest pasan

## Siguiente fase

**FASE 11 — Motor test vocacional (sesiones, respuestas, cálculo RIASEC)**
