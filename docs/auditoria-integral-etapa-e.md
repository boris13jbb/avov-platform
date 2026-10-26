# Auditoría integral AVOV — Etapa E (QA)

**Rama:** `feature/audit-integral-uiux`
**Alcance de código de la rama:** frontend (navegación, UI compartida, panel orientador). Backend sin cambios de producto en esta rama.

## Frontend (worktree)

```powershell
cd frontend
flutter analyze
flutter test
```

| Comando | Resultado |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | **All tests passed (202)** |

## Backend

Ejecutado desde el código del worktree con el venv de `AVOV/backend` y `DATABASE_URL` apuntando a `avov_test` en `127.0.0.1:3307`.

| Comando | Resultado |
|---|---|
| `pytest -q` | **246 passed, 1 failed** |

### Fallo observado

- `tests/test_vector.py::test_search_careers_by_riasec_profile` — `assert False`
- Probable dependencia de entorno Qdrant / índice vectorial; **no introducido por los commits de esta rama** (solo tocan frontend + docs).
- No bloquea la entrega de navegación/UI; conviene reejecutar con Qdrant sano en un entorno limpio.

## Veredicto parcial

- FE: OK
- BE: OK salvo 1 test vectorial de entorno
- Regresión atribuible a esta rama: no evidenciada en FE; BE sin diff de código de app
