# FASE 12 — Vector / Qdrant

## Objetivo

Sincronizar carreras activas de MySQL hacia Qdrant y habilitar búsqueda semántica por perfil vocacional.

## Componentes implementados

| Capa | Archivo | Responsabilidad |
|------|---------|-----------------|
| Schema | `schemas/vector.py` | Búsqueda y rebuild |
| Embedding | `services/embedding_service.py` | Texto y vectores locales determinísticos |
| Qdrant | `services/qdrant_service.py` | Colección, upsert y search |
| Service | `services/vector_service.py` | Orquestación y fallback MySQL |
| Routes | `api/routes/vector.py` | Endpoints REST |

## Endpoints

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| POST | `/api/v1/vector/rebuild-careers` | SUPER_ADMIN | Reconstruir índice desde MySQL |
| POST | `/api/v1/vector/search-careers` | Autenticado | Búsqueda semántica |

## Payload búsqueda

```json
{
  "riasec_profile": "RIA",
  "query": "carreras tecnológicas",
  "limit": 10
}
```

Al menos uno de `riasec_profile` o `query` es obligatorio.

## Texto de embedding (carrera)

```
"{name} | {area} | Perfil {riasec_profile} | {description} | Campo: {employment_field}"
```

## Metadata Qdrant

`career_id`, `name`, `area`, `riasec_profile`, `degree_type`, `institution_type`, `status`

## Reglas

- MySQL es fuente de verdad; Qdrant es derivado.
- `rebuild-careers` recrea la colección e indexa solo carreras `ACTIVE`.
- Si Qdrant falla en búsqueda, fallback MySQL por coincidencia RIASEC.
- Embeddings locales determinísticos (MVP); API externa en fases posteriores.

## Criterios de validación

- [x] Rebuild SUPER_ADMIN operativo
- [x] Búsqueda autenticada por perfil RIASEC
- [x] Fallback MySQL documentado
- [x] Tests pytest pasan

## Siguiente fase

**FASE 13 — IA / Asistente (DeepSeek, explicación de perfil y carreras)**
