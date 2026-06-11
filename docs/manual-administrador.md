# Manual de administrador — AVOV

Guía para **Super Administrador** (`SUPER_ADMIN`) y **Administrador institucional** (`INSTITUTION_ADMIN`).

---

## 1. Super administrador

### 1.1 Panel global

Ruta: `/admin/dashboard`

Métricas: instituciones activas, usuarios, estudiantes, tests completados, reportes generados.

### 1.2 Instituciones

| Acción | Ruta |
|--------|------|
| Listar | `/admin/institutions` |
| Crear | `/admin/institutions/new` |
| Detalle / editar | `/admin/institutions/:id` |

- El **código** de institución debe ser único.
- La baja es lógica (`INACTIVE`); no se eliminan registros con historial.

### 1.3 Usuarios globales

Ruta: `/admin/users`

- Crear usuarios de cualquier rol.
- Asignar institución según rol.
- Cambiar estado (`ACTIVE` / `INACTIVE`).

### 1.4 Catálogo de carreras

Rutas: `/admin/careers`, `/admin/careers/new`, `/admin/careers/:id/edit`

- Al crear, editar o desactivar una carrera, el backend sincroniza Qdrant automáticamente.
- La respuesta indica `vector_synced` (éxito o fallo de sincronización).
- Si Qdrant no está disponible, reconstruye el índice desde **Vector admin**.

### 1.5 Preguntas RIASEC

Rutas: `/admin/questions`, `/admin/questions/new`, `/admin/questions/:id/edit`

- 60 preguntas activas en producción (10 por categoría R, I, A, S, E, C).
- `DELETE` desactiva la pregunta (no borrado físico) para preservar historial de respuestas.

### 1.6 Índice vectorial Qdrant

Ruta: `/admin/vector`

- **Reconstruir índice**: regenera embeddings desde MySQL hacia Qdrant.
- Usar tras fallos de sincronización o restauración de Qdrant.

### 1.7 Auditoría

Ruta: `/admin/audit`

Registra acciones críticas: login, cambios de configuración, PDF, CRUD de carreras/preguntas, etc.

Filtros: `action`, `entity`, paginación.

API detalle: `GET /api/v1/audit/logs/{id}`

### 1.8 Configuración del sistema

Ruta: `/admin/settings`

| Clave | Descripción |
|-------|-------------|
| `app_display_name` | Nombre visible en splash y login |
| `ethical_disclaimer` | Mensaje ético en resultados, PDF y banners |
| `max_recommendations_per_session` | Límite de carreras recomendadas (1–50) |
| `maintenance_mode` | `true` bloquea acceso excepto super admin |

**Configuración pública** (sin autenticación): `GET /api/v1/settings/public`

---

## 2. Administrador institucional

### 2.1 Panel institucional

Ruta: `/institution/dashboard`

Métricas de la propia institución: estudiantes, orientadores, tests, reportes.

### 2.2 Estudiantes

Rutas: `/institution/students`, `/institution/students/new`, `/institution/students/:id`

- Crear estudiantes con usuario asociado (`STUDENT`).
- Asignar orientador desde el detalle del estudiante.
- Solo estudiantes de tu `institution_id`.

### 2.3 Orientadores y usuarios

Ruta: `/institution/users`

- Crear y gestionar `COUNSELOR` e `INSTITUTION_ADMIN` de la institución.
- No puedes crear `SUPER_ADMIN` ni ver otras instituciones.

### 2.4 Reportes

Ruta: `/institution/reports`

- Listado de PDF generados para estudiantes de la institución.
- Descarga con permisos validados en backend.

### 2.5 Exportaciones

Ruta: `/institution/exports`

| Exportación | Formato |
|-------------|---------|
| Estudiantes | CSV |
| Resultados de tests | CSV |

### 2.6 Configuración de la institución

Ruta: `/institution/settings`

- Editar teléfono, correo de contacto, dirección.
- **Subir logo**: imagen vía `image_picker`; se sirve por `/api/v1/media/...`
- Código y estado institucional son solo lectura en esta pantalla.

---

## 3. Credenciales de desarrollo

Ejecutar seeds antes de probar:

```powershell
.\scripts\seed-institution-admin-dev.ps1
.\scripts\seed-counselor-dev.ps1
```

| Rol | Email | Contraseña |
|-----|-------|------------|
| Super Admin | `admin@avov.edu.co` | `Admin123!` |
| Admin institucional | `admin.institucion.test.fase28@instituto.edu.co` | `InstAdmin1234!` |
| Orientador | `orientador.test.fase26@instituto.edu.co` | `Counsel1234!` |
| Estudiante | `estudiante.test.fase11@instituto.edu.co` | `Estud1234!` |

---

## 4. phpMyAdmin (solo desarrollo)

| Campo | Valor |
|-------|-------|
| URL | http://localhost:8081 |
| Usuario | `MYSQL_USER` en `.env` |
| Contraseña | `MYSQL_PASSWORD` en `.env` |

**Nunca exponer phpMyAdmin en internet sin VPN, IP allowlist o autenticación adicional.**

---

## 5. Seguridad administrativa

- Rotar `JWT_SECRET_KEY` y `APP_SECRET_KEY` antes de producción.
- Activar `maintenance_mode` antes de migraciones críticas.
- Revisar auditoría tras cambios en carreras, preguntas o usuarios.
- El login tiene **rate limiting** (5 intentos fallidos / 15 min por IP+correo, configurable).
- DeepSeek API Key solo en backend (`.env`); nunca en Flutter.

---

## 6. Comandos útiles

```powershell
# Levantar stack
docker compose up -d

# Tests backend
docker compose exec -T backend pytest -q

# Flutter
cd frontend
flutter analyze
flutter test

# Android con API en LAN
.\scripts\run-android-device.ps1 -ApiIp <IP_DE_TU_PC>
```
