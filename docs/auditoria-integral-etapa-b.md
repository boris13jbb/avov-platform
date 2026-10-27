# Auditoría integral AVOV — Etapa B (Navegación y acceso)

**Worktree:** `C:\Users\BRS\Documents\AVOV-audit-uiux`
**Rama:** `feature/audit-integral-uiux` (sin push/commit aún)
**Base:** `origin/main` @ `dfca9ee`

## Objetivo

Corregir el uso generalizado de `context.go` en pantallas internas, que borraba el historial y hacía que el Atrás de Android cerrara la aplicación.

## Cambios

### Infraestructura nueva

| Archivo | Rol |
|---|---|
| `frontend/lib/router/app_navigation.dart` | `open` (push), `back`, `completeTo`, raíces y fallbacks por área |
| `frontend/lib/shared/widgets/navigation_back_button.dart` | Leading «Volver» |
| `frontend/lib/shared/widgets/internal_route_scope.dart` | PopScope interno → `AppNavigation.back` |
| `frontend/lib/shared/widgets/root_exit_scope.dart` | En paneles raíz confirma salida |

### Conservado de `main` (no repetir regresiones del WIP de `AVOV`)

- Acceso **Gestionar asignaciones** en panel SUPER_ADMIN e INSTITUTION_ADMIN
- Entrada **Asistente IA** en `StudentScaffold` / menú del estudiante
- Fallback de asistente → panel estudiante en `AppNavigation.fallbackFor`

### Pantallas actualizadas

Dashboards (RootExit + open), listados/formularios/detalles admin e institución, asignaciones, auditoría, vector, observaciones, estudiantes, usuarios, carreras, preguntas, espacio estudiante y test vocacional (`completeTo` al resultado).

### `context.go` residual justificado

- Splash → login
- Login → destino por rol
- Logout → login

## Pruebas (ejecutadas)

```text
flutter analyze → No issues found
flutter test test/router/app_navigation_test.dart
flutter test test/admin_navigation_test.dart
flutter test test/admin_modules_navigation_test.dart
flutter test test/admin_dashboard_test.dart
→ All tests passed
```

## Pendiente Etapa C (prioridad)

1. Texto engañoso en panel COUNSELOR («herramientas no disponibles») pese a revisión de sesión/observaciones vía ficha de estudiante.
2. `PendingPanelScreen` sin ruta (código muerto).
3. UI cambio de contraseña / forgot-reset (PRs #12/#14; no portar sin autorización).
4. Suite completa `flutter test` + `pytest` en `avov_test`.

## Git

- Sin commit ni push (requieren autorización explícita).
- WIP de `C:\Users\BRS\Documents\AVOV` no modificado.
