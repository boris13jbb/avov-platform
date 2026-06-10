# FASE 8 — CRUD estudiantes

## Objetivo

Implementar gestión de estudiantes creando usuario + perfil académico en una sola operación, con permisos por rol.

## Componentes implementados

| Capa | Archivo | Responsabilidad |
|------|---------|-----------------|
| Schema | `schemas/student.py` | Create, Update, Status, Response |
| Repository | `repositories/student_repository.py` | CRUD, búsqueda, asignación orientador |
| Service | `services/student_service.py` | Reglas de negocio y permisos |
| Routes | `api/routes/students.py` | Endpoints REST |

## Endpoints

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/api/v1/students` | SUPER_ADMIN, INSTITUTION_ADMIN, COUNSELOR | Listar con filtros |
| GET | `/api/v1/students/{id}` | Según permiso | Detalle |
| POST | `/api/v1/students` | SUPER_ADMIN, INSTITUTION_ADMIN | Crear estudiante + usuario |
| PUT | `/api/v1/students/{id}` | SUPER_ADMIN, INSTITUTION_ADMIN | Actualizar |
| PATCH | `/api/v1/students/{id}/status` | SUPER_ADMIN, INSTITUTION_ADMIN | Cambiar estado del usuario |

## Parámetros de listado

| Parámetro | Descripción |
|-----------|-------------|
| `page` | Página (default 1) |
| `page_size` | Tamaño (1-100, default 20) |
| `search` | Nombre, apellido, email o identificación |
| `institution_id` | Filtro por institución (SUPER_ADMIN) |
| `status` | Estado del usuario (ACTIVE, INACTIVE, BLOCKED) |
| `grade` | Grado/cursado |
| `gender` | Género |

## Reglas de permisos

### SUPER_ADMIN
- Ve y gestiona todos los estudiantes

### INSTITUTION_ADMIN
- Solo estudiantes de su institución
- Crea y actualiza en su institución

### COUNSELOR
- Solo lista y ve estudiantes asignados en `counselor_assignments` (ACTIVE)

### STUDENT
- Puede ver su propio perfil (`GET /students/{id}` propio)
- Sin acceso al listado

## Validaciones

- Email único
- Identificación única
- Fecha de nacimiento no futura
- Contraseña fuerte al crear
- Institución activa requerida
- Estado se guarda en tabla `users`

## Criterios de validación

- [x] Creación atómica user + student
- [x] Permisos por rol
- [x] Orientador filtrado por asignaciones
- [x] Tests pytest pasan

## Siguiente fase

**FASE 9 — CRUD carreras**
