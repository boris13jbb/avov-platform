# FASE 14 — Motor de recomendaciones (RIASEC + Qdrant + IA)

## Objetivo

Generar recomendaciones de carreras personalizadas tras completar el test vocacional, combinando:

- **60%** afinidad RIASEC (perfil dominante + secundario vs `career.riasec_profile`)
- **40%** similitud vectorial Qdrant (o fallback MySQL)
- **Explicación IA** con DeepSeek (fallback estático si falla)

## Endpoints

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| POST | `/api/v1/recommendations/generate` | STUDENT | Genera y persiste recomendaciones |
| GET | `/api/v1/recommendations/student/{student_id}` | Según permiso | Lista recomendaciones del estudiante |
| POST | `/api/v1/recommendations/{id}/observations` | COUNSELOR | Agrega observación profesional |

## Fórmula híbrida

```
match_percentage = (riasec_score * 0.60) + (qdrant_score * 0.40)
```

- `riasec_score`: coincidencia de letras dominante/secundario con el perfil RIASEC de la carrera (0-100).
- `qdrant_score`: score vectorial normalizado (0-100) desde Qdrant o fallback MySQL.

## Flujo `generate`

1. Validar estudiante autenticado y test `COMPLETED` con resultado RIASEC.
2. Si ya existen recomendaciones para la sesión → devolver persistidas (idempotente).
3. Consultar cache Redis (`avov:recommendations:session:{id}`, TTL 24h).
4. Buscar candidatos con `VectorService.search_careers` usando `combined_profile`.
5. Completar hasta mínimo 5 carreras activas si hace falta.
6. Calcular `match_percentage` híbrido y ordenar descendente.
7. Persistir top 5 en tabla `recommendations`.
8. Generar explicación IA colectiva (`explain_careers`) + texto breve por ítem.
9. Cachear respuesta en Redis.

## Archivos implementados

| Archivo | Responsabilidad |
|---------|-----------------|
| `backend/app/schemas/recommendation.py` | Schemas request/response |
| `backend/app/repositories/recommendation_repository.py` | Persistencia MySQL |
| `backend/app/services/recommendation_service.py` | Motor híbrido + cache |
| `backend/app/api/routes/recommendations.py` | Endpoints REST |
| `backend/tests/test_recommendations.py` | Pruebas automatizadas |

## Validación manual (PowerShell)

```powershell
# 1. Login estudiante con test completado
$login = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/login" `
  -Method POST -ContentType "application/json" `
  -Body '{"email":"estudiante@instituto.edu.co","password":"Estud1234!"}'
$token = $login.data.access_token
$headers = @{ Authorization = "Bearer $token" }

# 2. Generar recomendaciones
$gen = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/recommendations/generate" `
  -Method POST -Headers $headers -ContentType "application/json" -Body '{}'

$gen.data.items | Select-Object match_percentage, riasec_score, qdrant_score, @{n='career';e={$_.career.name}}

# 3. Listar por estudiante
$studentId = $gen.data.student_id
Invoke-RestMethod -Uri "http://localhost:8000/api/v1/recommendations/student/$studentId" `
  -Headers $headers
```

## Criterios de aceptación

- [x] Mínimo 5 carreras recomendadas cuando existan en catálogo.
- [x] Solo carreras `ACTIVE`.
- [x] Sin duplicados por sesión (`UNIQUE test_session_id + career_id`).
- [x] `match_percentage` entre 0 y 100.
- [x] Idempotencia al regenerar misma sesión.
- [x] Permisos por rol al listar y observar.
- [x] Fallback IA si DeepSeek no responde.
- [x] Cache Redis opcional (no bloquea si Redis no está disponible).

## Siguiente fase

**FASE 15 — Reportes PDF** (`GET /reports/{test_session_id}/pdf`).
