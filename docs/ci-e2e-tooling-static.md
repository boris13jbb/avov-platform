# Gate CI `e2e-tooling-static`

Documentación operativa del workflow `.github/workflows/e2e-tooling-static.yml` y de su relación con la protección de `main`.

## Alcance del check

El job GitHub Actions llamado exactamente `e2e-tooling-static` es un **gate de validación estática** del tooling PowerShell E2E aislado. Es el check obligatorio exigido por el ruleset del repositorio para fusionar hacia `main`.

Valida:

- Sintaxis PowerShell (parser, sin ejecutar) de:
  - `scripts/dev-backend-e2e-isolated.ps1`
  - `scripts/stop-backend-e2e-isolated.ps1`
  - `scripts/verify-backend-e2e-isolated.ps1`
- `git diff --check` sobre el rango de commits del evento (`pull_request` o `push`).

No valida:

- Ejecución operativa de esos scripts.
- Aislamiento real de MySQL (`avov_test`) ni Redis.
- `pytest`, `flutter analyze`, `flutter test` ni flujos E2E funcionales de AVOV Platform.

La guía operativa de los scripts sigue en `docs/s-20-e2e-estudiante.md` (sección de tooling backend E2E aislado).

## Triggers

- `pull_request` dirigido a `main`
- `push` a `main`

Sin filtros `paths` / `paths-ignore`. El check debe generarse para los PR a `main` aunque el cambio no toque `scripts/`.

## Política frente a marcadores de omisión de CI

GitHub puede omitir workflows disparados por `push` o `pull_request` si el mensaje del commit (o el HEAD del PR) incluye marcadores como:

- `[skip ci]`
- `[ci skip]`
- `[no ci]`
- `[skip actions]`
- `[actions skip]`
- el trailer `skip-checks: true` (según la documentación vigente de GitHub)

Si se omite el workflow que produce `e2e-tooling-static`, el check obligatorio puede quedar en estado pendiente y **bloquear la fusión** a `main` mientras el ruleset lo exija.

**Política del proyecto:** los autores no deben usar esos marcadores en commits de PR dirigidos a `main` mientras `e2e-tooling-static` sea obligatorio.

Esta política es de proceso: la documentación **no** impide técnicamente escribir esos marcadores.

Si una ejecución se omite por accidente:

1. Corregir el mensaje de commit o crear un commit nuevo sin el marcador.
2. Verificar que el check `e2e-tooling-static` aparece y termina correctamente en el PR.
3. No desactivar ni eludir el ruleset para forzar el merge.

## Relación con el ruleset

El nombre del check (`e2e-tooling-static`) forma parte del contrato con la protección de `main`. Renombrarlo exige actualizar el ruleset en el mismo cambio autorizado; no se debe hacer de forma incidental.
