# CI de producto — AVOV

**Workflow:** `.github/workflows/product-ci.yml`  
**Complementa:** `e2e-tooling-static` (parser PowerShell + `git diff --check`).

## Qué ejecuta

| Job | Contenido |
|-----|-----------|
| `backend-pytest` | MySQL 8.4 + Redis servicios; `alembic upgrade head`; `pytest` con schema `avov_test` |
| `frontend-flutter` | `flutter pub get`, `flutter analyze`, `flutter test` |

## Qué no ejecuta

- E2E Flutter Web contra API aislada
- Restore drills de backup
- Publicación en tiendas
- Llamadas reales a DeepSeek (tests usan mocks)

## Notas

- El ruleset de `main` puede seguir exigiendo solo `e2e-tooling-static` hasta actualizar la política de protección de rama.
- Credenciales CI son locales al job; no usar secretos de producción.
