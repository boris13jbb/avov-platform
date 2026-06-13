# Pantallas Flutter — AVOV

**Fase:** 0 — Diseño de navegación  
**Router:** GoRouter con `auth_guard` y redirección por rol  
**Total planificado:** ~45 pantallas/vistas

---

## Convenciones de rutas

| Tipo | Patrón | Ejemplo |
|------|--------|---------|
| Pública | Sin guard | `/login` |
| Protegida | `auth_guard` | `/profile` |
| Por rol | `role_guard` | `/admin/dashboard` |
| Parámetro | `:id` | `/admin/institutions/:id` |

### Redirección post-login

| Rol | Ruta destino |
|-----|--------------|
| SUPER_ADMIN | `/admin/dashboard` |
| INSTITUTION_ADMIN | `/institution/dashboard` |
| COUNSELOR | `/counselor/dashboard` |
| STUDENT | `/student/dashboard` |

---

## 1. Comunes / Autenticación

| # | Pantalla | Ruta | Rol | Fase |
|---|----------|------|-----|------|
| 1 | Splash | `/` | Todos | 16 |
| 2 | Login | `/login` | Público | 18 |
| 3 | Recuperar contraseña | `/forgot-password` | Público | 33 |
| 4 | Restablecer contraseña | `/reset-password?token=` | Público | 33 |
| 5 | Cambiar contraseña | `/change-password` | Autenticado | 18 |
| 6 | Perfil usuario | `/profile` | Autenticado | 16 |
| 7 | No autorizado | `/unauthorized` | Todos | 16 |
| 8 | No encontrado | `/not-found` | Todos | 16 |
| 9 | Mantenimiento | `/maintenance` | Público | 30 |

---

## 2. Super Administrador

| # | Pantalla | Ruta | Fase |
|---|----------|------|------|
| 7 | Dashboard global | `/admin/dashboard` | 19 |
| 8 | Lista instituciones | `/admin/institutions` | 20 |
| 9 | Crear institución | `/admin/institutions/new` | 20 |
| 10 | Editar institución | `/admin/institutions/:id/edit` | 20 |
| 11 | Detalle institución | `/admin/institutions/:id` | 20 |
| 12 | Lista usuarios global | `/admin/users` | 21 |
| 13 | Crear usuario | `/admin/users/new` | 21 |
| 14 | Editar usuario | `/admin/users/:id/edit` | 21 |
| 15 | Catálogo carreras | `/admin/careers` | 9/20 |
| 16 | Detalle carrera | `/admin/careers/:id` | 20 |
| 17 | Gestión preguntas RIASEC | `/admin/questions` | 10/20 |
| 18 | Detalle pregunta | `/admin/questions/:id` | 20 |
| 19 | Rebuild índice Qdrant | `/admin/vector` | 12 |
| 20 | Auditoría (lista) | `/admin/audit` | 26 |
| 21 | Detalle auditoría | `/admin/audit/:id` | 30 |
| 22 | Configuración sistema | `/admin/settings` | 18 |

---

## 3. Administrador Institucional

| # | Pantalla | Ruta | Fase |
|---|----------|------|------|
| 20 | Dashboard institucional | `/institution/dashboard` | 19 |
| 21 | Lista estudiantes | `/institution/students` | 22 |
| 22 | Crear estudiante | `/institution/students/new` | 22 |
| 23 | Editar estudiante | `/institution/students/:id/edit` | 22 |
| 24 | Perfil estudiante | `/institution/students/:id` | 22 |
| 25 | Lista orientadores | `/institution/counselors` | 21 |
| 26 | Crear orientador | `/institution/counselors/new` | 21 |
| 27 | Detalle orientador | `/institution/counselors/:id` | 21 |
| 28 | Editar orientador | `/institution/counselors/:id/edit` | 21 |
| 29 | Reportes institución | `/institution/reports` | 24 |
| 30 | Exportaciones | `/institution/exports` | 19 |
| 31 | Config institución | `/institution/settings` | 20 |

---

## 4. Orientador

| # | Pantalla | Ruta | Fase |
|---|----------|------|------|
| 29 | Dashboard orientador | `/counselor/dashboard` | 19 |
| 30 | Estudiantes asignados | `/counselor/students` | 22 |
| 31 | Resultado vocacional | `/counselor/students/:id/results` | 24 |
| 32 | Agregar observación | `/counselor/students/:id/observation` | 24 |
| 33 | Descargar reporte | Modal en resultados | 24 |

---

## 5. Estudiante

| # | Pantalla | Ruta | Fase |
|---|----------|------|------|
| 34 | Dashboard estudiante | `/student/dashboard` | 19 |
| 35 | Completar perfil | `/student/profile` | 22 |
| 36 | Instrucciones test | `/student/test/instructions` | 23 |
| 37 | Test vocacional | `/student/test/session/:id` | 23 |
| 38 | Confirmar finalización | `/student/test/finish/:id` | 23 |
| 39 | Resultados RIASEC | `/student/results` | 24 |
| 40 | Carreras recomendadas | `/student/recommendations` | 24 |
| 41 | Asistente virtual | `/student/assistant` | 25 |
| 42 | Descargar PDF | Acción en resultados | 24 |

---

## 6. Layout y navegación responsive

### Web / Tablet (≥ 768px)

- `DashboardShell` con barra superior y acciones por rol
- Menú contextual desde cada dashboard
- Contenido en área principal con scroll

### Móvil (< 768px)

- `DashboardShell` responsive (misma estructura adaptada)
- Formularios en `SingleChildScrollView` con manejo de teclado

> **Nota:** `AppScaffold` existe en `shared/widgets/` como base reutilizable; las pantallas operativas usan `DashboardShell`.

---

## 7. Componentes compartidos (`shared/widgets/`)

| Widget | Uso | Estado |
|--------|-----|--------|
| `AppScaffold` | Layout base (sidebar/drawer) | Disponible, no integrado globalmente |
| `DashboardShell` | Layout operativo de dashboards | **En uso** |
| `AdminPaginatedList` | Listas CRUD admin con paginación | **En uso** |
| `DashboardErrorMessage` | Errores en dashboards | **En uso** |
| `ScaleAnswerSelector` | Escala Likert 1-5 del test | **En uso** |
| `EthicalDisclaimerBanner` | Nota ética (texto desde API) | **En uso** |
| `LoadingOverlay` | Bloqueo visual durante operaciones | Planificado |
| `PaginatedDataTable` | Tabla genérica paginada | Sustituido por listas por feature |
| `RiasecChart` | Gráfico barras RIASEC | **En uso** (resultados estudiante y orientador) |

---

## 8. Mapa de rutas GoRouter (estructura)

```dart
// Estructura planificada — implementación Fase 16+
GoRouter(
  routes: [
    GoRoute(path: '/', builder: SplashScreen),
    GoRoute(path: '/login', builder: LoginScreen),
    ShellRoute(
      builder: AppScaffold,
      routes: [
        // Super Admin
        GoRoute(path: '/admin/dashboard', ...),
        GoRoute(path: '/admin/institutions', ...),
        // Institution Admin
        GoRoute(path: '/institution/dashboard', ...),
        // Counselor
        GoRoute(path: '/counselor/dashboard', ...),
        // Student
        GoRoute(path: '/student/dashboard', ...),
        GoRoute(path: '/student/test/session/:id', ...),
      ],
    ),
  ],
  redirect: authGuard,
);
```

---

## 9. Rutas auxiliares

| Pantalla | Ruta | Notas |
|----------|------|-------|
| Inicio (health check) | `/inicio` | Legacy; usuarios autenticados redirigen al dashboard |

## 10. Funcionalidades post-MVP ya implementadas

| Funcionalidad | Estado |
|---------------|--------|
| Recuperación de contraseña | Implementada (`/forgot-password`, `/reset-password`) |
| Gráfico RIASEC (`RiasecChart`) | Implementado en resultados estudiante y orientador |
| Hardening OWASP (Fase 33) | Cabeceras HTTP, rate limits ampliados, validación prod |

---

## Resumen por rol (auditoría 2026-06)

| Rol | Pantallas implementadas |
|-----|-------------------------|
| Comunes | 8 (incl. mantenimiento y cambio de contraseña) |
| Super Admin | 18 (incl. formularios carrera/pregunta) |
| Institución | 12 |
| Orientador | 5 |
| Estudiante | 10 (incl. perfil autogestionado) |
| Auxiliar | 1 (`/inicio`, legacy) |
| **Total archivos `*_screen.dart`** | **45** |

**Estado:** Todas las pantallas del plan operativo están implementadas y enrutadas en `app_router.dart`. La protección por rol usa `AuthGuard` + `RoleRouteMapper`: rutas no permitidas redirigen a `/unauthorized`; sesión sin rol válido fuerza re-login.
