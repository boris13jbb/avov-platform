# FASE 15 — Reportes PDF

## Objetivo

Generar y descargar reportes PDF institucionales tras completar el test vocacional y generar recomendaciones (Fase 14).

## Endpoints

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/api/v1/reports/{test_session_id}/pdf` | Según permiso | Descarga PDF (genera o reutiliza) |
| GET | `/api/v1/reports/student/{student_id}` | Según permiso | Historial de reportes |

## Contenido del PDF

1. Datos de institución
2. Datos del estudiante (sin información sensible innecesaria)
3. Fecha del test y código único del reporte
4. Perfil RIASEC dominante, secundario y combinado
5. Tabla de puntajes R/I/A/S/E/C
6. Carreras recomendadas con compatibilidad y explicación
7. Observaciones del orientador (si existen)
8. Responsable del reporte
9. Nota ética obligatoria

## Flujo

1. Validar permisos (`TestSessionService._ensure_can_view_result`)
2. Verificar test `COMPLETED` y recomendaciones existentes
3. Si ya hay PDF guardado → descargar desde `storage/reports/{report_code}.pdf`
4. Si no → renderizar con ReportLab, guardar archivo y registrar en tabla `reports`
5. Auditoría en `audit_logs` (`PDF_GENERATED` / `PDF_DOWNLOADED`)

## Archivos implementados

| Archivo | Responsabilidad |
|---------|-----------------|
| `backend/app/schemas/report.py` | Schemas de respuesta |
| `backend/app/repositories/report_repository.py` | Persistencia |
| `backend/app/services/pdf_renderer.py` | Render ReportLab |
| `backend/app/services/pdf_service.py` | Orquestación |
| `backend/app/services/audit_service.py` | Registro de auditoría |
| `backend/app/api/routes/reports.py` | Endpoints |
| `backend/app/utils/file_storage.py` | Rutas seguras de almacenamiento |
| `backend/tests/test_reports.py` | Pruebas automatizadas |

## Validación manual (PowerShell)

```powershell
# 1. Login estudiante con test completado y recomendaciones generadas
$login = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/login" `
  -Method POST -ContentType "application/json" `
  -Body '{"email":"estudiante.test.fase11@instituto.edu.co","password":"Estud1234!"}'
$headers = @{ Authorization = "Bearer $($login.data.access_token)" }

# 2. Generar recomendaciones si aún no existen
Invoke-RestMethod -Uri "http://localhost:8000/api/v1/recommendations/generate" `
  -Method POST -Headers $headers -ContentType "application/json" -Body '{}'

# 3. Descargar PDF (sesión 17 del estudiante de prueba)
Invoke-WebRequest -Uri "http://localhost:8000/api/v1/reports/17/pdf" `
  -Headers $headers -OutFile "reporte-avov.pdf"

# 4. Historial
Invoke-RestMethod -Uri "http://localhost:8000/api/v1/reports/student/81" -Headers $headers
```

## Siguiente fase

**FASE 16+** — Dashboard, frontend Flutter resultados/PDF, etc.
