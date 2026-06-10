# Criterios de validación — FASE 0

**Proyecto:** AVOV — Asistente Virtual de Orientación Vocacional con IA  
**Fecha de cierre:** Junio 2026

---

## Objetivo de la FASE 0

Definir la arquitectura, estructura, entidades, endpoints, pantallas y flujos del sistema **antes de escribir código de negocio**. Esta fase produce documentación verificable, no funcionalidad ejecutable.

---

## Checklist de documentación

| # | Criterio | Estado | Evidencia |
|---|----------|--------|-----------|
| 1 | Arquitectura general definida con regla MySQL > Qdrant | Completado | [arquitectura.md](arquitectura.md) |
| 2 | Diagrama de 20 módulos con dependencias | Completado | [arquitectura.md](arquitectura.md) §5 |
| 3 | Estructura carpetas backend y frontend acordada | Completado | [estructura-proyecto.md](estructura-proyecto.md) |
| 4 | Lista de entidades con relaciones y enums | Completado | [modelo-base-datos.md](modelo-base-datos.md) |
| 5 | Lista de 56 endpoints con roles y fases | Completado | [api-endpoints.md](api-endpoints.md) |
| 6 | Lista de 42 pantallas con rutas GoRouter | Completado | [pantallas-flutter.md](pantallas-flutter.md) |
| 7 | Flujo de usuario por rol documentado | Completado | [flujos.md](flujos.md) §1 |
| 8 | Flujo test vocacional RIASEC documentado | Completado | [flujos.md](flujos.md) §2 |
| 9 | Flujo recomendación IA+Qdrant documentado | Completado | [flujos.md](flujos.md) §3 |
| 10 | Flujo generación PDF documentado | Completado | [flujos.md](flujos.md) §4 |
| 11 | Flujo de despliegue documentado | Completado | [flujos.md](flujos.md) §6 |
| 12 | Roadmap 32 fases definido | Completado | [plan-desarrollo.md](plan-desarrollo.md) |

---

## Checklist de decisiones técnicas

| # | Decisión | Estado | Detalle |
|---|----------|--------|---------|
| 1 | Monorepo en `aplicstibi/` | Aprobado | Sin renombrar a `avov-platform/` |
| 2 | Entidades complementarias | Aprobado | `counselor_assignments`, `counselor_observations`, `system_settings`, `refresh_tokens` |
| 3 | Adaptador LLM intercambiable | Aprobado | Interface `LLMProvider` + DeepSeek + Fallback |
| 4 | Algoritmo híbrido recomendación | Aprobado | 60% RIASEC + 40% Qdrant + explicación IA |
| 5 | Flutter desktop en estructura | Aprobado | Builds validados en Fase 31 |
| 6 | Eliminación lógica | Aprobado | `status = INACTIVE`, no DELETE físico |
| 7 | Respuesta JSON estándar | Aprobado | Ya implementado en `core/responses.py` |

---

## Checklist de alineación con código existente

| # | Elemento | Estado | Nota |
|---|----------|--------|------|
| 1 | Scaffold Fases 1-2 reconocido | Completado | Base válida, no conflicto |
| 2 | Carpetas backend pendientes identificadas | Completado | Ver [estructura-proyecto.md](estructura-proyecto.md) |
| 3 | Carpetas frontend pendientes identificadas | Completado | Ver [estructura-proyecto.md](estructura-proyecto.md) |
| 4 | `modelo-base-datos.md` diseño completo | Completado | Implementación Alembic en Fase 4 |
| 5 | `.env.example` variables definidas | Completado | Archivo existente en raíz |
| 6 | `docker-compose.yml` servicios definidos | Completado | 5 servicios + health checks |

---

## Comandos de verificación (Fase 0)

La Fase 0 no requiere servicios en ejecución. Verificación documental:

```powershell
# Verificar que existen todos los documentos de Fase 0
Get-ChildItem docs\ -Name

# Resultado esperado incluye:
# arquitectura.md
# estructura-proyecto.md
# modelo-base-datos.md
# api-endpoints.md
# pantallas-flutter.md
# flujos.md
# plan-desarrollo.md
# criterios-validacion-fase0.md
# fase-0-analisis.md
```

---

## Resultado de validación

| Aspecto | Resultado |
|---------|-----------|
| Documentación | Completa |
| Decisiones técnicas | Cerradas |
| Alineación con scaffold | Confirmada |
| Errores encontrados | Ninguno bloqueante |
| **Estado FASE 0** | **COMPLETADA Y VALIDADA** |

---

## Próximo paso

Para iniciar la FASE 1 (completar estructura del monorepo), escribir:

> **"Continúa con la FASE 1"**
