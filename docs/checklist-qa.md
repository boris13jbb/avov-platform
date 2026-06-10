# Checklist QA — AVOV

## Fase 1 — Fundación del monorepo

- [ ] `docker compose up --build` levanta todos los servicios
- [ ] `GET /api/v1/health/live` responde `success: true`
- [ ] `GET /api/v1/health` muestra estado de mysql, redis, qdrant
- [ ] phpMyAdmin accesible en puerto 8081
- [ ] `python -m pytest` pasa en backend
- [ ] `flutter analyze` sin errores (requiere Flutter SDK)
- [ ] `flutter test` pasa (requiere Flutter SDK)
- [ ] `.env` no está en el repositorio
- [ ] Documentación base en `docs/` existe

## Fases posteriores

Se ampliará con pruebas de auth, roles, test vocacional, PDF y más.
