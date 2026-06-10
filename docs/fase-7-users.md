# FASE 7 — CRUD usuarios

## Objetivo

Implementar gestión de usuarios con permisos diferenciados por rol e integración con instituciones.

## Componentes implementados

| Capa | Archivo | Responsabilidad |
|------|---------|-----------------|
| Schema | `schemas/user.py` | Create, Update, Status, Response, paginación |
| Repository | `repositories/user_repository.py` | Listado, CRUD y búsqueda |
| Service | `services/user_service.py` | Reglas de negocio y permisos |
| Routes | `api/routes/users.py` | Endpoints REST |

## Endpoints

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/api/v1/users` | SUPER_ADMIN, INSTITUTION_ADMIN | Listar con filtros |
| GET | `/api/v1/users/{id}` | Según permiso | Detalle (propio o gestionado) |
| POST | `/api/v1/users` | SUPER_ADMIN, INSTITUTION_ADMIN | Crear usuario |
| PUT | `/api/v1/users/{id}` | Según permiso | Actualizar |
| PATCH | `/api/v1/users/{id}/status` | SUPER_ADMIN, INSTITUTION_ADMIN | Cambiar estado |

## Parámetros de listado

| Parámetro | Descripción |
|-----------|-------------|
| `page` | Página (default 1) |
| `page_size` | Tamaño (1-100, default 20) |
| `search` | Busca en nombre, apellido y email |
| `role` | Filtro por rol |
| `institution_id` | Filtro por institución (solo SUPER_ADMIN) |
| `status` | Filtro por estado |

## Reglas de permisos

### SUPER_ADMIN
- Gestiona todos los usuarios y roles
- Puede filtrar por cualquier institución

### INSTITUTION_ADMIN
- Solo ve usuarios de su `institution_id`
- Solo crea/gestiona `COUNSELOR` y `STUDENT`
- No puede crear `SUPER_ADMIN` ni `INSTITUTION_ADMIN`

### COUNSELOR / STUDENT
- Sin acceso al listado ni creación
- Pueden ver su propio perfil vía `GET /users/{id}` (propio id)

## Validaciones

- Contraseña fuerte al crear (8+ chars, mayúscula, minúscula, número, símbolo)
- Email único
- `SUPER_ADMIN` sin `institution_id`
- Demás roles requieren institución activa
- No se puede cambiar el propio estado
- `password_hash` nunca se expone en respuestas

## Criterios de validación

- [x] Listado con filtros y paginación
- [x] Permisos SUPER_ADMIN vs INSTITUTION_ADMIN
- [x] Creación con hash bcrypt
- [x] Actualización y cambio de estado
- [x] Tests pytest pasan

## Siguiente fase

**FASE 8 — CRUD estudiantes**
