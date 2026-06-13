# Fase 44 — Despliegue institucional y validacion release publico

## Objetivo

Ejecutar el **release institucional completo** en VPS Linux (o simulacion local equivalente):

1. Despliegue unificado API + Flutter Web + SSL + cron.
2. Smoke automatizado de URLs publicas (API + frontend SPA).
3. Post-deploy y monitoreo operativo.
4. Checklist UI manual documentado con plantilla de reporte.

---

## Archivos creados

| Archivo | Descripcion |
|---------|-------------|
| `.env.institutional-local.example` | Env simulacion local institucional |
| `docker-compose.prod.institutional-local.yml` | Stack prod + web + SSL local |
| `scripts/prod-institutional-local-up.ps1` | Levanta simulacion completa |
| `scripts/prod-institutional-local-down.ps1` | Detiene simulacion |
| `scripts/smoke-public-release.ps1` / `.sh` | Smoke API + Flutter Web publico |
| `scripts/deploy-institutional.sh` | Orquestador VPS Linux (6 pasos) |
| `scripts/validate-institutional-deploy.ps1` | Orquestador validacion Fase 44 |
| `docs/fase-44-ui-checklist-report.template.md` | Plantilla reporte checklist UI |
| `docs/fase-44-despliegue-institucional.md` | Este documento |

---

## Simulacion local (antes del VPS real)

```powershell
.\scripts\prod-institutional-local-up.ps1
.\scripts\validate-institutional-deploy.ps1 -SkipTlsVerify
```

URLs locales:

| Servicio | URL |
|----------|-----|
| Frontend | https://localhost:8443 |
| API | https://localhost:8443/api/v1 |
| HTTP redirect | http://localhost:8180 |

---

## Despliegue en VPS Linux (produccion real)

### Pre-requisitos

1. VPS con Docker y Docker Compose.
2. DNS `A`/`AAAA` para `API_DOMAIN` y `FRONTEND_DOMAIN`.
3. Puertos 80 y 443 abiertos en firewall.
4. `.env` editado desde `.env.production.server.example` (sin placeholders).

### Flujo automatizado

```bash
cp .env.production.server.example .env
# Editar dominios, claves, CORS, API_BASE_URL, FRONTEND_BASE_URL

chmod +x scripts/*.sh
LETSENCRYPT_EMAIL=admin@instituto.edu.co RUN_LETSENCRYPT=1 ./scripts/deploy-institutional.sh
```

Variables opcionales:

| Variable | Default | Descripcion |
|----------|---------|-------------|
| `RUN_LETSENCRYPT` | 0 | 1 = ejecutar certbot |
| `INSTALL_CRON` | 1 | 1 = instalar cron backup/monitor |
| `SKIP_SMOKE` | 0 | 1 = omitir smoke final |

### Pasos del script `deploy-institutional.sh`

1. Build Flutter Web con `API_BASE_URL` de produccion.
2. Certificados SSL (Let's Encrypt o existentes).
3. `deploy-prod-server.sh` (prod + web + ssl).
4. `post-deploy-prod.sh` (salud, login, Qdrant).
5. `smoke-public-release.sh` (API + frontend + CORS + HSTS).
6. `install-vps-cron.sh` (backups + monitor).

---

## Checklist UI manual (obligatorio)

1. Abrir `docs/fase-41-flutter-ui-manual.md`.
2. Probar contra la URL publica del frontend.
3. Registrar resultados en `docs/fase-44-ui-checklist-report.template.md`.
4. Aprobar solo si cumple criterio 90% en A, C, E.

---

## Comandos de validacion

```powershell
# Validacion Fase 44 (detecta stack local o dev)
.\scripts\validate-institutional-deploy.ps1 -SkipTlsVerify

# Smoke explicito
.\scripts\smoke-public-release.ps1 `
  -ApiUrl "https://localhost:8443/api/v1" `
  -FrontendUrl "https://localhost:8443" `
  -HttpApiUrl "http://localhost:8180/api/v1" `
  -SkipTlsVerify
```

```bash
./scripts/smoke-public-release.sh \
  "https://api.tudominio.edu.co/api/v1" \
  "https://app.tudominio.edu.co" \
  "http://api.tudominio.edu.co/api/v1"
```

---

## Reportes generados

| Archivo | Contenido |
|---------|-----------|
| `docs/fase-44-institutional-deploy-validation.txt` | Resultado validate-institutional-deploy |
| `docs/fase-44-smoke-public-release.txt` | Resultado smoke publico |

---

## Próximo paso sugerido (Fase 45)

Soporte en producción, rollback y capacitación TI: [fase-45-soporte-rollback-capacitacion.md](fase-45-soporte-rollback-capacitacion.md).

---

## Estado

Fase 44 completada. Validacion local institutional-local: **8 OK / 0 FALLO** (`validate-institutional-deploy.ps1`). Smoke publico: **9 OK / 0 FALLO**.
