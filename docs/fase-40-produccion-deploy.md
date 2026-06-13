# Fase 40 — Despliegue producción y validación prod-local

## Objetivo

Cerrar el ciclo de despliegue con:

1. **Preflight** de variables antes de levantar producción.
2. **Stack prod-local** aislado (puerto 8090, proyecto `avov-prod-local`) sin tocar `.env` de desarrollo.
3. **Validación automatizada** de health, seguridad (OpenAPI bloqueado), smoke E2E y backups.
4. **Script Linux** para servidor real.

---

## Archivos creados

| Archivo | Descripción |
|---------|-------------|
| `.env.prod-local.example` | Variables prod local (puerto 8090) |
| `docker-compose.prod-local.yml` | Override `env_file: .env.prod-local` |
| `scripts/preflight-prod.ps1` | Valida secretos, CORS, APP_DEBUG, DATABASE_URL |
| `scripts/prod-local-up.ps1` | Levanta prod-local con preflight |
| `scripts/prod-local-down.ps1` | Detiene prod-local |
| `scripts/validate-prod-deploy.ps1` | Orquestador Fase 40 |
| `scripts/deploy-prod.sh` | Despliegue Linux (preflight + compose prod) |
| `docs/fase-40-produccion-deploy.md` | Este documento |

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `scripts/prod-up.ps1` | Ejecuta preflight antes de `docker compose up` |
| `scripts/backup-all.ps1` | Target `-Target prod-local` |
| `scripts/backup-mysql.ps1` | Switch `-ProdLocal` |
| `scripts/backup-qdrant.ps1` | Switch `-ProdLocal` |
| `scripts/verify-structure.ps1` | Archivos Fase 40 en checklist |
| `.gitignore` | Ignora `.env.prod-local` |
| `docs/plan-desarrollo.md` | Fase 40 completada |
| `docs/checklist-qa.md` | Sección validación prod deploy |
| `docs/manual-produccion.md` | Preflight y prod-local |
| `README.md` | Comandos Fase 40 |

---

## Stacks Docker coexistiendo

| Proyecto | Puerto Nginx | Env file |
|----------|--------------|----------|
| dev | 8000 (backend directo) | `.env` |
| avov-staging | 8080 | `.env.staging` |
| avov-prod-local | 8090 | `.env.prod-local` |
| avov-prod (real) | 80 | `.env` |

---

## Comandos

### Preflight (sin Docker)

```powershell
.\scripts\preflight-prod.ps1 -EnvFile ".env"
.\scripts\preflight-prod.ps1 -EnvFile ".env.prod-local"
```

### Prod-local manual

```powershell
Copy-Item .env.prod-local.example .env.prod-local
.\scripts\prod-local-up.ps1
.\scripts\smoke-e2e.ps1 -BaseUrl "http://localhost:8090/api/v1" -EnsureStudentSeed
.\scripts\backup-all.ps1 -Target prod-local
.\scripts\prod-local-down.ps1
```

### Validación integral Fase 40

```powershell
.\scripts\validate-prod-deploy.ps1
.\scripts\validate-prod-deploy.ps1 -SkipTeardown
```

Reporte: `docs/fase-40-prod-deploy-validation.txt`

### Producción real (Windows)

```powershell
Copy-Item .env.production.example .env
# Editar claves y dominios
.\scripts\prod-up.ps1
```

### Producción real (Linux)

```bash
chmod +x scripts/deploy-prod.sh
AVOV_ENV_FILE=.env ./scripts/deploy-prod.sh
# Con SSL:
AVOV_PROD_SSL=1 ./scripts/deploy-prod.sh
```

---

## Validaciones del preflight

- Claves `APP_SECRET_KEY` y `JWT_SECRET_KEY` ≥ 32 caracteres, sin placeholders.
- `APP_DEBUG=false`.
- `BACKEND_CORS_ORIGINS` sin `*`.
- `DATABASE_URL` coherente con `MYSQL_PASSWORD`.
- Advertencia (no bloquea) si `DEEPSEEK_API_KEY` es placeholder.

---

## Criterios de éxito Fase 40

1. `preflight-prod.ps1` pasa con `.env.prod-local`.
2. Stack prod-local responde en `:8090/api/v1/health/live`.
3. `/docs` retorna 404 vía Nginx.
4. Smoke E2E (17 checks) pasa vía Nginx prod-local.
5. Backup MySQL + Qdrant + storage con `-Target prod-local`.
6. Reporte generado sin fallos.

**Última ejecución:** 9 OK / 0 FALLO — ver [fase-40-prod-deploy-validation.txt](fase-40-prod-deploy-validation.txt) y [fase-40-prod-smoke-report.txt](fase-40-prod-smoke-report.txt).

---

## Próximo paso sugerido

Despliegue en servidor real siguiendo [manual-produccion.md](manual-produccion.md), pruebas UI Flutter manuales del checklist QA, y configuración SSL con certificados reales.
