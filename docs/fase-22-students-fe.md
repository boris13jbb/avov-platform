# FASE 22 — CRUD estudiantes (Flutter)

## Objetivo

Gestión de estudiantes para **INSTITUTION_ADMIN**, integrada con `/api/v1/students` (Fase 8).

## Rutas

| Pantalla | Ruta |
|----------|------|
| Lista | `/institution/students` |
| Crear | `/institution/students/new` |
| Detalle | `/institution/students/:id` |
| Editar | `/institution/students/:id/edit` |

## Mejora FASE 21

- Detalle de usuario muestra **nombre de institución** (no solo ID) vía `institutionDetailProvider`.

## Funcionalidad adicional (FASE 26)

- En detalle de estudiante: botón **Asignar orientador**
- Integra `POST /students/{id}/assign-counselor`
- Lista orientadores activos de la institución en diálogo de selección

## Validación manual

1. Login como `INSTITUTION_ADMIN`
2. Panel institucional → **Gestionar estudiantes**
3. Crear estudiante con identificación, grado y contraseña fuerte
4. Editar perfil y cambiar estado
5. Abrir detalle → **Asignar orientador** → elegir orientador activo

## Siguiente fase

**FASE 23 — Pantallas test vocacional (Flutter)**
