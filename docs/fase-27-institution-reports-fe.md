# FASE 27 — Reportes y exportaciones institución (Flutter)

## Objetivo

Pantallas de reportes vocacionales y exportaciones CSV para **INSTITUTION_ADMIN**.

## Rutas

| Pantalla | Ruta |
|----------|------|
| Reportes institución | `/institution/reports` |
| Exportaciones CSV | `/institution/exports` |

## Endpoints integrados

| Método | Ruta | Uso |
|--------|------|-----|
| GET | `/dashboard/institution` | Métricas, distribución RIASEC, finalizaciones |
| GET | `/reports/{session_id}/pdf` | Descargar PDF desde finalizaciones recientes |
| GET | `/exports/students` | CSV de estudiantes |
| GET | `/exports/test-results` | CSV de resultados RIASEC |

## Arquitectura Flutter

```
frontend/lib/features/institution_reports/
  data/
    datasources/export_remote_datasource.dart
    repositories/export_repository.dart
  presentation/
    providers/export_provider.dart
    screens/
      institution_reports_screen.dart
      institution_exports_screen.dart
```

## Validación manual

1. Login como `INSTITUTION_ADMIN`
2. Panel institucional → **Reportes institución**
3. Revisar métricas, distribución RIASEC y finalizaciones recientes
4. Descargar PDF de una finalización reciente
5. Panel → **Exportaciones CSV**
6. Descargar **Estudiantes** y **Resultados de tests**

## Siguiente fase

**FASE 28** — Config institución (`/institution/settings`) — ver `docs/fase-28-institution-settings-fe.md`.
