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
| 3 | Cambiar contraseña | `/change-password` | Autenticado | 18 |
| 4 | Perfil usuario | `/profile` | Autenticado | 16 |
| 5 | No autorizado | `/unauthorized` | Todos | 16 |
| 6 | No encontrado | `/not-found` | Todos | 16 |

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
| 16 | Gestión preguntas RIASEC | `/admin/questions` | 10/20 |
| 17 | Rebuild índice Qdrant | `/admin/vector` | 12 |
| 18 | Auditoría | `/admin/audit` | 26 |
| 19 | Configuración sistema | `/admin/settings` | 18 |

---

## 3. Administrador Institucional

| # | Pantalla | Ruta | Fase |
|---|----------|------|------|
| 20 | Dashboard institucional | `/institution/dashboard` | 19 |
| 21 | Lista estudiantes | `/institution/students` | 22 |
| 22 | Crear estudiante | `/institution/students/new` | 22 |
| 23 | Editar estudiante | `/institution/students/:id/edit` | 22 |
| 24 | Perfil estudiante | `/institution/students/:id` | 22 |
| 25 | Gestión orientadores | `/institution/counselors` | 21 |
| 26 | Reportes institución | `/institution/reports` | 24 |
| 27 | Exportaciones | `/institution/exports` | 19 |
| 28 | Config institución | `/institution/settings` | 20 |

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
| 38 | Confirmar finalización | `/student/test/finish` | 23 |
| 39 | Resultados RIASEC | `/student/results` | 24 |
| 40 | Carreras recomendadas | Sección en resultado `/student/test/:id/result` | 24 / S-21 — API `/recommendations` registrada; UI en resultado vocacional |
| 41 | Asistente virtual | `/student/assistant` | 25 |
| 42 | Descargar PDF | Acción en resultados | 24 |

---

## 6. Layout y navegación responsive

### Web / Tablet (≥ 768px)

- `AppScaffold` con sidebar lateral fijo
- Menú contextual según rol
- Contenido en área principal con scroll

### Móvil (< 768px)

- `AppScaffold` con bottom navigation bar
- Drawer opcional para menú secundario
- Formularios en `SingleChildScrollView` con manejo de teclado

---

## 7. Componentes compartidos (`shared/widgets/`)

| Widget | Uso |
|--------|-----|
| `AppScaffold` | Layout principal responsive |
| `LoadingOverlay` | Bloqueo visual durante operaciones |
| `ErrorBanner` | Mensajes de error amigables |
| `PaginatedDataTable` | Listas CRUD con paginación |
| `ConfirmDialog` | Confirmaciones destructivas |
| `SearchBar` | Búsqueda en listas |
| `StatusChip` | Estados ACTIVE/INACTIVE/BLOCKED |
| `RiasecChart` | Gráfico barras RIASEC |
| `ProgressBar` | Progreso del test |
| `LikertScale1to5` | Escala de respuesta 1-5 |
| `EthicalDisclaimerBanner` | Nota ética obligatoria |

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

## Resumen por rol

| Rol | Pantallas |
|-----|-----------|
| Comunes | 6 |
| Super Admin | 13 |
| Institución | 9 |
| Orientador | 5 |
| Estudiante | 9 |
| Componentes | 11 widgets |
| **Total vistas** | **42 pantallas + 11 widgets** |
