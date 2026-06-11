# FASE 20 — CRUD instituciones (Flutter)

## Objetivo

Pantallas de gestión de instituciones para el rol **SUPER_ADMIN**, integradas con los endpoints del backend (Fase 6).

## Rutas

| Pantalla | Ruta |
|----------|------|
| Lista | `/admin/institutions` |
| Crear | `/admin/institutions/new` |
| Detalle | `/admin/institutions/:id` |
| Editar | `/admin/institutions/:id/edit` |

## Archivos implementados

| Archivo | Responsabilidad |
|---------|-----------------|
| `core/models/institution.dart` | Modelo y paginación |
| `features/institutions/data/datasources/institution_remote_datasource.dart` | API REST |
| `features/institutions/data/repositories/institution_repository.dart` | Capa de datos |
| `features/institutions/presentation/providers/institution_provider.dart` | Estado Riverpod |
| `features/institutions/presentation/screens/institution_list_screen.dart` | Lista, búsqueda, filtros |
| `features/institutions/presentation/screens/institution_detail_screen.dart` | Detalle y desactivar |
| `features/institutions/presentation/screens/institution_form_screen.dart` | Crear / editar |
| `router/app_router.dart` | Rutas registradas |
| `router/auth_guard.dart` | Protección por rol + hidratación de rol |

## Validación manual

1. Iniciar sesión como `admin@avov.edu.co` / `Admin123!`
2. En el panel global, pulsar **Gestionar instituciones**
3. Buscar, filtrar por estado, paginar
4. Crear una institución de prueba
5. Editar y desactivar

## Siguiente fase

**FASE 21 — CRUD usuarios (Flutter)**
