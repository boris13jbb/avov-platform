# FASE 16A — Historial de informes PDF

## Alcance

- Backend: `GET /api/v1/reports/student/{student_id}` con paginación.
- Autorización vía `StudentService.get_student` (misma matriz que acceso a la ficha del estudiante; coherente con quién puede descargar PDFs de ese estudiante).
- Respuesta solo metadatos del modelo `Report` (sin `file_path`).
- Flutter: sección «Historial de informes» en detalle de estudiante y en «Mi ficha»; descarga con el flujo existente `GET /reports/{session_id}/pdf`.

## Limitaciones conocidas

- El modelo `Report` no tiene campo `status`; el historial no filtra por estado.
- Puede existir más de un registro por sesión en el esquema actual; el listado muestra todos los registros del estudiante, ordenados por `created_at`/`id` descendente. La descarga PDF sigue usando el último informe de la sesión (`GET /reports/{session_id}/pdf`). La UI aclara que se descarga el **PDF vigente de la sesión**, no una versión histórica del registro.
- La UI del historial carga solo la primera página (`page=1`, `page_size=20`); no hay control de paginación interactiva en esta fase.
- No se añadieron migraciones ni cambios de esquema.

## Pruebas

- Backend: `backend/tests/test_reports_history.py` (vacío, orden, auth por rol, sin filtración de rutas).
- Flutter: `frontend/test/student_reports_history_test.dart`.
