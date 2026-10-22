# API Endpoints — AVOV

**Base URL:** `http://localhost:8000/api/v1`  
**Fase documentada:** 0 (plan completo) — Implementación progresiva Fases 3-26

---

## Formato de respuesta estándar

### Éxito

```json
{
  "success": true,
  "message": "Operación realizada correctamente",
  "data": {},
  "errors": []
}
```

### Error

```json
{
  "success": false,
  "message": "Error de validación",
  "data": null,
  "errors": [
    {
      "field": "email",
      "message": "El correo no tiene un formato válido"
    }
  ]
}
```

### Autenticación

Endpoints protegidos requieren header:

```
Authorization: Bearer <access_token>
```

---

## 1. Sistema y salud (Fase 3)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/` | Público | Información básica de la API |
| GET | `/health` | Público | Health completo (MySQL, Redis, Qdrant) |
| GET | `/health/live` | Público | Liveness probe |
| GET | `/status` | Público | Estado detallado de servicios |

---

## 2. Autenticación (Fase 5)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| POST | `/auth/login` | Público | Iniciar sesión, retorna JWT |
| POST | `/auth/logout` | Autenticado | Cerrar sesión, revocar refresh token |
| POST | `/auth/refresh` | Autenticado | Renovar access token |
| GET | `/auth/me` | Autenticado | Perfil del usuario actual |
| POST | `/auth/change-password` | Autenticado | Cambiar contraseña |
| POST | `/auth/forgot-password` | Público | Solicitar recuperación (opcional) |
| POST | `/auth/reset-password` | Público | Restablecer con token (opcional) |

---

## 3. Instituciones (Fase 6)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/institutions` | SUPER_ADMIN | Listar con paginación y búsqueda |
| GET | `/institutions/{id}` | SUPER_ADMIN, INSTITUTION_ADMIN (propia) | Detalle |
| POST | `/institutions` | SUPER_ADMIN | Crear institución |
| PUT | `/institutions/{id}` | SUPER_ADMIN | Actualizar |
| DELETE | `/institutions/{id}` | SUPER_ADMIN | Eliminación lógica (INACTIVE) |

---

## 4. Usuarios (Fase 7)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/users` | SUPER_ADMIN, INSTITUTION_ADMIN | Listar con filtros rol/institución |
| GET | `/users/{id}` | Según permiso | Detalle usuario |
| POST | `/users` | SUPER_ADMIN, INSTITUTION_ADMIN | Crear usuario |
| PUT | `/users/{id}` | Según permiso | Actualizar |
| PATCH | `/users/{id}/status` | SUPER_ADMIN, INSTITUTION_ADMIN | Cambiar estado |

---

## 5. Estudiantes (Fase 8)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/students` | Admin, Counselor (filtrado) | Listar estudiantes |
| GET | `/students/me` | STUDENT | Ficha del estudiante autenticado |
| GET | `/students/{id}` | Según permiso | Detalle estudiante |
| POST | `/students` | SUPER_ADMIN, INSTITUTION_ADMIN | Crear estudiante + usuario |
| PUT | `/students/{id}` | Según permiso | Actualizar |
| PATCH | `/students/{id}/status` | Admin | Cambiar estado |

---

## 6. Carreras (Fase 9)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/careers` | Autenticado | Listar con filtros área/RIASEC/título |
| GET | `/careers/{id}` | Autenticado | Detalle carrera |
| POST | `/careers` | SUPER_ADMIN | Crear carrera |
| PUT | `/careers/{id}` | SUPER_ADMIN | Actualizar |
| DELETE | `/careers/{id}` | SUPER_ADMIN | Eliminación lógica |

---

## 7. Preguntas RIASEC (Fase 10)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/questions` | Autenticado | Listar preguntas activas |
| POST | `/questions` | SUPER_ADMIN | Crear pregunta |
| PUT | `/questions/{id}` | SUPER_ADMIN | Actualizar |
| PATCH | `/questions/{id}/status` | SUPER_ADMIN | Activar/inactivar |

---

## 8. Test vocacional (Fase 11)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/tests` | STUDENT | Historial de sus evaluaciones, sin crear sesiones |
| POST | `/tests/start` | STUDENT | Continuar la única sesión abierta o iniciar una nueva |
| GET | `/tests/{session_id}/questions` | STUDENT (owner) | Preguntas de la sesión |
| POST | `/tests/{session_id}/answers` | STUDENT (owner) | Guardar respuesta (1-5) |
| POST | `/tests/{session_id}/finish` | STUDENT (owner) | Finalizar y calcular RIASEC |
| GET | `/tests/{session_id}/result` | STUDENT, COUNSELOR, Admin | Resultado RIASEC |

---

## 9. Vector / Qdrant (Fase 12)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| POST | `/vector/rebuild-careers` | SUPER_ADMIN | Reconstruir índice desde MySQL |
| POST | `/vector/search-careers` | Autenticado | Búsqueda semántica por perfil |

---

## 10. IA / Asistente (Fases 13, 25)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| POST | `/assistant/chat` | STUDENT | Chat con asistente virtual |
| POST | `/assistant/explain-profile` | STUDENT, COUNSELOR | Explicar perfil RIASEC |
| POST | `/assistant/explain-careers` | STUDENT, COUNSELOR | Explicar carreras recomendadas |

---

## 11. Recomendaciones (Fase 14 / S-21)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/recommendations/sessions/{session_id}` | Quien puede ver el resultado RIASEC | Lista persistida |
| POST | `/recommendations/sessions/{session_id}/generate` | STUDENT dueño (u roles con permiso de vista) | Genera/reemplaza recomendaciones |

- Orquestación: perfil RIASEC de la sesión completada → `VectorService.search_careers` (Qdrant; fallback MySQL) → puntuación híbrida 60% RIASEC + 40% vector → tabla `recommendations`.
- `data.used_fallback`: `true` cuando la búsqueda usó MySQL.
- Lista vacía si no hay carreras compatibles (no se inventan).
- Detalle: `docs/fase-14-recomendaciones.md`.

---


## 12. Reportes PDF (Fase 15)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/reports/{session_id}/pdf` | Según permiso de resultado | Genera (idempotente) o descarga PDF de evaluación `COMPLETED` |
| GET | `/reports/student/{student_id}` | Según permiso de ficha del estudiante | Historial paginado de informes PDF (metadatos; sin rutas de archivo) |

Respuesta binaria `application/pdf` con cabeceras `Content-Disposition` y `X-Report-Code`. Errores JSON estándar AVOV (`401`/`403`/`404`/`422`).

### Historial `GET /reports/student/{student_id}` (Fase 16A)

Query: `page` (≥1), `page_size` (1–100, default 20).

`data` paginado: `items`, `total`, `page`, `page_size`, `pages`. Cada ítem: `id`, `student_id`, `test_session_id`, `report_code`, `generated_by`, `created_at`, `updated_at`. Orden: más reciente primero. No incluye `file_path` ni rutas de almacenamiento.

Autorización (alineada a consulta de ficha / descarga PDF del mismo estudiante):

| Rol | Condición |
|-----|-----------|
| `STUDENT` | Solo su propio `student_id` |
| `COUNSELOR` | Asignación ACTIVE al estudiante |
| `INSTITUTION_ADMIN` | Misma institución |
| `SUPER_ADMIN` | Todos |

### Historial frente a descarga PDF vigente

El historial (`GET /reports/student/{student_id}`) y la descarga (`GET /reports/{session_id}/pdf`) son operaciones distintas:

| Aspecto | Historial | Descarga PDF |
|---------|-----------|--------------|
| Finalidad | Listar metadatos de registros `Report` del estudiante (paginado) | Obtener el archivo PDF de una evaluación `COMPLETED` |
| Identificador de entrada | `student_id` (+ `page`, `page_size`) | `session_id` (sesión de test) |
| Identificador por fila | `id` del informe en la respuesta JSON (`Report.id`) y `test_session_id` | No usa el `id` del registro histórico |

Puede haber varios registros históricos con el mismo `test_session_id`. La descarga se solicita solo con `session_id` y el backend devuelve el **PDF vigente** de esa sesión (el último informe asociado a esa sesión). No existe en esta API una descarga por `id` de informe (`report_id`) que recupere una versión histórica concreta de cada fila.

Consecuencia para la UI: varias filas del historial de la misma sesión pueden mostrar `report_code` distintos y, aun así, la acción de descarga de cada una obtiene el mismo PDF vigente de la sesión. Detalle de alcance y limitaciones: `docs/fase-16a-historial-informes.md`.

---

## 13. Dashboard (Fase 19)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/dashboard/super-admin` | SUPER_ADMIN | Métricas globales |
| GET | `/dashboard/institution` | INSTITUTION_ADMIN | Métricas institución |
| GET | `/dashboard/counselor` | COUNSELOR | Métricas orientador |
| GET | `/dashboard/student` | STUDENT | Estado test y resultados |

---

## 14. Auditoría (Fase 26)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/audit/logs` | SUPER_ADMIN | Listar logs con filtros |
| GET | `/audit/logs/{id}` | SUPER_ADMIN | Detalle de log |

---

## 15. Exportaciones (Fase 19)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/exports/students` | INSTITUTION_ADMIN | Exportar estudiantes CSV |
| GET | `/exports/test-results` | INSTITUTION_ADMIN, COUNSELOR | Exportar resultados |

---

## Resumen

Fuente de verdad de rutas activas: routers registrados en `backend/app/main.py` y el esquema OpenAPI de la aplicación. Este documento aún describe grupos planificados; no asumir disponibilidad solo por aparecer en una tabla.

| Grupo | Endpoints |
|-------|-----------|
| Sistema | 4 |
| Auth | 7 |
| Instituciones | 5 |
| Usuarios | 5 |
| Estudiantes | 5 |
| Carreras | 5 |
| Preguntas | 4 |
| Test | 5 |
| Vector | 2 |
| Asistente | 3 |
| Recomendaciones | 0 (no implementadas ni registradas; ver §11) |
| Reportes | 2 |
| Dashboard | 4 |
| Auditoría | 2 |
| Exportaciones | 2 |
| **Total documentado (excl. recomendaciones inexistentes)** | **53** |
