# Plan de desarrollo — AVOV (32 fases)

**Versión:** Fase 0  
**Metodología:** Desarrollo incremental con validación obligatoria entre fases

---

## Regla de avance

Cada fase debe completarse y validarse antes de continuar. El usuario confirma con:

> **"Continúa con la FASE X"**

---

## Roadmap completo

| Fase | Nombre | Entregable clave | Dependencias |
|------|--------|------------------|--------------|
| **0** | Análisis inicial | Documentación de arquitectura, entidades, endpoints, pantallas, flujos | — |
| **1** | Monorepo | Estructura carpetas completa, README, `.env.example` | 0 |
| **2** | Docker | Compose funcional: MySQL, phpMyAdmin, Redis, Qdrant, backend | 1 |
| **3** | Backend base | Health, CORS, errores estándar, conexiones | 2 |
| **4** | Modelo BD | 12+ tablas, migraciones Alembic, seeds | 3 |
| **5** | Auth | JWT, roles, bcrypt, middleware | 4 |
| **6** | CRUD instituciones | Endpoints + permisos SUPER_ADMIN | 5 |
| **7** | CRUD usuarios | Endpoints + permisos por rol | 5, 6 |
| **8** | CRUD estudiantes | Endpoints + asignaciones | 5, 7 |
| **9** | Catálogo carreras | CRUD + seed ejemplo | 5 |
| **10** | Preguntas RIASEC | 60 preguntas + CRUD | 4, 5 |
| **11** | Motor test | Sesiones, respuestas, cálculo RIASEC | 10, 8 |
| **12** | Qdrant | Embeddings, búsqueda, rebuild | 9, 3 |
| **13** | DeepSeek | Adaptador IA, fallback | 3 |
| **14** | Recomendaciones | Motor híbrido RIASEC+Qdrant+IA | 11, 12, 13 |
| **15** | PDF | Generación reportes ReportLab | 14 |
| **16** | Flutter base | Tema, router, Dio, interceptores | 3 |
| **17** | Validadores FE | Validadores reutilizables español | 16 |
| **18** | Login FE | Pantalla login + redirección rol | 5, 16, 17 |
| **19** | Dashboards | 4 dashboards por rol | 18 |
| **20** | FE instituciones | CRUD frontend instituciones | 6, 19 |
| **21** | FE usuarios | CRUD frontend usuarios | 7, 19 |
| **22** | FE estudiantes | CRUD frontend estudiantes | 8, 19 |
| **23** | FE test | Pantallas test vocacional | 11, 19 |
| **24** | FE resultados | Resultados, PDF, observaciones | 14, 15, 23 |
| **25** | Asistente FE | Chat con backend IA | 13, 24 |
| **26** | Auditoría | Logs + endpoint + pantalla | 5 |
| **27** | Tests backend | pytest ≥70% cobertura | 5-15 |
| **28** | Tests frontend | flutter test + analyze | 16-25 |
| **29** | Seguridad | OWASP, rate limit, CORS, secrets | 5, 27 |
| **30** | Documentación | Manuales, checklists, guías | Todas |
| **31** | Producción | Docker prod, Nginx, SSL, backups | 29, 30 |
| **32** | Checklist final | Validación integral 15 criterios | 31 |

---

## Agrupación por bloques

### Bloque A — Infraestructura (Fases 0-3)

Análisis, monorepo, Docker, backend base.

### Bloque B — Datos y seguridad (Fases 4-5)

Modelo MySQL, autenticación JWT.

### Bloque C — CRUD core (Fases 6-10)

Instituciones, usuarios, estudiantes, carreras, preguntas.

### Bloque D — Motor vocacional (Fases 11-15)

Test RIASEC, Qdrant, DeepSeek, recomendaciones, PDF.

### Bloque E — Frontend (Fases 16-25)

Flutter completo con todos los paneles.

### Bloque F — Calidad y entrega (Fases 26-32)

Auditoría, pruebas, seguridad, documentación, producción.

---

## Criterio de calidad final (Fase 32)

El proyecto se considera terminado cuando:

1. Se ejecuta localmente con Docker
2. phpMyAdmin accesible en desarrollo
3. Login funcional con roles
4. Crear institución y usuario estudiante
5. Estudiante completa test de 60 preguntas
6. Sistema calcula RIASEC correctamente
7. Qdrant devuelve recomendaciones
8. DeepSeek genera explicación (o fallback)
9. PDF se genera y descarga
10. Cada rol ve solo lo permitido
11. Validaciones frontend y backend funcionan
12. Pruebas automatizadas pasan
13. Documentación completa
14. Guía de producción lista
15. Checklist QA aprobado

---

## Estado actual del proyecto

| Fase | Estado |
|------|--------|
| 0 | **Completada** — Documentación en `docs/` |
| 1 | **Completada** — Estructura monorepo profesional |
| 2 | **Completada** — Docker Compose operativo |
| 3 | **Completada** — Backend base + errores estándar |
| 4 | **Completada** — 17 tablas + migraciones Alembic |
| 5-32 | Pendiente |

### Próximo paso

Escribir **"Continúa con la FASE 1"** para completar estructura del monorepo.
