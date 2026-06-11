# FASE 21 — CRUD usuarios (Flutter)

## Objetivo

Pantallas de gestión de usuarios integradas con el backend (Fase 7), para **SUPER_ADMIN** y gestión de orientadores para **INSTITUTION_ADMIN**.

## Rutas Super Admin

| Pantalla | Ruta |
|----------|------|
| Lista | `/admin/users` |
| Crear | `/admin/users/new` |
| Detalle | `/admin/users/:id` |
| Editar | `/admin/users/:id/edit` |

## Rutas Admin Institucional

| Pantalla | Ruta |
|----------|------|
| Lista orientadores | `/institution/counselors` |
| Crear orientador | `/institution/counselors/new` |
| Detalle | `/institution/counselors/:id` |
| Editar | `/institution/counselors/:id/edit` |

## Archivos implementados

| Archivo | Responsabilidad |
|---------|-----------------|
| `core/models/managed_user.dart` | Modelo de usuario gestionado |
| `features/users/domain/user_management_config.dart` | Config por rol/alcance |
| `features/users/data/...` | Datasource y repository |
| `features/users/presentation/providers/user_provider.dart` | Estado Riverpod |
| `features/users/presentation/screens/*` | Lista, detalle, formulario |
| `router/app_router.dart` | Rutas registradas |
| `router/role_route_mapper.dart` | Protección por rol |

## Validación manual

### Super Admin
```text
admin@avov.edu.co / Admin123!
```
1. Panel global → **Gestionar usuarios**
2. Crear usuario con rol e institución
3. Editar y cambiar estado

### Admin Institucional
Usar credenciales de un `INSTITUTION_ADMIN` existente:
1. Panel institucional → **Gestionar orientadores**
2. Crear orientador (institución asignada automáticamente por backend)

## Siguiente fase

**FASE 22 — CRUD estudiantes (Flutter)**
