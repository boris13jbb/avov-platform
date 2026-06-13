# Fase 41 — Servidor real, SSL y post-despliegue

## Objetivo

Completar la preparación para **servidor de producción real** con:

1. Simulación **prod-ssl-local** (Nginx HTTPS + redirect HTTP + cert autofirmado).
2. Script **post-deploy** (salud, settings, login admin, rebuild Qdrant, HSTS).
3. Script **Linux** para servidor (`post-deploy-prod.sh`, integrado en flujo deploy).
4. Checklist manual Flutter UI para QA visual pre-release.

---

## Archivos creados

| Archivo | Descripción |
|---------|-------------|
| `.env.prod-ssl-local.example` | Variables SSL local (8180/8443) |
| `docker-compose.prod-ssl-local.yml` | Override prod + SSL + env aislado |
| `scripts/_tls_helpers.ps1` | Helper certificados autofirmados |
| `scripts/generate-dev-ssl-certs.ps1` | Genera `nginx/certs/*.pem` |
| `scripts/prod-ssl-local-up.ps1` | Levanta stack HTTPS local |
| `scripts/prod-ssl-local-down.ps1` | Detiene stack |
| `scripts/post-deploy-prod.ps1` | Checklist post-despliegue (Windows) |
| `scripts/post-deploy-prod.sh` | Checklist post-despliegue (Linux) |
| `scripts/validate-prod-ssl-deploy.ps1` | Orquestador Fase 41 |
| `docs/fase-41-servidor-ssl-postdeploy.md` | Este documento |
| `docs/fase-41-flutter-ui-manual.md` | Checklist UI Flutter manual |

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `scripts/smoke-e2e.ps1` | Param `-SkipTlsVerify` |
| `scripts/seed-careers-dev.ps1` | Param `-SkipTlsVerify` |
| `scripts/seed-dev-student.ps1` | Param `-SkipTlsVerify` |
| `scripts/preflight-prod.ps1` | Placeholder prod-ssl-local |
| `.gitignore` | Ignora `.env.prod-ssl-local` |
| `docs/plan-desarrollo.md` | Fase 41 completada |
| `docs/checklist-qa.md` | Sección SSL + post-deploy |
| `docs/manual-produccion.md` | Flujo servidor real ampliado |
| `README.md` | Comandos Fase 41 |

---

## Stacks Docker

| Proyecto | HTTP | HTTPS | Env |
|----------|------|-------|-----|
| avov-prod-ssl-local | 8180 (redirect) | 8443 | `.env.prod-ssl-local` |
| avov-prod (real) | 80 | 443 | `.env` |

---

## Comandos

### Validación integral Fase 41 (local)

```powershell
.\scripts\validate-prod-ssl-deploy.ps1
```

### Prod SSL local manual

```powershell
.\scripts\generate-dev-ssl-certs.ps1
Copy-Item .env.prod-ssl-local.example .env.prod-ssl-local
.\scripts\prod-ssl-local-up.ps1
.\scripts\post-deploy-prod.ps1 `
  -BaseUrl "https://localhost:8443/api/v1" `
  -HttpBaseUrl "http://localhost:8180/api/v1" `
  -SkipTlsVerify -SeedCareers
.\scripts\prod-ssl-local-down.ps1
```

### Servidor Linux real

```bash
cp .env.production.example .env
# editar claves, CORS, API_BASE_URL
chmod +x scripts/deploy-prod.sh scripts/post-deploy-prod.sh
./scripts/deploy-prod.sh
# Con certificados en nginx/certs/:
AVOV_PROD_SSL=1 ./scripts/deploy-prod.sh
./scripts/post-deploy-prod.sh https://api.tudominio.edu.co/api/v1
```

---

## Post-despliegue verifica

- Health live y completo (MySQL, Redis, Qdrant)
- Settings públicas
- Login super admin
- `POST /vector/rebuild-careers`
- `POST /vector/search-careers`
- HSTS en HTTPS
- Redirect HTTP → HTTPS
- `/docs` → 404

**Última ejecución local:** 10 OK / 0 FALLO — ver [fase-41-prod-ssl-validation.txt](fase-41-prod-ssl-validation.txt) y [fase-41-post-deploy-report.txt](fase-41-post-deploy-report.txt).

> Nota: el smoke E2E completo (17 checks) vía HTTPS autofirmado en Windows puede ser inestable en ráfagas largas. La validación Fase 41 usa post-deploy completo + smoke reducido HTTPS. Para E2E completo usar HTTP (`validate-prod-deploy.ps1`) o servidor con certificado real.

---

## Próximo paso sugerido

Ejecutar [fase-41-flutter-ui-manual.md](fase-41-flutter-ui-manual.md) contra prod-local o staging, y desplegar en servidor institucional con certificados Let's Encrypt reales.
