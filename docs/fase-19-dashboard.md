# FASE 19 — Dashboards y exportaciones

## Objetivo

Exponer métricas agregadas por rol y exportaciones CSV para paneles institucionales.

## Endpoints Dashboard

| Método | Ruta | Rol |
|--------|------|-----|
| GET | `/api/v1/dashboard/super-admin` | SUPER_ADMIN |
| GET | `/api/v1/dashboard/institution` | INSTITUTION_ADMIN |
| GET | `/api/v1/dashboard/counselor` | COUNSELOR |
| GET | `/api/v1/dashboard/student` | STUDENT |

## Endpoints Exportaciones

| Método | Ruta | Rol |
|--------|------|-----|
| GET | `/api/v1/exports/students` | INSTITUTION_ADMIN |
| GET | `/api/v1/exports/test-results` | INSTITUTION_ADMIN, COUNSELOR |

## Archivos implementados

| Archivo | Responsabilidad |
|---------|-----------------|
| `backend/app/schemas/dashboard.py` | Schemas por rol |
| `backend/app/repositories/dashboard_repository.py` | Consultas agregadas |
| `backend/app/services/dashboard_service.py` | Lógica por rol |
| `backend/app/services/export_service.py` | CSV estudiantes y resultados |
| `backend/app/api/routes/dashboard.py` | Endpoints dashboard |
| `backend/app/api/routes/exports.py` | Endpoints exportaciones |
| `backend/tests/test_dashboard.py` | Pruebas automatizadas |

## Validación manual (PowerShell)

```powershell
# Super admin
$admin = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/login" `
  -Method POST -ContentType "application/json" `
  -Body '{"email":"admin@avov.edu.co","password":"Admin123!"}'
$h = @{ Authorization = "Bearer $($admin.data.access_token)" }
Invoke-RestMethod -Uri "http://localhost:8000/api/v1/dashboard/super-admin" -Headers $h

# Estudiante
$stu = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/login" `
  -Method POST -ContentType "application/json" `
  -Body '{"email":"estudiante.test.fase11@instituto.edu.co","password":"Estud1234!"}'
$hs = @{ Authorization = "Bearer $($stu.data.access_token)" }
Invoke-RestMethod -Uri "http://localhost:8000/api/v1/dashboard/student" -Headers $hs
```

## Siguiente fase

Integración Flutter de dashboards por rol (Fase 19 FE / Fase 24 pantallas).
