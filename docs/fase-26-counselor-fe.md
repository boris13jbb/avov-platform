# FASE 26 — Panel orientador (Flutter)

## Objetivo

Pantallas del orientador para revisar estudiantes asignados, consultar resultados vocacionales, registrar observaciones y descargar PDF.

## Rutas

| Pantalla | Ruta |
|----------|------|
| Dashboard orientador | `/counselor/dashboard` |
| Estudiantes asignados | `/counselor/students` |
| Resultado vocacional | `/counselor/students/:id/results` |
| Agregar observación | `/counselor/students/:id/observation` |

## Endpoints integrados

| Método | Ruta | Uso |
|--------|------|-----|
| GET | `/dashboard/counselor` | Métricas y pendientes |
| GET | `/students` | Lista filtrada por asignación |
| GET | `/students/{id}` | Datos del estudiante |
| GET | `/recommendations/student/{id}` | Carreras recomendadas |
| GET | `/tests/{session_id}/result` | Perfil RIASEC |
| POST | `/tests/{session_id}/observations` | Registrar observación (sin requerir recomendación) |
| POST | `/students/{id}/assign-counselor` | Asignar orientador (UI en detalle estudiante) |
| GET | `/reports/{session_id}/pdf` | Descargar reporte |

## Arquitectura Flutter

```
frontend/lib/features/counselor/
  presentation/
    providers/counselor_provider.dart
    screens/
      counselor_student_results_screen.dart
      counselor_observation_screen.dart
frontend/lib/core/models/counselor_observation.dart
```

Reutiliza `StudentListScreen` con `StudentManagementConfig.counselor`.

## Seed de orientador de prueba

```powershell
.\scripts\seed-counselor-dev.ps1
```

Credenciales:
- Email: `orientador.test.fase26@instituto.edu.co`
- Contraseña: `Counsel1234!`

## Validación manual

1. Ejecutar seed y login como orientador asignado al estudiante test
2. Panel → **Ver estudiantes asignados**
3. Abrir estudiante → ver perfil RIASEC y recomendaciones
4. **Agregar observación profesional** → guardar
5. **Descargar reporte PDF**
6. Probar con estudiante sin recomendaciones: debe verse RIASEC y permitir observación

## Siguiente fase

**FASE 27** — Reportes y exportaciones institución (Flutter)
