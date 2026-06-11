# FASE 24 — Resultados, recomendaciones y PDF (Flutter)

## Objetivo

Pantallas de resultados RIASEC, carreras recomendadas y descarga de PDF para estudiantes.

## Rutas

| Pantalla | Ruta |
|----------|------|
| Resultados RIASEC | `/student/results` |
| Carreras recomendadas | `/student/recommendations` |

## Endpoints integrados

| Método | Ruta | Uso |
|--------|------|-----|
| GET | `/dashboard/student` | Datos RIASEC y acciones |
| POST | `/recommendations/generate` | Generar recomendaciones |
| GET | `/recommendations/student/{id}` | Listar recomendaciones |
| GET | `/reports/{session_id}/pdf` | Descargar PDF |

## Dependencias nuevas

- `path_provider` — guardar PDF temporal
- `open_filex` — abrir PDF en el dispositivo

## Validación manual

Login: `estudiante.test.fase11@instituto.edu.co` / `Estud1234!`

1. Mi panel → **Ver resultados RIASEC**
2. **Generar recomendaciones** → ver lista con porcentajes
3. **Descargar reporte PDF** → se abre el visor del sistema

## Siguiente fase

**FASE 25 — Asistente virtual (Flutter)**
