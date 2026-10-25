# Estado actual AVOV Platform — diagnóstico Fase 0

**Fecha de comprobación:** 2026-10-25  
**Autor:** auditoría de continuidad (sin merge ni despliegue)  
**Remoto:** `https://github.com/boris13jbb/avov-platform.git`

Este documento sustituye, para el cierre v1, el estado obsoleto de `docs/PROJECT_STATUS.md` (2026-10-15). No borra ese archivo histórico.

## 1. Fotografía del repositorio

| Entorno | Rama | HEAD | Notas |
|---------|------|------|--------|
| `origin/main` | `main` | `46c0a0e` | Merge PR #10 (v1-product-completion / fix dropdowns) |
| Copia Cursor `AVOV` | `feature/s21-career-recommendations` | `0dce77b` | WIP local (scripts E2E/CDP, hooks); **no descartar** |
| `AVOV-v1-master` | `feature/v1-product-completion` | `46c0a0e` | WIP amplio de cierre; no mezclar |
| Worktrees `AVOV-v1-*` | ramas de PRs atómicos | ver §3 | Usar para cierre v1 |

### WIP en `AVOV` (ajeno a esta tarea; conservar)

- Modificados: `AGENTS.md`, `scripts/dev-backend-e2e-isolated.ps1`, `backend/scripts/prepare_e2e_s21_disposable_session.py`
- Sin seguimiento: hooks continual-learning, scripts CDP, `verify-backend-e2e-isolated.ps1`, regla Untitled

## 2. Arquitectura comprobada en `main`

Stack: Flutter (Riverpod/GoRouter) + FastAPI + MySQL 8 + Redis + Qdrant + DeepSeek (solo backend).

Routers registrados en `main` (entre otros): auth, institutions, users, students, assignments, careers, questions, tests, recommendations, reports, vector, assistant. Stub vacío de auditoría (`/audit` sin handlers) hasta PR #16.

## 3. PRs abiertos verificados (SHA actuales)

| PR | Rama | SHA head | Mergeable | CI visto | Integrado en `main` |
|----|------|----------|-----------|----------|---------------------|
| #11 product-ci | `chore/product-ci` | `a03ff54` | MERGEABLE / **BLOCKED** | e2e-static FAIL; backend-pytest FAIL; frontend-flutter FAIL | No |
| #12 change-password FE | `feature/v1-change-password-fe` | `5a046c6` | CLEAN | e2e-static OK | No |
| #13 prod/móvil | `chore/v1-prod-mobile-prep` | `521ec53` | BLOCKED | (ruleset) | No |
| #14 forgot/reset | `feature/v1-password-recovery` | `ceb97d6` | CLEAN | e2e-static OK | No |
| #15 observaciones | `feature/v1-observations` | `289c96c` | CLEAN | e2e-static OK (no product-ci) | No |
| #16 auditoría | `feature/v1-audit-query` | `61a134f` | CLEAN | e2e-static OK | No |
| #17 asistente | `feature/v1-assistant-ui` | `aa499fb` | CLEAN | e2e-static OK | No |
| #18 catálogo admin | `feature/v1-admin-catalog-fe` | `f1acd25` | CLEAN | e2e-static OK | No |

**Nota CI:** el único workflow activo en `main` es `e2e-tooling-static`. No valida pytest/Flutter de producto. El pass de ese check **no** aprueba funcionalidad.

## 4. Causas del bloqueo PR #11 (verificadas en logs run `40169409592` / `40169409601`)

1. **e2e-tooling-static:** `docs/ci-product.md:3` trailing whitespace (`git diff --check`).
2. **backend-pytest:**
   - `DEEPSEEK_API_KEY=your-deepseek-api-key-here` en el job pisa `Settings(..., deepseek_api_key=...)` → fallan 3 tests de `test_deepseek_config.py`.
   - Sin servicio Qdrant → `test_rebuild_careers_as_super_admin` 422; `test_generate_recommendations_with_qdrant_path` usa fallback.
3. **frontend-flutter:** 2 fallos por `Timer is still pending` en `student_manage_test` (detalle) y `student_space_test` (perfil).

## 5. Matriz de riesgos (cierre v1)

| ID | Riesgo | Severidad | Mitigación |
|----|--------|-----------|------------|
| R1 | Integrar #15–#18 sin product-ci verde | Alta | Desbloquear #11 antes o validar localmente cada merge |
| R2 | Conflicto hub `admin_dashboard` entre #16 y #18 | Alta | Orden: #18 luego #16; resolución manual de botones |
| R3 | WIP de `AVOV` / `AVOV-v1-master` tocado por error | Alta | Solo worktrees `AVOV-v1-*` |
| R4 | Rebuild Qdrant / datos productivos | Alta | No ejecutar rebuild destructivo en `avov_db` |
| R5 | Exposición `details` en API auditoría (#16) | Media | Revisar antes de merge #16 |
| R6 | Coste DeepSeek sin rate-limit en `main` | Media | Depende de merge #17 |

## 6. Plan de fases (estado)

| Fase | Nombre | Estado |
|------|--------|--------|
| 0 | Diagnóstico y protección | **EN CURSO** → entregable este archivo |
| 1 | Cierre funcionalidades v1 (#15–#18) | PENDIENTE (PRs listos; sin merge) |
| 2 | CI y pruebas (#11) | **EN CURSO** (correcciones locales en worktree product-ci) |
| 3 | Integración controlada | PENDIENTE (requiere auth por PR) |
| 4 | Validación integral | PENDIENTE |
| 5 | Seguridad / prod | PENDIENTE (#13 y docs) |
| 6 | Cierre de versión | PENDIENTE |

### Orden de merge recomendado (sin autorizar aún)

1. #11 (cuando CI verde)  
2. #15 observaciones  
3. #17 asistente  
4. #18 catálogo admin  
5. #16 auditoría (resolver dashboard con #18)  
6. #12 / #14 auth UI  
7. #13 prod/móvil tras revisión de bloqueo

## 7. Primer pendiente de bajo riesgo

**Desbloquear PR #11** en `C:\Users\BRS\Documents\AVOV-v1-product-ci` sin tocar `AVOV` ni merge a `main`.

Correcciones preparadas en ese worktree (pendientes de commit/push autorizados):

- Quitar trailing whitespace en `docs/ci-product.md`
- Servicio Qdrant + clave DeepSeek de CI no marcadora en `product-ci.yml`
- Aislar env en `test_deepseek_config.py`
- Limpiar timers en tests Flutter citados
- Este diagnóstico en `docs/development/estado-actual.md`

## 8. Criterios para cerrar Fase 0

- [x] Inventario ramas/worktrees/PR/SHA comprobado
- [x] Base `origin/main` = `46c0a0e`
- [x] Causas de #11 identificadas con evidencia de logs
- [x] Documento de estado publicado en worktree seguro
- [ ] Commit/push del diagnóstico + fix CI (requiere autorización)
- [ ] CI de #11 en verde tras push (requiere autorización de push)
