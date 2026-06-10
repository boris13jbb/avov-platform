# FASE 9 — CRUD carreras

## Objetivo

Implementar gestión de carreras vocacionales con filtros RIASEC y eliminación lógica.

## Componentes implementados

| Capa | Archivo | Responsabilidad |
|------|---------|-----------------|
| Schema | `schemas/career.py` | Create, Update, Response, paginación |
| Repository | `repositories/career_repository.py` | CRUD, búsqueda y filtros |
| Service | `services/career_service.py` | Reglas de negocio |
| Routes | `api/routes/careers.py` | Endpoints REST |

## Endpoints

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/api/v1/careers` | Autenticado | Listar con filtros |
| GET | `/api/v1/careers/{id}` | Autenticado | Detalle |
| POST | `/api/v1/careers` | SUPER_ADMIN | Crear |
| PUT | `/api/v1/careers/{id}` | SUPER_ADMIN | Actualizar |
| DELETE | `/api/v1/careers/{id}` | SUPER_ADMIN | Desactivar (INACTIVE) |

## Parámetros de listado

| Parámetro | Descripción |
|-----------|-------------|
| `page` | Página (default 1) |
| `page_size` | Tamaño (1-100, default 20) |
| `search` | Busca en nombre, área, campo laboral y descripción |
| `area` | Filtro por área |
| `riasec_profile` | Filtro por letras RIASEC (R, I, A, S, E, C) |
| `degree_type` | TECNOLOGICO, TERCER_NIVEL, LICENCIATURA, INGENIERIA, OTRO |
| `status` | ACTIVE o INACTIVE |

## Validaciones

- `name`: mínimo 3 caracteres
- `description`: mínimo 10 caracteres
- `riasec_profile`: solo letras R, I, A, S, E, C (normalizado a mayúsculas)
- DELETE: cambia `status` a `INACTIVE`

## Criterios de validación

- [x] Lectura para cualquier usuario autenticado
- [x] Escritura solo SUPER_ADMIN
- [x] Filtros área/RIASEC/título operativos
- [x] Soft delete funcional
- [x] Tests pytest pasan

## Siguiente fase

**FASE 10 — CRUD preguntas RIASEC (60 preguntas)**
