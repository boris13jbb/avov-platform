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

## 11. Recomendaciones (Fase 14) — No implementado / no disponible

**Estado verificado en el código actual:**

- Existe el stub `backend/app/api/routes/recommendations.py`: solo declara `APIRouter(prefix="/recommendations")` **sin handlers**.
- Ese router **no** está incluido en `backend/app/main.py` (`include_router`).
- OpenAPI no expone ninguna ruta `/api/v1/recommendations*`.
- No existe `recommendation_service.py`.
- La eventual tabla MySQL `recommendations` (esquema) **no** implica API disponible.

**Separación con el comportamiento actual del test vocacional:**

- Los puntajes y el perfil RIASEC calculados tras finalizar un test están disponibles con `GET /tests/{session_id}/result` (sección 8).
- Las **recomendaciones de carreras** (generación, listado u observaciones de orientador) son funcionalidad planificada de la Fase 14 y **no están disponibles** hasta que se implementen handlers y se registre el router.

No se documentan aquí rutas, parámetros ni códigos de respuesta futuros: el contrato se publicará solo cuando exista implementación registrada.

---


## 12. Reportes PDF (Fase 15)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/reports/{test_session_id}/pdf` | Según permiso | Descargar PDF |
| GET | `/reports/student/{student_id}` | Según permiso | Historial de reportes |

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
