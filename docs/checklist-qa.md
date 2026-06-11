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
| `docker pytest` / health runtime | Pendiente si Docker no está activo |

---

## A. Infraestructura

### Desarrollo

- [ ] `docker compose up --build -d` levanta todos los servicios sin error

### Producción

- [ ] `docker compose -f docker-compose.prod.yml config` sin errores de sintaxis
- [ ] `.\scripts\prod-up.ps1` levanta MySQL, Redis, Qdrant, backend y Nginx
- [ ] `GET http://localhost/api/v1/health/live` responde vía Nginx
- [ ] `/docs` retorna 404 en producción
- [ ] phpMyAdmin **no** está en el stack prod
- [ ] `.\scripts\backup-all.ps1 -Target prod` genera archivos en `backups/`
- [ ] `GET /api/v1/health/live` → `success: true`
- [ ] `GET /api/v1/health` → MySQL, Redis y Qdrant en estado aceptable
- [ ] phpMyAdmin accesible solo en desarrollo (puerto 8081)
- [ ] `.env` no está en el repositorio
- [ ] Variables críticas definidas (JWT, MySQL, DeepSeek)

---

## B. Autenticación y seguridad

- [ ] Login exitoso retorna `access_token` y `refresh_token`
- [ ] Credenciales incorrectas → 401 mensaje genérico
- [ ] Usuario inactivo → 401 con mensaje de cuenta inactiva
- [ ] Tras 5 intentos fallidos (por defecto) → 429 rate limit
- [ ] `GET /auth/me` requiere Bearer token
- [ ] Refresh token renueva access y revoca el anterior
- [ ] Logout revoca refresh token
- [ ] Cambio de contraseña valida requisitos de seguridad
- [ ] Recuperación: `/forgot-password` respuesta genérica
- [ ] Restablecimiento: `/reset-password` con token válido
- [ ] Modo mantenimiento bloquea login de no super admin
- [ ] Super admin accede durante mantenimiento

---

## C. Roles y permisos

- [ ] `SUPER_ADMIN` accede a `/admin/*`
- [ ] `INSTITUTION_ADMIN` solo ve su institución
- [ ] `COUNSELOR` solo ve estudiantes asignados
- [ ] `STUDENT` solo ve su perfil, test y resultados
- [ ] Ruta no permitida → `/unauthorized` en Flutter
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

- [ ] 60 preguntas activas disponibles
- [ ] Inicio de sesión de test
- [ ] Guardado de respuestas escala 1–5
- [ ] No finalizar test incompleto
- [ ] Continuar test en progreso
- [ ] Cálculo de puntajes y perfil dominante/secundario al finalizar
- [ ] Test finalizado no editable sin permiso especial

---

## G. Recomendaciones e IA

- [ ] Generación de recomendaciones post-test
- [ ] Fallback MySQL si Qdrant no disponible
- [ ] Explicación IA o fallback básico
- [ ] Mensaje ético presente en respuestas
- [ ] Asistente chat contextualizado (test + recomendaciones)

---

## H. Reportes PDF

- [ ] Generación PDF con datos completos
- [ ] Código único de reporte
- [ ] Descarga autorizada por rol
- [ ] Observaciones del orientador en PDF
- [ ] Auditoría de generación y descarga

---

## I. Dashboards

- [ ] Dashboard super admin con métricas globales
- [ ] Dashboard institución
- [ ] Dashboard orientador
- [ ] Dashboard estudiante con `next_actions` correctas
- [ ] `download_pdf` visible con reporte existente

---

## J. Admin global

- [ ] CRUD carreras + `vector_synced`
- [ ] CRUD preguntas + DELETE lógico
- [ ] Rebuild índice Qdrant
- [ ] Auditoría listado y detalle
- [ ] Configuración sistema editable
- [ ] `GET /settings/public` sin auth

---

## K. Exportaciones

- [ ] Export CSV estudiantes (admin institución)
- [ ] Export CSV resultados (admin / orientador según permiso)

---

## L. Frontend Flutter

- [ ] `flutter analyze` sin errores
- [ ] `flutter test` pasa
- [ ] Splash redirige según sesión y mantenimiento
- [ ] Login muestra `app_display_name` dinámico
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

- [ ] Los 15 criterios del plan formal aprobados por stakeholders
