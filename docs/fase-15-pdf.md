# FASE 15 — Informes PDF vocacionales

## Discrepancias documentación ↔ código (antes de implementar)

| Fuente | Afirmación | Código real (pre-Fase 15) |
|--------|------------|---------------------------|
| `api-endpoints.md` §12 | `GET /reports/{test_session_id}/pdf` | Router stub vacío; **no** registrado en `main.py` |
| `api-endpoints.md` §12 | `GET /reports/student/{student_id}` | No implementado (fuera de alcance MVP) |
| `flujos.md` §4 | `PDFService`, ReportLab, auditoría | Sin servicio; `AuditLog` existe sin servicio de escritura |
| Proyecto | ReportLab o WeasyPrint | Solo `reportlab==4.2.5` en `requirements.txt` |
| Modelo `Report` | `file_path`, `report_code`, `generated_by` | Sin unique en `test_session_id` (idempotencia por «último informe») |

## Implementación

- Endpoint: `GET /api/v1/reports/{session_id}/pdf` (autenticado).
- Respuesta: `application/pdf` + `Content-Disposition` + `X-Report-Code`.
- Motor: **ReportLab** (ya en dependencias); `pypdf` solo para verificar en pruebas.
- Autorización: reutiliza `_ensure_can_view_result` (STUDENT dueño, COUNSELOR asignado, INSTITUTION_ADMIN misma institución, SUPER_ADMIN).
- Idempotencia: reutiliza el último `Report` de la sesión si el archivo existe y es PDF; regenera archivo si falta o está corrupto; no crea registros duplicados en el camino feliz.
- Auditoría: `PDF_GENERATED` / `PDF_DOWNLOADED` / `PDF_REGENERATED` en `audit_logs`.
- Frontend: botón «Descargar PDF» en resultado vocacional; sin auto-`generate` de recomendaciones al abrir el resultado.

## Contenido del PDF

Institución, estudiante (nombre, identificación, curso), fechas de sesión, perfil y puntajes RIASEC, interpretación si existe, carreras recomendadas **persistidas**, observación del orientador si existe, nota ética, código único.

## Fase 15.1 — Brechas de validación

### Autorización cubierta en pruebas

- `INSTITUTION_ADMIN` misma institución: descarga permitida.
- `INSTITUTION_ADMIN` otra institución: 403 sin cuerpo PDF ni filtración de datos/rutas; el 403 depende de `_ensure_can_view_result` (bypass controlado → 200).
- `COUNSELOR` con `CounselorAssignment` ACTIVE: descarga permitida.
- `COUNSELOR` sin asignación al estudiante de la sesión: 403 (misma comprobación de bypass).

### `GET /reports/student/{student_id}`

Fuera del alcance obligatorio de Fase 15 / 15.1. Implementado en **Fase 16A** (`docs/fase-16a-historial-informes.md`).

### E2E navegador

La descarga real en Chrome queda bloqueada si no se puede aislar `AVOV_REPORTS_DIR` del proceso `:8001` sin reiniciar servicios. La validación HTTP+PDF queda cubierta por pytest (`TestClient` + `AVOV_REPORTS_DIR` temporal).
