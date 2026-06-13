# Fase 43 — Operaciones VPS: backups, retención y monitoreo

## Objetivo

Automatizar la **operación continua** del servidor AVOV en Linux:

1. Backup unificado MySQL + Qdrant + storage (`backup-all.sh`).
2. Retención configurable de backups antiguos (`prune-backups.sh` / `.ps1`).
3. Monitoreo periódico de salud API y disco (`monitor-health.sh` / `.ps1`).
4. Instalación de cron en VPS (`install-vps-cron.sh`).
5. Bootstrap inicial del servidor (`setup-vps.sh`).
6. Validación automatizada `validate-vps-readiness.ps1`.

---

## Archivos creados

| Archivo | Descripción |
|---------|-------------|
| `scripts/backup-all.sh` | Backup Linux unificado con soporte prod/web/ssl/staging |
| `scripts/backup-storage.sh` | Backup tarball de `/app/storage` |
| `scripts/prune-backups.sh` | Retención Linux (`RETENTION_DAYS`, `DRY_RUN=1`) |
| `scripts/prune-backups.ps1` | Retención Windows (`-DryRun`) |
| `scripts/monitor-health.sh` | Monitor Linux para cron |
| `scripts/monitor-health.ps1` | Monitor Windows con reporte |
| `scripts/install-vps-cron.sh` | Instala entradas cron backup + monitor |
| `scripts/setup-vps.sh` | Bootstrap VPS (deploy + post-deploy) |
| `scripts/validate-vps-readiness.ps1` | Orquestador Fase 43 |
| `docs/cron/avov-backup.cron.example` | Plantilla cron manual |
| `docs/fase-43-vps-operaciones.md` | Este documento |

---

## Comandos

### Validación Fase 43 (Windows / CI)

```powershell
.\scripts\validate-vps-readiness.ps1
.\scripts\validate-vps-readiness.ps1 -SkipBackupTest
.\scripts\validate-vps-readiness.ps1 -BaseUrl "http://localhost:8090/api/v1"
```

### Backup manual

```bash
# Produccion real (web + ssl)
AVOV_PROD_WEB=1 AVOV_PROD_SSL=1 ./scripts/backup-all.sh prod

# Staging
./scripts/backup-all.sh staging

# Prod-local (Windows)
.\scripts\backup-all.ps1 -Target prod-local
```

### Retención (preview)

```bash
DRY_RUN=1 RETENTION_DAYS=14 ./scripts/prune-backups.sh
```

```powershell
.\scripts\prune-backups.ps1 -DryRun -RetentionDays 14
```

### Monitoreo

```powershell
.\scripts\monitor-health.ps1 -BaseUrl "http://localhost:8000/api/v1"
```

```bash
./scripts/monitor-health.sh "https://api.tudominio.edu.co/api/v1"
```

### Cron en VPS Linux

```bash
# Preview
INSTALL=0 AVOV_ROOT=/opt/avov ./scripts/install-vps-cron.sh

# Instalar
INSTALL=1 AVOV_ROOT=/opt/avov RETENTION_DAYS=14 ./scripts/install-vps-cron.sh
```

### Bootstrap VPS completo

```bash
# Requiere Docker, git y .env editado
./scripts/setup-vps.sh
```

---

## Variables de entorno relevantes

| Variable | Uso |
|----------|-----|
| `AVOV_PROD_WEB=1` | Activa override `docker-compose.prod.web.yml` |
| `AVOV_PROD_SSL=1` | Activa override SSL (web.ssl o prod.ssl) |
| `AVOV_ENV_FILE` | Archivo env (default `.env`) |
| `RETENTION_DAYS` | Días de retención backups (default 14) |
| `DRY_RUN=1` | Preview prune sin borrar |
| `DISK_WARN_PERCENT` | Umbral disco monitor (default 85) |
| `API_BASE_URL` | URL base API para monitor cron |

---

## Reportes generados

| Archivo | Contenido |
|---------|-----------|
| `docs/fase-43-vps-readiness-validation.txt` | Resultado `validate-vps-readiness.ps1` |
| `docs/fase-43-monitor-report.txt` | Último monitor health |
| `logs/backup-cron.log` | Log cron backups (VPS) |
| `logs/monitor-health.log` | Log cron monitor (VPS) |

---

## Próximo paso sugerido (Fase 44)

Despliegue institucional en VPS y checklist UI contra URL pública: [fase-44-despliegue-institucional.md](fase-44-despliegue-institucional.md).

---

## Estado

Fase 43 completada. Validacion local: **5 OK / 2 SKIP / 0 FALLO** (`validate-vps-readiness.ps1`).
