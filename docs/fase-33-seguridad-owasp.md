# FASE 33 — Hardening OWASP y validación runtime

## 1. Resumen

Se completó el **hardening de seguridad** pendiente de la Fase 29: cabeceras HTTP OWASP en la API, validación de secretos al arrancar en producción, rate limiting ampliado (recuperación de contraseña, restablecimiento y asistente IA) y pruebas automatizadas de seguridad.

## 2. Archivos creados

| Archivo | Descripción |
|---------|-------------|
| `backend/app/security/middleware.py` | `SecurityHeadersMiddleware` y `TrustedHostMiddleware` en producción |
| `backend/app/core/startup.py` | Validación de configuración en `APP_ENV=production` |
| `backend/tests/test_security.py` | Pruebas de cabeceras, producción y rate limit del asistente |
| `docs/fase-33-seguridad-owasp.md` | Este entregable |

## 3. Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `backend/app/security/rate_limit.py` | `RedisRateLimiter` genérico con 4 instancias |
| `backend/app/main.py` | Lifespan + middleware de seguridad |
| `backend/app/core/config.py` | Nuevas variables de rate limit y hosts |
| `backend/app/api/routes/auth.py` | Rate limit dedicado forgot/reset password |
| `backend/app/api/routes/assistant.py` | Cuota por usuario en endpoints IA |
| `frontend/test/widget_test.dart` | Test de arranque sin timers pendientes |
| `.env.example` / `.env.production.example` | Variables documentadas |
| `docs/plan-desarrollo.md` | Fase 29 seguridad marcada como completada |

## 4. Validaciones realizadas

| Verificación | Resultado |
|--------------|-----------|
| `docker compose exec backend pytest tests/test_security.py -q` | 5 passed |
| `docker compose exec backend pytest -q` | 164 passed |
| `flutter analyze` / `flutter test` | OK (20 tests) |
| `validate-fase32.ps1` con Docker activo | 15/15 OK (incl. health runtime) |
| Cabeceras en `/api/v1/health/live` | `X-Content-Type-Options`, `X-Frame-Options`, etc. |
| Arranque producción con secretos débiles | `RuntimeError` controlado |

## 5. Comandos sugeridos

```powershell
docker compose up -d
docker compose exec -T backend pytest tests/test_security.py -q
docker compose exec -T backend pytest -q
curl -I http://localhost:8000/api/v1/health/live
.\scripts\validate-fase32.ps1
```

## 6. Errores encontrados

Ninguno en implementación. La validación runtime con Docker debe repetirse en el entorno del equipo.

## 7. Estado final

**Fase 33 completada** — hardening OWASP operativo en backend. Nginx en producción mantiene sus propios headers (`nginx/snippets/security-headers.conf`); la API añade defensa en profundidad también en desarrollo.

## 8. Próximo paso

- Marcar ítems E2E en [checklist-qa.md](checklist-qa.md)
- Despliegue staging según [manual-produccion.md](manual-produccion.md)
- Monitoreo post-despliegue
