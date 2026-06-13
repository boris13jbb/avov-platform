# Capacitación TI institucional — AVOV (Fase 45)

Material para formar al personal de tecnología de la institución en operación diaria de AVOV en producción.

**Duración sugerida:** 4 horas (teoría + práctica)

---

## Módulo 1 — Arquitectura y accesos (45 min)

### Contenido

- Stack: Flutter Web → Nginx → FastAPI → MySQL, Redis, Qdrant
- Roles: SUPER_ADMIN, INSTITUTION_ADMIN, COUNSELOR, STUDENT
- URLs: frontend (`FRONTEND_BASE_URL`) y API (`API_BASE_URL`)
- Qué **no** está expuesto: MySQL, Redis, Qdrant, phpMyAdmin

### Práctica

1. Abrir `https://app.instituto.edu.co` e iniciar sesión admin.
2. Consultar `GET /api/v1/health` y explicar cada servicio.
3. Revisar `.env` en servidor (sin compartir secretos).

---

## Módulo 2 — Despliegue y actualizaciones (60 min)

### Contenido

- Preflight: `preflight-prod.ps1` / variables en `.env`
- Despliegue inicial: `deploy-institutional.sh`
- Actualización segura: `update-prod-safe.sh`
- Modo mantenimiento antes de cambios

### Práctica (staging o simulación local)

```powershell
.\scripts\prod-institutional-local-up.ps1
.\scripts\validate-institutional-deploy.ps1 -SkipTlsVerify
```

En VPS:

```bash
./scripts/update-prod-safe.sh
```

---

## Módulo 3 — Backups y restauración (45 min)

### Contenido

- Backup diario: MySQL + Qdrant + storage
- Retención 14 días
- Cron: `install-vps-cron.sh`

### Práctica

```bash
AVOV_PROD_WEB=1 AVOV_PROD_SSL=1 ./scripts/backup-all.sh prod
ls -la backups/mysql/
DRY_RUN=1 ./scripts/prune-backups.sh
```

Restauración (solo en entorno de prueba):

```bash
./scripts/restore-backup.sh backups/mysql/archivo.sql
```

---

## Módulo 4 — Rollback y contingencias (45 min)

### Contenido

- Cuándo hacer rollback vs hotfix
- Archivo `.deploy/release-state.json`
- Procedimiento: [plan-rollback-produccion.md](plan-rollback-produccion.md)
- Runbook: [runbook-soporte-produccion.md](runbook-soporte-produccion.md)

### Práctica (simulación)

1. Ejecutar `update-prod-safe.sh` en staging.
2. Simular fallo (detener backend).
3. Ejecutar `rollback-prod.sh` (sin restore BD primero).
4. Validar con `post-deploy-prod.sh`.

---

## Módulo 5 — Soporte a usuarios y QA (45 min)

### Contenido

- Manual administrador: [manual-administrador.md](manual-administrador.md)
- Manual usuario: [manual-usuario.md](manual-usuario.md)
- Checklist UI release: [fase-41-flutter-ui-manual.md](fase-41-flutter-ui-manual.md)
- Credenciales de prueba (solo entornos no productivos)

### Práctica

Completar secciones A y C del checklist UI en staging.

---

## Evaluación (checklist del capacitado)

| # | Competencia | OK |
|---|-------------|-----|
| 1 | Explica arquitectura AVOV | [ ] |
| 2 | Ejecuta backup manual | [ ] |
| 3 | Interpreta `/health` y logs | [ ] |
| 4 | Activa modo mantenimiento | [ ] |
| 5 | Ejecuta update-prod-safe | [ ] |
| 6 | Describe procedimiento rollback | [ ] |
| 7 | Restaura backup MySQL (prueba) | [ ] |
| 8 | Completa checklist UI básico | [ ] |

**Aprobación:** mínimo 6/8 ítems OK.

---

## Material entregable a la institución

1. Este documento
2. [plan-rollback-produccion.md](plan-rollback-produccion.md)
3. [runbook-soporte-produccion.md](runbook-soporte-produccion.md)
4. [manual-produccion.md](manual-produccion.md)
5. Acceso restringido al servidor y panel super admin

---

## Soporte post-capacitación

- Canal: correo TI institucional + ticket interno
- Escalación L3: equipo desarrollo AVOV
- Revisiones recomendadas: semestral o tras cada release mayor
