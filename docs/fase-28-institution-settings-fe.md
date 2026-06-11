# FASE 28 — Configuración institución (Flutter)

## Objetivo

Pantalla para que el **administrador institucional** consulte y actualice los datos de su propia institución.

## Ruta

- `/institution/settings`
- Acceso: rol `INSTITUTION_ADMIN`

## API utilizada

| Método | Endpoint | Uso |
|--------|----------|-----|
| GET | `/institutions/{id}` | Cargar datos de la institución del usuario |
| PUT | `/institutions/{id}` | Guardar cambios (campos limitados para admin institucional) |
| POST | `/institutions/{id}/logo` | Subir logo (PNG, JPG o WEBP, máx. 2 MB) |
| GET | `/media/logos/{filename}` | Servir imagen del logo (público) |

### Restricciones backend (INSTITUTION_ADMIN)

- Solo puede ver/actualizar **su** institución (`institution_id` del usuario).
- **No** puede modificar `code` ni `status`.
- Puede editar: nombre, provincia, ciudad, dirección, teléfono, correo.
- Puede subir logo desde galería (PNG, JPG, WEBP) con `image_picker`.

### URLs de logo unificadas

- Logos subidos por la API se guardan como ruta relativa: `/api/v1/media/logos/...`
- URLs antiguas con `localhost` o `127.0.0.1` se normalizan en la API a ruta relativa.
- URLs externas (`https://cdn...`) se conservan sin cambios.
- En Flutter, `ApiUrlResolver` reescribe rutas relativas y logos locales antiguos usando el `API_BASE_URL` activo (IP LAN en móvil físico).

## Archivos Flutter

```
frontend/lib/features/institutions/
  presentation/screens/institution_settings_screen.dart
  presentation/providers/institution_provider.dart  # institutionSettingsProvider
frontend/lib/core/models/institution.dart         # toInstitutionAdminUpdateJson()
frontend/lib/router/route_names.dart
frontend/lib/router/app_router.dart
frontend/lib/router/role_route_mapper.dart
frontend/lib/features/dashboard/presentation/screens/institution_dashboard_screen.dart
```

## Backend modificado

- `backend/app/api/routes/institutions.py` — PUT permite `INSTITUTION_ADMIN`
- `backend/app/services/institution_service.py` — `_ensure_can_update`
- `backend/tests/test_institutions.py` — tests de permisos admin institucional

## Credenciales de prueba (seed)

```powershell
.\scripts\seed-institution-admin-dev.ps1
```

| Campo | Valor |
|-------|-------|
| Email | `admin.institucion.test.fase28@instituto.edu.co` |
| Contraseña | `InstAdmin1234!` |

Requiere que exista el estudiante `estudiante.test.fase11@instituto.edu.co`.

## Prueba manual

1. Iniciar backend: `docker compose up -d`
2. Ejecutar seed: `.\scripts\seed-institution-admin-dev.ps1`
3. Ejecutar app: `.\scripts\run-android-device.ps1 -ApiIp 192.168.100.140`
4. Login con credenciales del admin institucional.
5. Ir a **Panel institucional** → **Configuración institución**.
6. Verificar que código y estado son solo lectura.
7. **Seleccionar imagen** → **Subir logo** → vista previa actualizada.
8. Cambiar teléfono o correo → **Guardar configuración**.
9. Resultado esperado: mensaje de éxito y datos persistidos al recargar.

## Siguiente fase sugerida

Módulos admin pendientes: catálogo carreras, preguntas RIASEC, auditoría, etc.
