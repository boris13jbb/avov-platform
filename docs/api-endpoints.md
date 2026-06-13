# API Endpoints — AVOV

**Base URL:** `http://localhost:8000/api/v1`  
**Raíz servidor:** `http://localhost:8000/` (misma información que `/api/v1/`)  
**Última revisión:** Fase 33 — alineado con implementación actual

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
| GET | `/` | Público | Información básica (raíz del servidor) |
| GET | `/api/v1/` | Público | Información básica bajo el prefijo API |
| GET | `/health` | Público | Health completo (MySQL, Redis, Qdrant) |
| GET | `/health/live` | Público | Liveness probe |
| GET | `/status` | Público | Estado detallado de servicios |

---

## 2. Autenticación (Fase 5)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| POST | `/auth/login` | Público | Iniciar sesión, retorna JWT |
| POST | `/auth/logout` | Autenticado | Cerrar sesión, revocar refresh token |
| POST | `/auth/refresh` | Público | Renovar access token (requiere `refresh_token` en body) |
| GET | `/auth/me` | Autenticado | Perfil del usuario actual |
| POST | `/auth/change-password` | Autenticado | Cambiar contraseña |
| POST | `/auth/forgot-password` | Público | Solicitar enlace de recuperación (respuesta genérica) |
| POST | `/auth/reset-password` | Público | Restablecer contraseña con token del correo |

---

## 3. Instituciones (Fase 6)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/institutions` | SUPER_ADMIN | Listar con paginación y búsqueda |
| GET | `/institutions/{id}` | SUPER_ADMIN, INSTITUTION_ADMIN (propia) | Detalle |
| POST | `/institutions` | SUPER_ADMIN | Crear institución |
| PUT | `/institutions/{id}` | SUPER_ADMIN, INSTITUTION_ADMIN (propia; sin `code`/`status`) | Actualizar |
| POST | `/institutions/{id}/logo` | SUPER_ADMIN, INSTITUTION_ADMIN (propia) | Subir logo institucional |
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
| GET | `/students` | SUPER_ADMIN, INSTITUTION_ADMIN, COUNSELOR (filtrado) | Listar estudiantes |
| GET | `/students/{id}` | Según permiso | Detalle estudiante |
| POST | `/students` | SUPER_ADMIN, INSTITUTION_ADMIN | Crear estudiante + usuario |
| PUT | `/students/{id}` | SUPER_ADMIN, INSTITUTION_ADMIN, STUDENT (propio perfil) | Actualizar |
| POST | `/students/{id}/assign-counselor` | SUPER_ADMIN, INSTITUTION_ADMIN | Asignar orientador |
| PATCH | `/students/{id}/status` | SUPER_ADMIN, INSTITUTION_ADMIN | Cambiar estado |

---

## 6. Carreras (Fase 9)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/careers` | Autenticado | Listar con filtros área/RIASEC/título |
| GET | `/careers/{id}` | Autenticado | Detalle carrera |
| POST | `/careers` | SUPER_ADMIN | Crear carrera (sincroniza Qdrant automáticamente) |
| PUT | `/careers/{id}` | SUPER_ADMIN | Actualizar |
| DELETE | `/careers/{id}` | SUPER_ADMIN | Eliminación lógica |

---

## 7. Preguntas RIASEC (Fase 10)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/questions` | Autenticado | Listar preguntas activas |
| GET | `/questions/{id}` | Autenticado (inactivas solo SUPER_ADMIN) | Detalle pregunta |
| POST | `/questions` | SUPER_ADMIN | Crear pregunta |
| PUT | `/questions/{id}` | SUPER_ADMIN | Actualizar |
| PATCH | `/questions/{id}/status` | SUPER_ADMIN | Activar/inactivar |
| DELETE | `/questions/{id}` | SUPER_ADMIN | Desactivar pregunta (baja lógica) |

---

## 8. Test vocacional (Fase 11)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| POST | `/tests/start` | STUDENT | Iniciar o continuar test |
| GET | `/tests/{session_id}/questions` | STUDENT (owner) | Preguntas de la sesión |
| POST | `/tests/{session_id}/answers` | STUDENT (owner) | Guardar respuesta (1-5) |
| POST | `/tests/{session_id}/finish` | STUDENT (owner) | Finalizar y calcular RIASEC |
| GET | `/tests/{session_id}/result` | STUDENT, COUNSELOR, INSTITUTION_ADMIN, SUPER_ADMIN | Resultado RIASEC |
| POST | `/tests/{session_id}/observations` | COUNSELOR | Observación por sesión de test |

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

## 11. Recomendaciones (Fase 14)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| POST | `/recommendations/generate` | STUDENT | Generar recomendaciones post-test |
| GET | `/recommendations/student/{student_id}` | Según permiso | Listar recomendaciones |
| POST | `/recommendations/{id}/observations` | COUNSELOR | Agregar observación profesional |

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

## 15. Configuración del sistema (Fase 29)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/settings/public` | Público | Nombre app, disclaimer ético y modo mantenimiento |
| GET | `/settings` | SUPER_ADMIN | Listar parámetros del sistema |
| PUT | `/settings/{key}` | SUPER_ADMIN | Actualizar parámetro (`app_display_name`, `ethical_disclaimer`, `max_recommendations_per_session`, `maintenance_mode`) |

---

## 16. Categorías RIASEC (Fase 29)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/riasec-categories` | Autenticado | Listar categorías RIASEC |

---

## 17. Media (Fase 28)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/media/logos/{filename}` | Público | Servir logos institucionales |

---

## 18. Exportaciones (Fase 19)

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/exports/students` | INSTITUTION_ADMIN | Exportar estudiantes CSV |
| GET | `/exports/test-results` | INSTITUTION_ADMIN, COUNSELOR | Exportar resultados |

---

## Resumen

| Grupo | Endpoints |
|-------|-----------|
| Sistema | 5 |
| Auth | 7 |
| Instituciones | 6 |
| Usuarios | 5 |
| Estudiantes | 6 |
| Carreras | 5 |
| Preguntas | 6 |
| Configuración | 3 |
| RIASEC | 1 |
| Media | 1 |
| Test | 6 |
| Vector | 2 |
| Asistente | 3 |
| Recomendaciones | 3 |
| Reportes | 2 |
| Dashboard | 4 |
| Auditoría | 2 |
| Exportaciones | 2 |
| **Total bajo `/api/v1`** | **60** |
