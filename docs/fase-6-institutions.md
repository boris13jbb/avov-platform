# FASE 6 — CRUD instituciones

## Objetivo

Implementar gestión completa de instituciones con permisos por rol y eliminación lógica.

## Componentes implementados

| Capa | Archivo | Responsabilidad |
|------|---------|-----------------|
| Schema | `schemas/institution.py` | Create, Update, Response, paginación |
| Repository | `repositories/institution_repository.py` | Acceso a datos y búsqueda |
| Service | `services/institution_service.py` | Reglas de negocio y permisos |
| Routes | `api/routes/institutions.py` | Endpoints REST |

## Endpoints

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/api/v1/institutions` | SUPER_ADMIN | Listar con paginación y búsqueda |
| GET | `/api/v1/institutions/{id}` | SUPER_ADMIN, INSTITUTION_ADMIN (propia) | Detalle |
| POST | `/api/v1/institutions` | SUPER_ADMIN | Crear |
| PUT | `/api/v1/institutions/{id}` | SUPER_ADMIN | Actualizar |
| DELETE | `/api/v1/institutions/{id}` | SUPER_ADMIN | Desactivar (INACTIVE) |

## Parámetros de listado

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `page` | int | Página (default 1) |
| `page_size` | int | Tamaño (1-100, default 20) |
| `search` | string | Busca en nombre, código, provincia, ciudad |
| `status` | ACTIVE/INACTIVE | Filtro por estado |
| `province` | string | Filtro por provincia |
| `city` | string | Filtro por ciudad |

## Validaciones

- `name`: mínimo 3 caracteres
- `code`: único, se normaliza a mayúsculas
- `phone`: 7-15 dígitos numéricos
- `email`: formato válido (opcional)
- DELETE: cambia `status` a `INACTIVE` (no borra físicamente)

## Criterios de validación

- [x] SUPER_ADMIN puede listar, crear, editar y desactivar
- [x] INSTITUTION_ADMIN solo ve su propia institución
- [x] STUDENT/COUNSELOR no acceden al CRUD
- [x] Código duplicado rechazado
- [x] Tests pytest pasan

## Siguiente fase

**FASE 7 — CRUD usuarios**
