# FASE 35 — Smoke E2E automatizado por API

## 1. Resumen

Script de humo (`scripts/smoke-e2e.ps1`) que valida flujos críticos contra el backend en ejecución: salud, auth, roles, dashboards, preguntas RIASEC y sesión de test.

Complementa `validate-fase32.ps1` (estructura + pytest) con pruebas de **runtime funcional** sin UI.

## 2. Archivos creados

| Archivo | Descripción |
|---------|-------------|
| `scripts/smoke-e2e.ps1` | Ejecutor de smoke E2E |
| `docs/fase-35-e2e-smoke-report.txt` | Reporte generado |
| `docs/fase-35-e2e-smoke.md` | Este documento |

## 3. Comandos

```powershell
docker compose up -d
.\scripts\smoke-e2e.ps1
```

Opcional (estudiante de prueba documentado):

```powershell
# Si el login estudiante falla, crear datos de prueba según manual-administrador.md
.\scripts\seed-institution-admin-dev.ps1
```

## 4. Cobertura del smoke

| Grupo | Verificaciones |
|-------|----------------|
| Infra | health/live, health, API root, cabeceras OWASP |
| Auth | settings/public, login inválido, super admin, /me, refresh |
| Roles | 403 estudiante en /students y /settings |
| Dashboard | super-admin y estudiante |
| Test RIASEC | 60 preguntas, inicio de sesión |
| CRUD | listado instituciones |

## 5. Validaciones realizadas

| Ejecución | Resultado |
|-----------|-----------|
| `smoke-e2e.ps1` | **17/17 OK** |
| Reporte | [fase-35-e2e-smoke-report.txt](fase-35-e2e-smoke-report.txt) |

## 6. Próximo paso

- Pruebas E2E **visuales** en Flutter (checklist manual)
- Despliegue staging con `scripts/prod-up.ps1`
