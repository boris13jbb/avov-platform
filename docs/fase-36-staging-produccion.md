# FASE 36 COMPLETADA — Staging y validación de producción local

## 1. Resumen

Se implementó un **entorno staging local** que replica el stack de producción (MySQL, Redis, Qdrant, backend sin hot-reload, Nginx) en un proyecto Docker aislado (`avov-staging`), expuesto por defecto en el puerto **8080** para no interferir con el desarrollo en el puerto 8000.

Incluye scripts de despliegue, validación integral automatizada, smoke E2E vía Nginx, verificación de bloqueo de OpenAPI y backups del entorno staging.

## 2. Archivos creados

| Archivo | Descripción |
|---------|-------------|
| `.env.staging.example` | Plantilla de variables para staging local |
| `docker-compose.staging.yml` | Override: `env_file` `.env.staging` |
| `scripts/staging-up.ps1` | Levantar stack staging |
| `scripts/staging-down.ps1` | Detener stack staging |
| `scripts/validate-staging.ps1` | Validación integral Fase 36 |
| `docs/fase-36-staging-produccion.md` | Este documento |
| `docs/fase-36-staging-validation.txt` | Reporte de validación (generado) |
| `docs/fase-36-staging-report.txt` | Reporte smoke E2E vía Nginx (generado) |

## 3. Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `scripts/smoke-e2e.ps1` | Parámetros `-ReportPath`, `-ReportTitle`; seed con `-BaseUrl` |
| `scripts/seed-dev-student.ps1` | Parámetro `-BaseUrl` para staging |
| `scripts/backup-all.ps1` | Target `staging` |
| `scripts/backup-mysql.ps1` | Soporte `-Staging` |
| `scripts/backup-qdrant.ps1` | Soporte `-Staging` |
| `backend/Dockerfile.prod` | `sed` elimina CRLF del entrypoint en Windows |
| `.gitattributes` | `*.sh` con fin de línea LF |
| `.env.production.example` | SMTP sanitizado (sin credenciales reales) |
| `.gitignore` | Excluye `.env.staging` |
| `scripts/verify-structure.ps1` | Valida archivos staging |
| `docs/plan-desarrollo.md` | Estado Fase 36 |
| `docs/checklist-qa.md` | Ítems staging |
| `README.md` | Comandos staging |

## 4. Validaciones realizadas

| Verificación | Descripción |
|--------------|-------------|
| Estructura | Archivos staging presentes |
| `docker compose config` | Sintaxis válida |
| `staging-up` | Stack levantado con Nginx |
| Health vía Nginx | `/api/v1/health/live` y DB ok |
| Seguridad | `/docs` → 404, cabeceras OWASP en Nginx |
| Sin phpMyAdmin | No expuesto en compose prod |
| Smoke E2E | 17 flujos vía `http://localhost:8080/api/v1` |
| Backup | MySQL + Qdrant + storage staging |

## 5. Comandos ejecutados o sugeridos

```powershell
# Levantar staging manualmente
Copy-Item .env.staging.example .env.staging
.\scripts\staging-up.ps1

# Health vía Nginx
curl http://localhost:8080/api/v1/health/live

# Smoke contra staging
.\scripts\smoke-e2e.ps1 -BaseUrl "http://localhost:8080/api/v1" -EnsureStudentSeed

# Validación integral Fase 36 (levanta, valida, detiene)
.\scripts\validate-staging.ps1

# Mantener stack activo tras validación
.\scripts\validate-staging.ps1 -SkipTeardown

# Backup staging
.\scripts\backup-all.ps1 -Target staging

# Detener
.\scripts\staging-down.ps1
```

## 6. Errores encontrados

| Error | Resolución |
|-------|------------|
| `prod-up.ps1` usa `.env` compartido con dev | Staging usa `.env.staging` dedicado |
| Smoke hardcodeado a puerto 8000 | Parámetro `-BaseUrl` reutilizable |
| Credenciales SMTP en `.env.production.example` | Reemplazadas por placeholders seguros |
| `docker-entrypoint.prod.sh` con CRLF (Windows) | `sed` en `Dockerfile.prod` + `.gitattributes` |
| Cabeceras OWASP fallaban en smoke vía Nginx | Lectura case-insensitive de headers HTTP |

## 7. Estado final

Staging local operativo y validable de forma automatizada. El stack de desarrollo (`docker compose up`) y staging (`avov-staging`) pueden coexistir en puertos distintos.

## 8. Próximo paso

- Pruebas E2E **visuales** Flutter apuntando a `API_BASE_URL=http://localhost:8080/api/v1`
- Despliegue en servidor real según [manual-produccion.md](manual-produccion.md)
- TLS con `.\scripts\prod-up.ps1 -Ssl` cuando existan certificados en `nginx/certs/`
