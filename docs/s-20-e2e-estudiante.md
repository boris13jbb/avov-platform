# S-20 — Registro E2E del espacio estudiante

Fecha de registro: 2026-10-19
Rama de referencia: `docs/windows-continuity`
HEAD de referencia al registrar: `8c30f5a`

Documento **append-only**: las entradas nuevas se añaden al final o se amplían sin borrar ni reescribir la evidencia ya registrada.

## 1. Propósito y alcance

Este archivo es el registro de ejecución E2E manual de la fase **S-20** (espacio estudiante) en AVOV.

Los estados usados en este registro son:

| Estado | Significado |
|--------|-------------|
| Aprobado (UI) | Observación manual de interfaz coherente con el criterio del caso |
| Parcialmente verificado | Parte del caso se observó; faltan subcasos o evidencia (p. ej. HTTP) |
| No verificado | Sin evidencia E2E manual suficiente |
| Bloqueado | No se puede continuar con seguridad sin un requisito externo |
| Inconcluso | La prueba se intentó pero no se alcanzó el punto de comprobación |

Aclaraciones de método:

- Los tests automatizados (widget/unit/pytest) **no sustituyen** las comprobaciones E2E manuales.
- Una confirmación visual en la UI **no equivale** a capturar y verificar la petición HTTP correspondiente.
- Un clic sintético fallido **no demuestra** por sí solo un defecto de producto.

## 2. Evidencia histórica confirmada

Secuencia temporal resumida (sin alterar el orden de los hallazgos):

### Bloque 1

- **Estado:** Aprobado (UI), con limitación de automatización.
- Dashboard, perfil de solo lectura, navegación, retorno con historial del navegador, logout y rutas protegidas se observaron en la prueba manual anterior.
- Limitación documentada: el clic sintético no es fiable en algunos controles Flutter Web (`OutlinedButton`).

### B2-03 — Identidad STUDENT

- **Estado:** Aprobado (UI).
- Panel del estudiante, ficha e historial se comportaron de forma coherente con rol STUDENT (sin 403 visibles en esas pantallas tras la sesión correcta).

### B2-05 — Sesiones abiertas (subcasos)

| Subcaso | Estado | Nota |
|---------|--------|------|
| B2-05a Cero sesiones abiertas | Aprobado (UI) | Según inventario anterior del historial |
| B2-05b Una sesión abierta | Parcialmente verificado | Continuación desde la UI observada; **no** se afirmó captura del ID de sesión |
| B2-05c Varias sesiones abiertas | No verificado | Sin prueba manual de múltiples abiertas |

### B2-06 — Guardado progresivo

- **Estado:** Parcialmente verificado.
- La UI indicó confirmación de respuesta y el contador pasó de **0/60** a **1/60** y después a **2/60**.
- **No** se capturó HTTP de `POST /tests/{id}/answers`.

### S-20.9 / S-20.10 — Botón «Siguiente»

- **S-20.9:** diagnóstico; el botón se veía habilitado en P1 con respuesta confirmada; el código prevé avance con respuesta guardada.
- **S-20.10:** clic físico en el centro de «Siguiente» avanzó de **P1 a P2**; el contador permaneció en **2/60**; sin mensaje inesperado informado.
- Interacción sintética previa no avanzó de forma fiable.
- **Clasificación:** `LIMITACIÓN_DE_AUTOMATIZACIÓN` — **no** defecto reproducible.
- HTTP **no** capturado.

### S-20.12 — Intento de relectura P2

- **Estado:** Inconcluso.
- No se alcanzó P2 en esa tarea.
- Estado posterior observado: **P4**, contador **3/60**.
- **No** se atribuye causa.

### S-20.13 — Reintento controlado de persistencia P2

- Un clic físico en «Anterior» llevó la UI de **P4 a P2** (sin observación intermedia de P3 en esa transición).
- En P2: opción **4** seleccionada; mensaje «Respuesta confirmada por el servidor»; contador **3/60**.
- **Clasificación UI:** `APROBADO_UI` para la relectura de P2.
- HTTP **no** verificado.
- Salto **P4→P2** registrado **sin explicación**.

### S-20.18 — Relectura de P1 (contador 3/60)

- **Clasificación UI:** `APROBADO_UI`.
- Tras confirmación del usuario, observación visual (sin clics del agente en esa inspección): **Pregunta 1 de 60**, categoría **Realista (R)**.
- Texto: «Me gusta reparar objetos, equipos o maquinaria.»
- Opción **4** seleccionada; mensaje «Respuesta confirmada por el servidor.»
- Contador: **3/60**.
- «Anterior» y «Guardar» deshabilitados; «Siguiente» habilitado.
- HTTP **no** capturado ni verificado; **no** se afirma persistencia en backend ni en base de datos.
- No contradice S-20.7–S-20.13: refuerza la relectura UI de P1 con contador 3/60; B2-06 sigue **parcial** (sin HTTP).

### S-20.20 — Relectura de P2 tras P1

- Precondiciones en Chrome: P1 R, opción 4, confirmación, 3/60, «Siguiente» habilitado.
- Usuario confirmó clic físico en «Siguiente»; inspección posterior **sigue en P1** (mismos indicadores).
- **Clasificación:** `INCONCLUSO`.
- HTTP no verificado. **No** se atribuye causa.

### S-20.21 — Auditoría estática de navegación

- Código: con respuesta guardada y sin dirty, `_moveTo(_index + 1)` solo hace `setState` del índice; no hay reset de `_index` al reconstruir el provider.
- Widget test `volver a una pregunta muestra la respuesta confirmada` valida P1↔P2 con respuestas preguardadas.
- Conclusión documental: **no** hay defecto de producto demostrado; el resultado de S-20.20 no aísla si el callback se ejecutó.
- Hipótesis principal (no conclusión): fallo de activación del clic / contexto de ventana frente a bug de `_moveTo`.

### Campaña de automatización (2026-10-20)

**Entorno comprobado:** rama `docs/windows-continuity` @ `8c30f5a`; API health 200 (mysql/redis/qdrant); Flutter `:3000` 200; CDP Chrome en `127.0.0.1:60371`. DOM Flutter sin texto accesible (`FLT-GLASS-PANE`). Playwright no instalado como CLI de proyecto.

**Navegación P1→P2 vía computer-use/CDP:** un clic sintético dirigido a «Siguiente» **no** cambió la UI (sigue P1, 3/60). Sin repeticiones ciegas adicionales. Clasificación de automatización: `LIMITACIÓN_DE_AUTOMATIZACIÓN` / `INCONCLUSO` E2E. **No** se modificó código de producto (sin defecto reproducible).

**Tests Flutter ejecutados** (`flutter test` sobre archivos listados; resultado: **All tests passed**):

- `test/vocational_unsaved_answers_test.dart` — guardar, dirty, diálogo Cancelar/Descartar/Guardar, busy, relectura P1↔P2 → soporte `APROBADO_TEST` para B2-07 (ramas de diálogo) y navegación con respuestas guardadas.
- `test/vocational_finish_history_sync_test.dart` — finalización + refresco de historial (mocks) → `APROBADO_TEST` de sincronización; **no** sustituye E2E de finalización real.
- `test/student_open_sessions_test.dart`, `test/student_navigation_test.dart`, `test/auth_refresh_test.dart` — sesiones abiertas / menú / refresh (mocks) → `APROBADO_TEST`; **no** E2E JWT real.

**Backend:** `pytest tests/test_recommendations_not_registered.py` → **2 passed** (`APROBADO_TEST` de que recomendaciones no están registradas en la app).

**No ejecutado en esta campaña (bloqueo o riesgo):** B2-04 seed; B2-05c segunda sesión; B2-08/09 finalizar sesión QA actual; B2-01 forzar expiry JWT; captura HTTP Dio fiable; SQL de escritura; commit/push.

### B2-04 — Datos QA / seed seguro

- **Estado:** Bloqueado.
- Falta un mecanismo seguro disponible para generar los datos QA necesarios.
- Este registro **no** describe tokens ni busca secretos.

### S-20.25 — Guardia fail-fast `avov_test` (2026-10-20)

Implementada protección técnica en pytest (fase 1 del diseño S-20.24):

- Módulo `backend/tests/db_isolation.py`: valida el **nombre** de base parseado de `DATABASE_URL` (sin conectar a MySQL).
- Solo se acepta exactamente `avov_test`. Se rechazan `avov_db`, nombres desconocidos y URLs incompletas/no verificables.
- Los mensajes de error **no** incluyen URL completa ni credenciales.

### S-20.25-A — Auditoría adversarial de la guardia (2026-10-20)

**Defecto encontrado (reproducible por inspección):** `pytest_collection_finish` corre **después** de importar módulos de test que hacen `from app.db.session import SessionLocal`, lo que ejecuta `create_engine` **antes** de la guardia. Además, `conftest` importaba `app.main` al cargar. La excepción «solo test_db_isolation.py» debilitaba el fail-closed ante selecciones mixtas/ambiguas.

**Corrección:**
- Guardia movida a `pytest_configure` (antes de la colección/import de tests).
- Eliminada la excepción de módulo de aislamiento; los unitarios usan URLs literales y, al invocar pytest, requieren `DATABASE_URL` con schema `avov_test` (puede ser URL ficticia; no conecta).
- `app.main` / `SessionLocal` diferidos hasta fixtures / `_session_factory`.

**Validación (sin MySQL real):**
- `DATABASE_URL=mysql+pymysql://qa_user:qa_pass_not_real@127.0.0.1:3307/avov_test` + `pytest tests/test_db_isolation.py` → **14 passed**.
- Negativos: assert con URLs literales; subproceso con `create_engine` interceptado; `pytest tests/test_health.py --collect-only` con schema `avov_db` → `UnauthorizedTestDatabaseError` (exit ≠ 0).
- **No** se ejecutó suite destructiva ni fixtures `db`/`test_user`. **No** hubo escrituras SQL a `avov_db` ni a `avov_test` en esta auditoría.

**Veredicto auditoría:** `APROBADO CON LIMITACIONES`
- Probado: rechazo fail-closed por nombre de schema; mensaje sin credenciales/URL; guardia en `pytest_configure` antes de imports de test; sin excepción de módulo.
- Limitación restante (no bloqueante para S-20.26 de diseño): tras autorizar `avov_test`, la colección puede importar `SessionLocal` y crear el `Engine` (SQLAlchemy no abre TCP hasta el primer checkout); eso solo ocurre con schema autorizado.
- Pendiente S-20.26: entorno real `avov_test` + API/FE aislados. B2-04/B2-05c E2E siguen bloqueados. S-20 permanece ABIERTA.

### S-20.26 — Preparación del entorno E2E aislado (2026-10-20)

**Veredicto:** `PREPARADO CON LIMITACIONES`. S-20 permanece **ABIERTA**. No se ejecutaron B2-04/B2-05c ni la suite destructiva.

#### Identidad MySQL
- Contenedor `avov-mysql` (imagen `mysql:8.4`), puerto host `3307→3306`. Distinto de XAMPP (`3306`) y de otros proyectos.
- Schemas presentes: `avov_db` (activo/producción local) y `avov_test` (QA).

#### Estado de `avov_test` (solo lectura)
- Existe; **no** se recreó ni se hizo `DROP`.
- Alembic: `f4b5c6d7e8f9` (alineado con el head documentado).
- Preguntas: **60**; categorías RIASEC: **6** (10 por código R/I/A/S/E/C).
- Usuario de app tiene privilegios sobre `avov_test` (verificado por `SHOW GRANTS` saneado).
- **No** se copiaron datos personales desde `avov_db`.

#### Guardia
- `pytest tests/test_db_isolation.py` con URL ficticia `…/avov_test` → **14 passed** (reconfirmado en verificación final).
- Preflight de arranque: `backend/scripts/assert_e2e_database.py` → primero validación de nombre **sin** conectar; después `SELECT DATABASE()`; solo entonces se lanza uvicorn.

#### API secundaria — evidencia de schema (verificación final, no solo health)
- Scripts: `scripts/dev-backend-e2e-isolated.ps1` / `scripts/stop-backend-e2e-isolated.ps1`.
- Proceso en `:8001`: `python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8001` (worker + padre).
- **Comprobado en el entorno del proceso** (sin imprimir URL/credenciales): `schema=avov_test`, host `127.0.0.1`, puerto `3307`, `redis_db=1`.
- **Comprobado en MySQL processlist** tras health: conexión desde host Docker gateway (`172.21.0.1`) con `db=avov_test`; conexiones del backend Docker (`172.21.0.4`) siguen en `avov_db` (API `:8000`).
- Health `:8001` y `:8000` → healthy. Health **no** se usa solo como prueba de aislamiento.
- Detener solo la secundaria: `.\scripts\stop-backend-e2e-isolated.ps1`.

#### Flutter de prueba (estado S-20.26; actualizado en S-20.27)
- Script: `scripts/dev-frontend-e2e-isolated.ps1`. Ver arranque y evidencia en **S-20.27**.

#### Limitaciones residuales (S-20.26)
- Qdrant compartido; JWT compartido (mitigación de IDs altos en S-20.27).
- B2-04/B2-05c E2E **pendientes**.

### S-20.27 — Identidad STUDENT QA y E2E acotado (2026-10-20)

**Veredicto:** `PREPARADO CON LIMITACIONES`. S-20 permanece **ABIERTA**.

#### Dependencias compartidas (inspección)
| Dependencia | Efecto de login/refresh/logout | Aislamiento E2E |
|-------------|-------------------------------|-----------------|
| MySQL | Refresh tokens + `last_login_at` | Escrituras vía `:8001` → solo `avov_test` (comprobado) |
| Redis | Rate-limit `avov:login-fail:*` | API `:8001` usa Redis **DB index 1**; `:8000`/Docker usa 0 |
| JWT | Access token con `sub=user_id` | Misma `JWT_SECRET`; mitigación: IDs QA ≥ **900000** (ausentes en `avov_db`) → `:8000` responde 401 |
| Qdrant | No usado en auth ni navegación inicial de login | Compartido; sin escrituras en esta fase |

#### Cuenta QA
- Script: `backend/scripts/create_e2e_student_qa.py` (exige schema `avov_test`).
- `qa_tag=E2E-STUDENT-QA`, `user_id=900000`, `student_id=900000`, rol `STUDENT`.
- Credenciales solo en `%LOCALAPPDATA%\AVOV\e2e\qa-student.json` (fuera del repo; no documentadas aquí).
- Institución sintética id `900000` en `avov_test`. Sin datos personales reales. Sin copia desde `avov_db`.

#### Flutter `:3001`
- Arrancado con `.\scripts\dev-frontend-e2e-isolated.ps1`.
- HTTP 200; cmdline incluye `--dart-define=API_BASE_URL=http://127.0.0.1:8001/api/v1`.
- Bundle DDC `packages/avov_frontend/config/app_config.dart.lib.js`: `envApiBaseUrl = "http://127.0.0.1:8001/api/v1"` (**comprobado**).
- `:3000` intacta (HTTP 200). Sesión QA del navegador principal **no** reutilizada.
- Limitación: el navegador de automatización Cursor mostró canvas negro; no se observa UI Flutter completa ahí. Chrome lanzado por `flutter run` es el destino UI previsto.

#### Escenarios ejecutados (S-20.27)

| # | Escenario | Resultado | Evidencia |
|---|-----------|-----------|-----------|
| 1 | Flutter `:3001` responde | **OK** | HTTP 200, title `avov_frontend` |
| 2 | Cliente apunta a `:8001` | **OK** | dart-define en proceso + `envApiBaseUrl` en JS |
| 3 | Login STUDENT QA vía API `:8001` | **OK** | HTTP 200, tokens emitidos (no volcados) |
| 4 | `/auth/me` rol/id | **OK** | role=STUDENT, id=900000 |
| 5 | `/students/me` en aislamiento | **OK** | HTTP 200; sesiones `avov_test`=0 (sin crear evaluaciones) |
| 6 | Token E2E en `:8000` | **OK (rechazo)** | `/auth/me` → 401 |
| 7 | Logout + refresh | **OK** | logout 200; refresh posterior 401 |
| 8 | Login UI en Flutter | **NO OBSERVADO** | Limitación de automatización / canvas |
| 9 | Crear evaluaciones / respuestas | **NO EJECUTADO** (fuera de alcance) |
| 10 | B2-04 / B2-05c | **PENDIENTE** | Ver procedimiento abajo |

#### Preservación
- `avov_db`: 1 estudiante, **2** sesiones de test (sin cambio).
- API `:8000`, Flutter `:3000` → HTTP 200 tras las pruebas.

#### Procedimiento propuesto B2-04 / B2-05c
Implementado y parcialmente ejecutado en **S-20.28** (ver abajo). Script: `backend/scripts/ensure_e2e_two_open_sessions.py`.

### S-20.28 — Múltiples sesiones abiertas en entorno aislado (2026-10-20)

**Veredicto:** `APROBADO CON LIMITACIONES`. S-20 permanece **ABIERTA**.

#### Preflight
- Rama `docs/windows-continuity` @ `8c30f5a…`. API `:8001` relanzada; preflight `assert_e2e_database.py` → `schema=avov_test`; processlist host → `avov_test`.
- Cuenta QA `user_id=900000` rol `STUDENT` ACTIVE; `student_id=900000`.
- Estado inicial abierto QA: **0** sesiones. `avov_db.test_sessions` = **2** (sin cambio al final).

#### Login visual Flutter `:3001`
- Instancia relanzada (`dev-frontend-e2e-isolated.ps1` + `--remote-allow-origins=*` para CDP).
- Bundle confirma `envApiBaseUrl=http://127.0.0.1:8001/api/v1`.
- **No observado:** montaje de `flt-glass-pane`/canvas vía CDP ni formulario usable por computer-use (página blanca / scripts DDC cargados sin canvas detectable). Clasificación: **LIMITACIÓN_DE_AUTOMATIZACIÓN**, no defecto de producto demostrado.
- Identidad efectiva comprobada por API `:8001` (login + `/auth/me` → STUDENT id 900000). No se tocó la sesión Flutter `:3000` (`#/student/dashboard` en otro Chrome).

#### Sesiones abiertas QA (`avov_test`)
| Momento | IDs abiertos | status |
|---------|--------------|--------|
| Inicial | — | 0 |
| Tras `ensure_e2e_two_open_sessions.py` | **137, 138** | STARTED |
| Tras `POST /tests/start` | **137, 138** | STARTED (sin tercera) |

#### API `POST /api/v1/tests/start` (`:8001`)
- HTTP **422**
- Mensaje funcional: indica más de una evaluación en progreso y que no se inicia otra ni se elige automáticamente.
- `GET /tests` → 2 ítems abiertos ids 138, 137.
- `avov_db` sesiones = 2 (intactas).

#### UI Flutter (observación E2E)
- **No observada** en navegador (mismo bloqueo de canvas).
- Cobertura automatizada de UI: `flutter test test/student_open_sessions_test.dart` → **8 passed** (lista dos abiertas, no llama `start`, continúa por id, 422 refresca historial).

#### Tests ejecutados
- Widget: `student_open_sessions_test.dart` → 8 passed.
- API real aislada: login + start 422 + list (arriba).
- No suite backend completa; no cleanup Redis/Qdrant; no respuestas ni finish.

#### Pendientes S-20
- Login visual y selección explícita de sesión en Chrome `:3001` (observación humana o automatización fiable).
- B2-04 seed/flujo adicional si aplica más allá de las dos sesiones ya creadas.
- No cerrar S-20; no S-21.

### S-20.29 — Selección visual de sesión abierta (2026-10-20)

**Veredicto:** `BLOQUEADO`. S-20 permanece **ABIERTA**.

- Objetivo: observar en Flutter `:3001` el dashboard / lista de sesiones abiertas (137/138) y verificar «Continuar» sobre una sesión concreta.
- **No observado:** dashboard del estudiante ni lista de sesiones abiertas en el flujo visual esperado.
- **No verificado:** acción Continuar / selección explícita de sesión en UI.
- Evidencia previa que **no** sustituye esta observación visual:
  - API aislada `:8001`: dos abiertas 137/138; `POST /tests/start` → 422.
  - `flutter test test/student_open_sessions_test.dart` → **8 passed** (widgets con mocks).
- Causa inmediata documentada en S-20.30–S-20.31: desalineación Chrome ↔ puerto Flutter E2E; login visual no aprobado.
- Sin escritura en `avov_db`; sin alterar sesiones 137/138; sin finalizar evaluaciones.

### S-20.30 — Causa raíz de observación Chrome / Flutter E2E (2026-10-20)

**Veredicto:** `DIAGNÓSTICO CON LIMITACIONES`. S-20 permanece **ABIERTA**.

- Se identificó **desalineación** entre:
  - una ventana Chrome **huérfana** (proceso cuyo padre de `flutter run` ya no existía) que aún mostraba URL en `:3001`, y
  - el Chrome **hijo** del `flutter run` E2E actual (ligado al proceso que sirve `:3001`).
- Inferir la relación ventana↔proceso solo por contenido visual o por la presencia de una URL **no** es fiable; hace falta parent/child de proceso + CDP.
- **Hipótesis secundaria (no confirmada como causa única):** inestabilidad DDC/DWDS (timeouts `RemoteDebuggerExecutionContext`, errores WIP, reloads DDC repetidos en el log del Flutter E2E). Pendiente de confirmación; **no** se autorizó reinicio ni cambio de scripts en esa fase.
- Sin modificación de código de producto ni de datos QA en esta fase.

### S-20.31 — Alineación Chrome con Flutter E2E (2026-10-20)

**Veredicto:** `BLOQUEADO` (pendiente intervención manual del operador). S-20 permanece **ABIERTA**.

| Evidencia de proceso | Hallazgo |
|---------------------|----------|
| Flutter E2E | Proceso que escucha `:3001` (dartvm hijo del `flutter run` E2E) |
| Chrome hijo de ese Flutter | CDP con `remote-allow-origins`; página observada en **`http://127.0.0.1:3000/#/login`** (puerto equivocado) |
| Chrome con URL `:3001` | Pestaña/proceso **huérfano** (padre muerto); no ligado al `flutter run` E2E actual |
| Flutter / Chrome principal | `:3000` con sesión STUDENT de trabajo — **no tocar** |

- Servicios `:3000` / `:3001` / `:8000` / `:8001` respondían health HTTP 200 en la comprobación (sin reinicios).
- **Comprobación visual de la app E2E en `http://127.0.0.1:3001/`:** no completada; bloqueada hasta que el operador active la ventana Chrome hija del E2E y navegue explícitamente a `http://127.0.0.1:3001/` (no `:3000`, no la pestaña huérfana).
- Si tras esa navegación la UI queda en blanco y el log DDC vuelve a errar: registrar y detener; corrección DDC requiere autorización aparte.
- Sin stage/commit/push; sin alterar 137/138 ni la sesión principal.

### S-20.23 — Auditoría de mecanismos seguros de preparación QA (2026-10-20)

Inspección de solo lectura. API/Flutter health 200. Sin SQL de escritura, sin crear/finalizar sesiones en `avov_db`, sin leer `.env`.

| Conclusión | Clasificación |
|------------|---------------|
| No existe `AVOV_QA_ACCESS_TOKEN` ni variable equivalente en `.env.example` ni en scripts del repo | **Confirmada** |
| Backend pytest usa fixtures que crean/borran datos vía API/repos sobre la BD apuntada por `DATABASE_URL` (documentado: `avov_test`, no `avov_db`) | **Confirmada** |
| Aislamiento pytest: cleanup explícito en fixtures (`delete`), **no** transacciones que revierten automáticamente | **Confirmada** |
| `POST /api/v1/tests/start` (rol STUDENT): 0 abiertas → crea; 1 abierta → reutiliza; >1 → 422 sin elegir | **Confirmada** |
| B2-05c (dos abiertas) en tests: se fabrican con `VocationalTestSessionRepository.create_session` (acceso a BD de test), no con la API pública | **Confirmada** |
| Vía API segura para abrir una 2.ª sesión en la cuenta QA de `avov_db` sin SQL ni tocar la sesión actual | **Bloqueada** (no existe) |
| Cubrir B2-04/B2-05c en E2E Chrome sobre `avov_db` con la sesión QA actual | **Bloqueada** sin mecanismo nuevo o segunda cuenta/BD aislada |
| Cubrir B2-05c a nivel backend contra `avov_test` (pytest ya existente) | **Confirmada** como cobertura `APROBADO_TEST`; **no** sustituye E2E |

Cambio mínimo propuesto (no implementado): entorno/documento QA con `DATABASE_URL`→`avov_test` (o BD efímera), cuenta STUDENT de fixture, y script/fixture documentado que cree dos sesiones abiertas solo en esa BD; opcionalmente variable de token de prueba solo para tooling local, nunca en producción. Alternativa E2E: segunda cuenta STUDENT dedicada en `avov_db` autorizada explícitamente, sin alterar la sesión/historial de la cuenta QA actual.

### B2-07 — Diálogo de respuesta sin guardar

- **Estado E2E:** Parcial (Cancelar observado en campaña previa).
- **Estado tests:** `APROBADO_TEST` para Cancelar, Descartar y Guardar desde el diálogo (`vocational_unsaved_answers_test.dart`, 2026-10-20).
- Recarga completa de página: **no** verificada en E2E ni marcada como aprobada.

### B2-08 y B2-09 — Finalización e historial / resultados

- **Estado E2E:** No verificado / bloqueado sobre la sesión QA actual (no desechable sin decisión).
- **Estado tests:** `APROBADO_TEST` de sincronización de historial tras finish con mocks (`vocational_finish_history_sync_test.dart`).

### B2-10 — Recomendaciones y casos límite

- **Estado E2E UI:** mensaje «no disponibles» observado antes.
- **Estado tests:** `APROBADO_TEST` backend — router de recomendaciones no registrado (`test_recommendations_not_registered.py`, 2 passed).
- Escenario E2E completo / límites: **no** declarado aprobado.

### B2-01 y B2-02 — Renovación JWT y logout/refresh

- **Estado E2E:** No verificado.
- **Estado tests:** `APROBADO_TEST` parcial vía `auth_refresh_test.dart` / `session_logout_test.dart` (mocks); **no** E2E con expiry real.

## 3. Estado actual de la sesión QA

Última observación (campaña 2026-10-20, inspección visual + intento sintético fallido de «Siguiente»):

| Indicador | Valor informado |
|-----------|-----------------|
| Pregunta | 1 de 60 |
| Categoría | Realista (R) |
| Selección | Opción 4 |
| Mensaje | «Respuesta confirmada por el servidor» |
| Contador | 3/60 |
| Evaluación QA | No finalizada |
| Sesión | No cerrada |
| Evaluación histórica 60/60 (19/10/2026 21:33) | Intacta (no finalizada ni borrada en esta campaña) |

## 4. Pendientes y bloqueos

| Caso | Estado | Evidencia disponible | Pendiente o bloqueo | Próximo paso seguro |
|------|--------|----------------------|---------------------|---------------------|
| Bloque 1 | Aprobado (UI) | Observación manual previa | Limitación de clic sintético | Mantener |
| B2-01 | No verificado E2E / Aprobado (TEST) parcial | `auth_refresh_test` | Expiry JWT real | Aplazar |
| B2-02 | No verificado E2E / Aprobado (TEST) parcial | logout tests | Cerrar sesión en QA | Solo con autorización |
| B2-03 | Aprobado (UI) | Panel, ficha, historial | — | Mantener |
| B2-04 | Bloqueado | S-20.23: sin token/`AVOV_QA` en repo | Seed E2E en `avov_db` | Usar `avov_test`+fixtures o 2.ª cuenta (no impl.) |
| B2-05a | Aprobado (UI) | Inventario cero abiertas | — | Mantener |
| B2-05b | Parcial | Una abierta + Continuar UI | ID de sesión no capturado | Opcional, sin secretos |
| B2-05c | No verificado E2E / Aprobado (TEST) API+widget | API 422 + open-sessions 8 passed (S-20.28); UI no (S-20.29–31) | Chrome E2E mal alineado con `:3001` | Operador: Chrome hijo → `127.0.0.1:3001` |
| S-20.29 | Bloqueado | Dashboard/lista no visibles; Continuar no verificado | Depende de alineación Chrome | S-20.31 + observación humana |
| S-20.30 | Diagnóstico | Huérfano vs Chrome hijo; DDC hipótesis | DDC no confirmado | Documentar; no reiniciar sin auth |
| S-20.31 | Bloqueado | Chrome hijo en `:3000`; tab `:3001` huérfana | Intervención manual | Abrir `http://127.0.0.1:3001/` en Chrome E2E |
| B2-06 | Parcial | Contador 0→1→2/60; UI | HTTP no capturado | Guardar más solo con autorización |
| B2-07 | Parcial E2E / Aprobado (TEST) | Widget tests diálogo | Recarga E2E | Mantener |
| B2-08 | No verificado E2E / Aprobado (TEST) sync | finish+history mocks | No finalizar QA actual | Sesión desechable o autorización |
| B2-09 | No verificado E2E | Depende de B2-08 | — | Aplazar |
| B2-10 | Parcial UI / Aprobado (TEST) BE | «no disponibles» + pytest | E2E completo | Aplazar |
| S-20.10 | Aprobado (UI) | P1→P2 físico; 2/60 | HTTP no | Cerrado (limitación automatización) |
| S-20.12 | Inconcluso | P4 / 3/60 | — | Cerrado por S-20.13 |
| S-20.13 | Aprobado (UI) P2 | Opción 4; 3/60 | HTTP no | Mantener |
| S-20.18 | Aprobado (UI) P1 | Opción 4; 3/60 | HTTP no | Mantener |
| S-20.20 | Inconcluso | Post-clic sigue P1 | Causa no aislada | Protocolo evidencia dual |
| S-20.21 | Análisis estático | Código + tests | Sin defecto demostrado | Mantener |
| Nav automática P1→P2 | Inconcluso / limitación | Clic sintético 2026-10-20 falló | Hit-target Flutter Web | No más clics ciegos |

## 5. Restricciones de ejecución

Hasta el registro de esta evidencia (creación y actualizaciones append-only de este archivo):

- No se realizaron cambios de código funcional de producto en la campaña de automatización 2026-10-20 (sin defecto reproducible de navegación).
- No se ejecutó SQL de escritura.
- No se finalizó la evaluación QA abierta ni la histórica 60/60.
- No se reiniciaron servicios sanos.
- No se realizaron commit, push ni merge.

La fase **S-20 permanece abierta**. No se inicia S-21 en este documento.

### Veredicto documental

**`S-20 ABIERTA`**. Criterios de cierre no cumplidos: login/selección visual E2E en `:3001` (S-20.29–31 bloqueados por desalineación Chrome), más E2E reales en B2-01/02/05c UI/06(HTTP)/08/09, seed B2-04 sobre cuenta principal si aplica, navegación «Siguiente» E2E fiable, y decisión sobre sesión desechable para finalización. Los 8 widget tests de sesiones abiertas y la API 422 **no** cierran el E2E visual.
