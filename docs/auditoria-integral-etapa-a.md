# Auditoría integral AVOV — Etapa A (Inventario y línea base)

**Fecha:** 2026-10-26  
**Worktree:** `C:\Users\BRS\Documents\AVOV-audit-uiux`  
**Rama:** `feature/audit-integral-uiux`  
**Base:** `origin/main` @ `dfca9ee` (Merge PR #16 — auditoría consultable)  
**Copia con WIP preservada (no tocada):** `C:\Users\BRS\Documents\AVOV` @ `feature/s21-career-recommendations` (`0dce77b` + WIP local)

## A. Estado del repositorio

| Ítem | Valor |
|---|---|
| Remoto | `https://github.com/boris13jbb/avov-platform.git` |
| SHA base auditoría | `dfca9eea15cf023f276e17b01d4b0618a1569f31` |
| Trabajo aislado | Sí (worktree nuevo; WIP de `AVOV` intacto) |
| Publicación | Ninguna (sin commit/push/PR/merge en esta etapa) |

### PRs abiertos relevantes (inspección 2026-10-26)

| PR | Rama | Tema | En main |
|---|---|---|---|
| #12 | `feature/v1-change-password-fe` | UI cambio de contraseña | No (BE sí tiene `POST /auth/change-password`) |
| #13 | `chore/v1-prod-mobile-prep` | Prep prod/móvil | No |
| #14 | `feature/v1-password-recovery` | Forgot/reset | No |
| #19 | `fix/audit-value-secret-redaction` | Redacción secretos en valores audit | No (capa clave ya en #16) |

### WIP en `AVOV` (no mezclar a ciegas)

Incluye catálogo/auditoría/navegación local y scripts E2E/CDP. La corrección de navegación (`AppNavigation`, `NavigationBackButton`, scopes) es **reutilizable**, pero el WIP del dashboard admin **omite el acceso a asignaciones** y el `StudentScaffold` WIP **quita el asistente del menú**. En Etapa B se porta el patrón de navegación **conservando** asignaciones y asistente de `main`.

## B. Arquitectura real

### Frontend

- Flutter + Riverpod + GoRouter + Dio + Secure Storage
- Feature-first bajo `frontend/lib/features/`
- Tema: `app_theme.dart` + `app_colors.dart` (azul AVOV `#1E3A5F`)
- Guards: `AuthGuard` + `routeMatchesRole` (prefijos `/admin`, `/institution`, `/counselor`, `/student`)

### Backend

- FastAPI capas service/repository; respuesta estándar
- Prefijo API: `/api/v1`
- Roles (`UserRole`): `SUPER_ADMIN`, `INSTITUTION_ADMIN`, `COUNSELOR`, `STUDENT`

### Routers montados

`health`, `status`, `auth`, `institutions`, `users`, `students`, `assignments`, `audit`, `careers`, `questions`, `tests`, `observations`, `recommendations`, `reports`, `vector`, `assistant`  
(`dashboard` router existe; revisar uso efectivo en servicios)

## C. Roles reales

1. `SUPER_ADMIN`
2. `INSTITUTION_ADMIN`
3. `COUNSELOR`
4. `STUDENT`

## D. Matriz de pantallas (inventario estático sobre `origin/main`)

Leyenda **Estado:**  
`completa` = archivo + ruta + acceso UI + API aparente · `incompleta` = falta pieza · `desconectada` = UI sin API o API sin UI · `inexistente` · `bloqueada` = fuera de main / PR

### Comunes / auth

| Rol | Módulo | Pantalla | Ruta | Acceso | Backend | Estado | Permisos | Pruebas | Acción |
|---|---|---|---|---|---|---|---|---|---|
| Todos | Splash | `splash_screen.dart` | `/` | Arranque | — | completa | público | login_flow | mantener |
| Todos | Auth | `login_screen.dart` | `/login` | Splash / redirect | `POST /auth/login`, refresh | completa | público | auth_* | mantener |
| Todos | Auth | `unauthorized_screen.dart` | `/unauthorized` | Guard rol | — | completa | autenticado | — | mantener |
| Todos | Home | `home_screen.dart` | `/inicio` | Fallback | — | completa (poco uso) | autenticado | — | revisar UX |
| — | Shell | `pending_panel_screen.dart` | (sin ruta) | — | — | desconectada | — | — | retirar o conectar |
| STUDENT+ | Auth | Cambio contraseña UI | `/change-password` | — | `POST /auth/change-password` | bloqueada (PR #12; test FE afirma ausencia) | autenticado | change_password_route_test | conectar en fase posterior / PR |
| — | Auth | Forgot/reset UI | — | — | PR #14 | inexistente en main | — | — | fuera de alcance salvo autorización |

### SUPER_ADMIN

| Módulo | Pantalla | Ruta | Acceso dashboard | Backend | Estado | Acción |
|---|---|---|---|---|---|---|
| Panel | `admin_dashboard_screen.dart` | `/admin/dashboard` | post-login | métricas instituciones/usuarios | completa | Etapa B: RootExitScope + push |
| Instituciones | list/create/edit | `/admin/institutions…` | Gestionar instituciones | `/institutions` CRUD | completa | Etapa B: AppNavigation |
| Usuarios | list/create/edit | `/admin/users…` | Gestionar usuarios | `/users` | completa | Etapa B |
| Estudiantes | list/create/detail/edit | `/admin/students…` | Gestionar estudiantes | `/students` | completa | Etapa B |
| Asignaciones | list/create | `/admin/assignments…` | Gestionar asignaciones | `/assignments` | completa | Etapa B (**no eliminar acceso**) |
| Carreras | list/create/edit | `/admin/careers…` | Gestionar carreras | `/careers` | completa | Etapa B |
| Preguntas | list/create/edit | `/admin/questions…` | Gestionar preguntas | `/questions` | completa | Etapa B |
| Vector | `vector_rebuild_screen.dart` | `/admin/vector-rebuild` | Reconstruir índice | `POST /vector/rebuild-careers` | completa | Etapa B |
| Auditoría | list/detail | `/admin/audit…` | Auditoría del sistema | `/audit` | completa | Etapa B; PR #19 mejora redacción |

### INSTITUTION_ADMIN

| Módulo | Pantalla | Ruta | Acceso | Backend | Estado | Acción |
|---|---|---|---|---|---|---|
| Panel | `institution_dashboard_screen.dart` | `/institution/dashboard` | post-login | perfil | completa | Etapa B |
| Estudiantes | mismas pantallas students | `/institution/students…` | panel | `/students` scoped | completa | Etapa B |
| Orientadores | counselor list/create/edit | `/institution/counselors…` | panel | `/users` (COUNSELOR) | completa | Etapa B |
| Asignaciones | assignment list/create | `/institution/assignments…` | panel | `/assignments` | completa | Etapa B |

### COUNSELOR

| Módulo | Pantalla | Ruta | Acceso | Backend | Estado | Acción |
|---|---|---|---|---|---|---|
| Panel | `counselor_dashboard_screen.dart` | `/counselor/dashboard` | post-login | — | completa | Etapa B |
| Estudiantes | list/detail | `/counselor/students…` | panel | `/students` asignados | completa | Etapa B |
| Observaciones | `counselor_session_review_screen.dart` | `…/sessions/:id` | desde detalle | `/observations`, tests/result | completa | Etapa B scopes |

### STUDENT

| Módulo | Pantalla | Ruta | Acceso | Backend | Estado | Acción |
|---|---|---|---|---|---|---|
| Panel | `student_dashboard_screen.dart` | `/student/dashboard` | post-login / menú | `/students/me`, tests | completa | Etapa B RootExit |
| Perfil | `student_profile_screen.dart` | `/student/profile` | menú | `/students/me` | completa | Etapa B |
| Test home | `student_test_home_screen.dart` | `/student/test` | menú | `/tests`, start | completa | mantener push sesiones |
| Test | `vocational_test_screen.dart` | `/student/test/:id` | launcher | answers/finish | completa | PopScope existente |
| Resultado | `vocational_result_screen.dart` | `…/result` | historial | result, recommendations, reports | completa | mantener |
| Resultados | `student_results_screen.dart` | `/student/results` | menú | historial | completa | Etapa B |
| Asistente | `assistant_chat_screen.dart` | `/student/assistant` | menú + dashboard | `/assistant` | completa | **conservar en menú** |

### Rutas / UX — defectos priorizados (Etapa A)

1. **P0 — Navegación con `context.go` en pantallas internas:** borra historial; Atrás de Android cierra la app. Afecta casi todos los listados/formularios/dashboards.
2. **P0 — Sin `RootExitScope` / `InternalRouteScope` en main:** no hay confirmación de salida en raíces ni fallback de área.
3. **P1 — Botón Volver inconsistente** en AppBars internas (muchas dependen del leading por defecto tras `go`).
4. **P1 — UI cambio de contraseña ausente** pese a endpoint BE; test documenta la ausencia a propósito.
5. **P2 — `PendingPanelScreen` sin ruta** (código muerto potencial).
6. **P2 — `RouteNames.profile` (`/profile`)** declarado sin ruta registrada.
7. **P2 — Consistencia visual:** tema básico OK; falta unificar estados vacío/error/loading compartidos y densidad responsive en admin.
8. **P3 — Forgot/reset** solo en PR #14.

## E. Línea base de pruebas

### Flutter (`AVOV-audit-uiux/frontend`)

```text
flutter analyze → No issues found! (2026-10-26)
```

Pruebas existentes (muestra): auth, institutions, users, students, careers, questions, vector, assignments, assistant, observations, vocational, PDF, student navigation, etc.

Línea base parcial ejecutada (2026-10-26):

- `flutter analyze` → **No issues found**
- `flutter test` (muestra): `app_navigation_test`, `login_flow_test`, `auth_login_test` → **All tests passed** (22 assertions/casos en esa corrida)

Pendiente Etapa E: suite completa `flutter test` y `pytest` en `avov_test`.

### Backend

Suite en `backend/tests/` (~28 módulos): auth, roles, CRUD, vocational, recommendations, reports, audit, vector, assistant rate-limit, isolation `avov_test`.

## F. Propuesta de diseño compartido (para Etapa D)

Reutilizar y extender (sin nuevo design system externo):

- `AppColors` / `AppTheme` actuales
- Widgets compartidos: `ConfirmDialog`, futuros `EmptyState`, `ErrorState`, `LoadingScaffold`
- Espaciado base 8/16/24; AppBar primary; cards radius 12
- Navegación: `AppNavigation` + back button + scopes (Etapa B)

## G. Plan de etapas siguientes

| Etapa | Foco |
|---|---|
| **B** | AppNavigation, push interno, Atrás Android, RootExit, leading Volver; tests navegación |
| **C** | Huecos funcionales (change-password si se autoriza portar PR #12; dead code; formularios) |
| **D** | UI/UX global coherente |
| **E** | QA roles + regresión |
| **F** | Informe final + guía móvil |

## H. Veredicto parcial Etapa A

**COMPLETA CON PENDIENTES DOCUMENTADOS** para el inventario: mapa de roles/pantallas/rutas/endpoints realizado por inspección estática del código en `origin/main`; analyze FE sin issues; validación manual en dispositivo y suite completa de tests aún pendientes (Etapas B–E).
