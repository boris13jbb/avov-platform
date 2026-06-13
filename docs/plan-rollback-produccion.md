# Plan de rollback — AVOV producción (Fase 45)

## Objetivo

Recuperar el servicio AVOV tras una actualización fallida o incidente, minimizando pérdida de datos y tiempo de indisponibilidad.

---

## Cuándo ejecutar rollback

| Escenario | Acción recomendada |
|-----------|-------------------|
| Smoke/post-deploy falla tras update | Rollback código + evaluar restore BD |
| Error crítico en backend tras deploy | Rollback inmediato |
| Migración Alembic corrupta | Rollback + restore MySQL del backup pre-update |
| Qdrant desincronizado | Rebuild índice; rollback solo si persiste |
| Frontend roto (SPA) | Rollback git + rebuild web |

---

## Artefactos de rollback

Tras `update-prod-safe.sh`, se genera:

```
.deploy/release-state.json
```

Contiene:

- `previous_commit` — commit Git antes del update
- `mysql_backup`, `qdrant_backup`, `storage_backup` — rutas de backup pre-update
- `api_url`, `frontend_url` — URLs de validación

---

## Procedimiento rápido (VPS Linux)

### 1. Activar modo mantenimiento

Super admin → Configuración → `maintenance_mode = true`

### 2. Rollback solo código (sin BD)

```bash
cd /opt/avov
./scripts/rollback-prod.sh
# Confirmar con SI
```

### 3. Rollback código + base de datos

```bash
ROLLBACK_RESTORE_DB=1 ./scripts/rollback-prod.sh
```

### 4. Validar

```bash
./scripts/post-deploy-prod.sh "$(grep ^API_BASE_URL= .env | cut -d= -f2-)"
./scripts/smoke-public-release.sh \
  "$(grep ^API_BASE_URL= .env | cut -d= -f2-)" \
  "$(grep ^FRONTEND_BASE_URL= .env | cut -d= -f2-)"
```

### 5. Desactivar mantenimiento

`maintenance_mode = false`

---

## Restauración manual de backup

```bash
./scripts/restore-backup.sh \
  backups/mysql/avov_mysql_YYYYMMDD_HHMMSS.sql \
  backups/qdrant/avov_qdrant_YYYYMMDD_HHMMSS.tar.gz \
  backups/storage/avov_storage_YYYYMMDD_HHMMSS.tar.gz
```

Windows:

```powershell
.\scripts\restore-backup.ps1 -MySqlFile backups\mysql\archivo.sql -Force
```

---

## Rollback a commit específico

```bash
ROLLBACK_GIT_REF=abc1234 ./scripts/rollback-prod.sh
```

---

## Tiempos estimados (RTO)

| Paso | Tiempo típico |
|------|---------------|
| Modo mantenimiento | 1 min |
| git checkout + redeploy | 5–15 min |
| Restore MySQL (500 MB) | 5–20 min |
| Post-deploy + smoke | 3 min |
| **Total** | **15–40 min** |

---

## Prevención

1. Siempre ejecutar `update-prod-safe.sh` (nunca `git pull` + deploy manual sin backup).
2. Probar updates en staging (`avov-staging`) antes de producción.
3. Conservar backups mínimo 14 días (`prune-backups.sh`).

---

## Escalación

| Nivel | Contacto | Acción |
|-------|----------|--------|
| L1 | Admin institución | Modo mantenimiento, reinicio servicios |
| L2 | TI institucional | Rollback, restore backup |
| L3 | Soporte AVOV / desarrollo | Análisis logs, parche hotfix |

Ver [runbook-soporte-produccion.md](runbook-soporte-produccion.md).
