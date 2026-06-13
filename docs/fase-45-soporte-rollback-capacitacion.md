# Fase 45 — Soporte producción, rollback y capacitación TI

## Objetivo

Entregar operación **sostenible** post-release institucional:

1. Scripts de actualización segura, rollback y restauración de backups.
2. Plan de rollback documentado con RTO estimado.
3. Runbook de soporte para incidentes frecuentes.
4. Material de capacitación TI (4 h).
5. Validación automatizada `validate-production-ops.ps1`.

---

## Archivos creados

| Archivo | Descripción |
|---------|-------------|
| `scripts/update-prod-safe.sh` / `.ps1` | Backup + pull + deploy + smoke |
| `scripts/rollback-prod.sh` / `.ps1` | Rollback a commit y backups registrados |
| `scripts/restore-backup.sh` / `.ps1` | Restauración MySQL + Qdrant + storage |
| `scripts/validate-production-ops.ps1` | Orquestador Fase 45 |
| `docs/plan-rollback-produccion.md` | Plan de rollback |
| `docs/runbook-soporte-produccion.md` | Runbook incidentes |
| `docs/capacitacion-ti-institucional.md` | Capacitación 4 h |
| `docs/fase-45-soporte-rollback-capacitacion.md` | Este documento |

---

## Flujo operativo

```
Actualización planificada:
  maintenance_mode ON → update-prod-safe.sh → smoke → checklist UI → maintenance_mode OFF

Incidente post-deploy:
  maintenance_mode ON → rollback-prod.sh [ROLLBACK_RESTORE_DB=1] → smoke → maintenance_mode OFF

Pérdida de datos:
  restore-backup.sh <mysql> [qdrant] [storage] → post-deploy → rebuild Qdrant
```

---

## Comandos

### Validación Fase 45

```powershell
.\scripts\validate-production-ops.ps1
```

### Update seguro (VPS)

```bash
./scripts/update-prod-safe.sh
```

### Rollback

```bash
./scripts/rollback-prod.sh
ROLLBACK_RESTORE_DB=1 ./scripts/rollback-prod.sh
```

### Restaurar backup

```bash
./scripts/restore-backup.sh backups/mysql/archivo.sql backups/qdrant/archivo.tar.gz
```

---

## Estado

Fase 45 completada. Validacion: **8 OK / 1 SKIP / 0 FALLO** (`validate-production-ops.ps1`).

---

## Próximo paso sugerido (Fase 46)

Entrega formal al cliente institucional: acta de recepción, formación a usuarios finales (orientadores/estudiantes) y cierre del proyecto.
