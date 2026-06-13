# Checklist QA — AVOV

Lista de verificación para validar el sistema antes de entrega o despliegue. Marca cada ítem tras comprobarlo.

## Validación automatizada (Fase 32)

Ejecutar:

```powershell
.\scripts\validate-fase32.ps1
```

**Última ejecución documentada:** ver [fase-32-validation-report.txt](fase-32-validation-report.txt)

| Verificación automática | Resultado |
|-------------------------|-----------|
| Estructura monorepo | OK |
| 15 criterios estáticos del plan | OK |
| `flutter analyze` | OK |
| `flutter test` (18 tests) | OK |
| `docker compose prod config` | OK |
| `docker pytest` / health runtime | OK (validado con Docker activo — ver `fase-32-validation-report.txt`) |

## Validación smoke E2E (Fase 35)

Ejecutar con Docker activo:

```powershell
.\scripts\smoke-e2e.ps1
# Si falta el estudiante de prueba:
.\scripts\smoke-e2e.ps1 -EnsureStudentSeed
```

**Última ejecución documentada:** ver [fase-35-e2e-smoke-report.txt](fase-35-e2e-smoke-report.txt)

| Verificación smoke API | Resultado |
|------------------------|-----------|
| Health + OWASP headers | OK |
| Auth (login, me, refresh, 401) | OK |
| Roles (403 estudiante) | OK |
| Dashboards super admin / estudiante | OK |
| Test RIASEC (preguntas + sesión) | OK |

## Validación staging (Fase 36)

Ejecutar (levanta stack prod local en puerto 8080, valida y detiene):

```powershell
.\scripts\validate-staging.ps1
# Mantener stack activo tras validar:
.\scripts\validate-staging.ps1 -SkipTeardown
```

**Última ejecución documentada:** ver [fase-36-staging-validation.txt](fase-36-staging-validation.txt)

| Verificación staging | Resultado |
|----------------------|-----------|
| Nginx proxy `/api/v1/health/live` | OK |
| OpenAPI `/docs` bloqueado (404) | OK |
| Cabeceras seguridad Nginx | OK |
| Smoke E2E vía puerto 8080 | OK |
| Backup MySQL + Qdrant staging | OK |

## Validación Flutter QA (Fase 37)

```powershell
.\scripts\validate-flutter-qa.ps1
```

**Última ejecución documentada:** ver [fase-37-flutter-qa-report.txt](fase-37-flutter-qa-report.txt)

| Verificación Flutter | Resultado |
|----------------------|-----------|
| `flutter analyze` | OK |
| `flutter test` (41 tests, navegación + roles) | OK |
| Redirección `/unauthorized` (lógica) | OK |
| Pantalla mantenimiento + login dinámico | OK |

## Validación flujo vocacional E2E (Fase 38)

```powershell
docker compose up -d
.\scripts\validate-vocational-e2e.ps1
```

**Última ejecución documentada:** ver [fase-38-vocational-e2e-report.txt](fase-38-vocational-e2e-report.txt)

| Verificación vocacional API | Resultado |
|-----------------------------|-----------|
| 60 respuestas + finalizar RIASEC | OK |
| Bloqueo edición post-finalizar | OK |
| Recomendaciones + disclaimer ético | OK |
| PDF válido + historial | OK |

## Validación release (Fase 39)

```powershell
# Completa (staging + vocacional + todo)
.\scripts\validate-release.ps1

# Rápida (estático + flutter + smoke dev)
.\scripts\validate-release.ps1 -Quick
```

| Verificación release | Resultado |
|----------------------|-----------|
| Orquestador Quick | 8 OK / 2 SKIP |
| Prod config + .gitignore | OK |
| Fase 32 + Flutter + Smoke | OK |

## Validación prod deploy (Fase 40)

```powershell
.\scripts\validate-prod-deploy.ps1
.\scripts\validate-prod-deploy.ps1 -SkipTeardown
```

| Verificación prod-local | Resultado |
|-------------------------|-----------|
| Preflight `.env.prod-local` | OK |
| Health vía Nginx :8090 | OK |
| OpenAPI `/docs` → 404 | OK |
| Smoke E2E 17 checks | OK |
| Backup `-Target prod-local` | OK |

Reporte: [fase-40-prod-deploy-validation.txt](fase-40-prod-deploy-validation.txt)

---

## Validación SSL + post-deploy (Fase 41)

```powershell
.\scripts\validate-prod-ssl-deploy.ps1
```

| Verificación prod-ssl-local | Resultado |
|-----------------------------|-----------|
| Certificados dev + preflight | OK |
| HTTPS :8443 health | OK |
| Redirect HTTP :8180 → HTTPS | OK |
| Post-deploy (Qdrant rebuild) | OK |
| Smoke reducido HTTPS | OK |

Reportes: [fase-41-prod-ssl-validation.txt](fase-41-prod-ssl-validation.txt), [fase-41-post-deploy-report.txt](fase-41-post-deploy-report.txt)

Checklist UI Flutter manual: [fase-41-flutter-ui-manual.md](fase-41-flutter-ui-manual.md)

---

## Validación release servidor (Fase 42)

```powershell
.\scripts\validate-server-release.ps1
```

| Verificación server release | Resultado |
|----------------------------|-----------|
| Preflight servidor HTTPS/CORS | OK |
| Compose prod + web + ssl | OK |
| Flutter analyze + test | OK |
| Flutter build web | OK |
| Checklist UI manual documentado | OK |

Reporte: [fase-42-server-release-validation.txt](fase-42-server-release-validation.txt)

---

## Validación operaciones VPS (Fase 43)

```powershell
.\scripts\validate-vps-readiness.ps1
```

| Verificación VPS | Resultado |
|------------------|-----------|
| Scripts backup/prune/monitor | OK (9 archivos) |
| Sintaxis bash | SKIP (Windows sin bash utilizable) |
| Prune dry-run | OK |
| Monitor health API | OK |
| Plantilla cron VPS | OK |
| Checklist UI manual | OK |

Reporte: [fase-43-vps-readiness-validation.txt](fase-43-vps-readiness-validation.txt) — **5 OK / 2 SKIP / 0 FALLO**

Documentación: [fase-43-vps-operaciones.md](fase-43-vps-operaciones.md)

---

## Validación despliegue institucional (Fase 44)

```powershell
.\scripts\prod-institutional-local-up.ps1
.\scripts\validate-institutional-deploy.ps1 -SkipTlsVerify
```

| Verificación institucional | Resultado |
|----------------------------|-----------|
| Stack local Web+API+SSL | OK |
| Smoke public release | OK (9/9) |
| Preflight servidor | OK |
| Deploy VPS script | OK |
| Plantilla checklist UI | OK |

Reporte: [fase-44-institutional-deploy-validation.txt](fase-44-institutional-deploy-validation.txt) — **8 OK / 0 FALLO**

Documentación: [fase-44-despliegue-institucional.md](fase-44-despliegue-institucional.md)

---

## Validación soporte y rollback (Fase 45)

```powershell
.\scripts\validate-production-ops.ps1
```

| Verificación ops producción | Resultado |
|----------------------------|-----------|
| Scripts update/rollback/restore | OK |
| Plan rollback documentado | OK |
| Runbook soporte | OK |
| Capacitación TI (5 módulos) | OK |

Reporte: [fase-45-production-ops-validation.txt](fase-45-production-ops-validation.txt) — **8 OK / 1 SKIP / 0 FALLO**

Documentación: [fase-45-soporte-rollback-capacitacion.md](fase-45-soporte-rollback-capacitacion.md)

---

## A. Infraestructura

### Desarrollo

- [x] `docker compose up --build -d` levanta todos los servicios sin error *(smoke E2E OK)*

### Producción

- [x] `docker compose -f docker-compose.prod.yml config` sin errores *(Fase 39 release)*
- [x] Stack prod local validado vía staging Nginx *(Fase 36/39)*
- [x] Stack prod-local aislado `:8090` validado *(Fase 40)*
- [x] Preflight producción antes de deploy *(Fase 40 — preflight-prod.ps1)*
- [x] `GET /api/v1/health/live` vía Nginx *(Fase 36 staging / Fase 40 prod-local)*
- [x] `/docs` retorna 404 en producción *(Fase 36 staging / Fase 40 prod-local)*
- [x] phpMyAdmin **no** está en el stack prod *(Fase 39 release)*
- [x] `.\scripts\backup-all.ps1 -Target staging` genera backups *(Fase 36)*
- [x] `.\scripts\backup-all.ps1 -Target prod-local` genera backups *(Fase 40)*
- [x] `GET /api/v1/health/live` → `success: true` *(smoke E2E)*
- [x] `GET /api/v1/health` → MySQL, Redis y Qdrant en estado aceptable *(smoke E2E)*
- [ ] phpMyAdmin accesible solo en desarrollo (puerto 8081)
- [x] `.env` no está en el repositorio *(verificado .gitignore — Fase 39)*
- [ ] Variables críticas definidas (JWT, MySQL, DeepSeek)

---

## B. Autenticación y seguridad

- [x] Login exitoso retorna `access_token` y `refresh_token` *(smoke E2E)*
- [x] Credenciales incorrectas → 401 mensaje genérico *(smoke E2E)*
- [ ] Usuario inactivo → 401 con mensaje de cuenta inactiva
- [ ] Tras 5 intentos fallidos (por defecto) → 429 rate limit
- [x] `GET /auth/me` requiere Bearer token *(smoke E2E)*
- [x] Refresh token renueva access *(smoke E2E)*
- [ ] Logout revoca refresh token
- [ ] Cambio de contraseña valida requisitos de seguridad
- [ ] Recuperación: `/forgot-password` respuesta genérica
- [ ] Restablecimiento: `/reset-password` con token válido
- [ ] Modo mantenimiento bloquea login de no super admin
- [ ] Super admin accede durante mantenimiento

---

## C. Roles y permisos

- [x] `SUPER_ADMIN` accede a dashboard y CRUD *(smoke E2E parcial)*
- [ ] `INSTITUTION_ADMIN` solo ve su institución
- [ ] `COUNSELOR` solo ve estudiantes asignados
- [x] `STUDENT` bloqueado en `/students` y `/settings` *(smoke E2E)*
- [x] Ruta no permitida → `/unauthorized` en Flutter *(AuthRedirectLogic + widget test Fase 37)*
- [ ] API retorna 403 al acceder a recurso de otra institución

---

## D. Instituciones y usuarios

- [ ] CRUD instituciones (super admin)
- [ ] CRUD usuarios con roles válidos
- [ ] Desactivación lógica de usuarios
- [ ] Logo institucional: subida y visualización en móvil (URL resuelta)

---

## E. Estudiantes

- [ ] Alta de estudiante con usuario STUDENT
- [ ] Asignación de orientador
- [ ] Autogestión de perfil por estudiante
- [ ] Listados filtrados por institución

---

## F. Test vocacional RIASEC

- [x] 60+ preguntas activas disponibles *(smoke E2E: 61 en dev)*
- [x] Inicio de sesión de test *(smoke E2E)*
- [x] Guardado de respuestas escala 1–5 *(Fase 38 E2E)*
- [x] No finalizar test incompleto *(pytest + lógica backend; finish exige 60 respuestas)*
- [x] Continuar test en progreso *(Fase 38 E2E)*
- [x] Cálculo de puntajes y perfil dominante/secundario al finalizar *(Fase 38 E2E)*
- [x] Test finalizado no editable sin permiso especial *(Fase 38 E2E: 422)*

---

## G. Recomendaciones e IA

- [x] Generación de recomendaciones post-test *(Fase 38 E2E)*
- [ ] Fallback MySQL si Qdrant no disponible
- [x] Explicación IA o fallback básico *(Fase 38 E2E)*
- [x] Mensaje ético presente en respuestas *(Fase 38 E2E)*
- [ ] Asistente chat contextualizado (test + recomendaciones)

---

## H. Reportes PDF

- [x] Generación PDF con datos completos *(Fase 38 E2E)*
- [x] Código único de reporte *(header X-Report-Code en descarga)*
- [x] Descarga autorizada por rol *(estudiante propio test — Fase 38)*
- [ ] Observaciones del orientador en PDF
- [ ] Auditoría de generación y descarga

---

## I. Dashboards

- [x] Dashboard super admin con métricas globales *(smoke E2E)*
- [ ] Dashboard institución
- [ ] Dashboard orientador
- [x] Dashboard estudiante responde *(smoke E2E)*
- [ ] `download_pdf` visible con reporte existente

---

## J. Admin global

- [ ] CRUD carreras + `vector_synced`
- [ ] CRUD preguntas + DELETE lógico
- [ ] Rebuild índice Qdrant
- [ ] Auditoría listado y detalle
- [ ] Configuración sistema editable
- [x] `GET /settings/public` sin auth *(smoke E2E)*

---

## K. Exportaciones

- [ ] Export CSV estudiantes (admin institución)
- [ ] Export CSV resultados (admin / orientador según permiso)

---

## L. Frontend Flutter

- [x] `flutter analyze` sin errores *(Fase 37)*
- [x] `flutter test` pasa *(Fase 37)*
- [x] Login muestra `app_display_name` dinámico *(Fase 37)*
- [ ] Splash redirige según sesión y mantenimiento
- [ ] `EthicalDisclaimerBanner` usa disclaimer del servidor
- [ ] Responsive en móvil, tablet y web
- [ ] Sin overflow en formularios largos
- [ ] SafeArea y teclado en pantallas de login/formularios

---

## M. Pruebas automatizadas backend

```powershell
docker compose exec -T backend pytest -q
```

- [ ] `test_auth.py` — incluye rate limit
- [ ] `test_vocational_test.py`
- [ ] `test_recommendations.py`
- [ ] `test_reports.py`
- [ ] `test_dashboard.py`
- [ ] `test_system_settings.py`
- [ ] `test_careers.py` / `test_questions.py`

---

## N. Documentación

- [ ] [manual-usuario.md](manual-usuario.md) actualizado
- [ ] [manual-administrador.md](manual-administrador.md) actualizado
- [ ] [manual-produccion.md](manual-produccion.md) actualizado
- [ ] [api-endpoints.md](api-endpoints.md) alineado con implementación
- [ ] [variables-entorno.md](variables-entorno.md) completo

---

## O. Criterios de aceptación final (Fase 32)

Referencia: [plan-desarrollo.md](plan-desarrollo.md) § Criterio de calidad final.

- [x] Los 15 criterios del plan formal validados por `validate-fase32.ps1` *(incluido en Fase 39 release)*
