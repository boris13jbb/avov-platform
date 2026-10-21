# Próximos pasos verificados

No se continúa una fase funcional hasta que el entorno de este Windows quede comprobado y el usuario lo autorice.

## Bloqueos de entorno

1. El MySQL de AVOV queda publicado en el puerto 3307. El 3306 sigue siendo XAMPP y no debe usarse para las pruebas de AVOV.
2. Ya existe un `.env` local. No pegar la API key de DeepSeek en el chat. Su `DATABASE_URL` usa el host interno `mysql` y el puerto `3306`; desde Windows no debe reescribirse a `localhost:3306`.
3. `pytest` no debe lanzarse contra el MySQL de XAMPP: los fixtures crean y borran instituciones y usuarios. Sin `DATABASE_URL`, el valor predeterminado apunta a `127.0.0.1:3307`.

## Después de desbloquear la base

1. Copiar `.env.example` a `.env` y revisar secretos locales.
2. Instalar dependencias del backend y del frontend.
3. Ejecutar `flutter analyze` y `flutter test`.
4. El stack AVOV ya está en marcha. MySQL en `127.0.0.1:3307`, Redis propio en `127.0.0.1:6380`, XAMPP en 3306 y `sc-pne-redis` en 6379.
5. Las pruebas de backend ya pasaron contra `avov_test`. No volver a lanzarlas contra `avov_db`.
6. Desde S-20.25 / S-20.25-A, pytest aborta en `pytest_configure` (antes de importar tests) si la base efectiva no es `avov_test` (`tests/db_isolation.py`). Toda invocación de pytest —incluida `tests/test_db_isolation.py`— necesita `DATABASE_URL` con schema `avov_test` (puede ser URL ficticia; la guardia no conecta). No lanzar pytest con schema `avov_db`.
7. Abrir `http://localhost:8000/api/v1/health` y `flutter run -d chrome`.
8. Entorno E2E aislado (S-20.26–S-20.27):
   - `avov_test`: Alembic `f4b5c6d7e8f9`, 60 preguntas; cuenta QA `E2E-STUDENT-QA` (user/student id ≥ 900000). Credenciales solo en `%LOCALAPPDATA%\AVOV\e2e\` (no en git).
   - Crear/reutilizar cuenta: `DATABASE_URL`→`avov_test` + `backend/scripts/create_e2e_student_qa.py`.
   - API `:8001` / Flutter `:3001` (`.\scripts\dev-frontend-e2e-isolated.ps1`). Auth API acotada comprobada; login UI Flutter aún no observado por automatización.
   - Detener API aislada: `.\scripts\stop-backend-e2e-isolated.ps1`. Flutter `:3001`: `q` en la terminal de `flutter run` (no cerrar `:3000`).
   - S-20.28: dos sesiones abiertas QA en `avov_test` (ids 137/138); `POST /tests/start` → 422; widget tests open-sessions 8 passed (no sustituyen UI). Credenciales solo en `%LOCALAPPDATA%\AVOV\e2e\`.
   - S-20.29–S-20.31: selección visual **bloqueada** en esa fecha; superada en S-20.49–S-20.51 con Chrome hijo del `dartvm` `:3001`.
   - **S-20 CERRADA** (2026-10-21): S-20.50/51 reanudación 138/137; S-20.52 aislamiento `POST /tests/138/answers` HTTP 200 + limpieza `id=3794`; S-20.53 fix hash `optionURLReflectsImperativeAPIs` + 2 tests. Evidencia en `docs/s-20-e2e-estudiante.md`. **No iniciar S-21** hasta completar el post-cierre abajo.

## Post-cierre S-20 (siguiente trabajo del expediente)

Orden efectivo (no saltar; no inventar estados):

1. **Verificación E2E del hash** — **HECHO** (S-20.54): tras recarga solo `:3001`, Continuar 138 → `#/student/test/138` + `GET /tests/138/questions` 200; 137/138 con 0 respuestas.
2. **B2-08 finalización** — **HECHO** (sesión desechable **139**): 60 answers + `POST /tests/139/finish` HTTP 200; RIASEC id=64 (R/I); 137/138 intactas (0 answers).
3. **B2-09 historial/resultado E2E** — **HECHO**: `#/student/results` muestra Completada; `#/student/test/139/result` con Perfil RIA; sin mezclar 137/138.
4. **B2-01 / B2-02** (aplazables): expiry JWT real y logout E2E.
5. **B2-10** recomendaciones: parcial; router BE no registrado (TEST).
6. Limpieza opcional de 139 (answers 3795–3854, riasec 64, sesión): **solo con autorización** de borrado; conservar evidencia hasta entonces.
7. Evaluar inicio de **S-21** según el plan vigente (S-20 ya cerrada) — ver sección siguiente.

Integración Git (2026-10-21): commit `95b6279` en `docs/windows-continuity`; push a `origin`; PR [#1](https://github.com/boris13jbb/avov-platform/pull/1) actualizado hacia `main`. El repositorio **no** define workflows en `.github/`; CI de GitHub Actions no reportó checks en esa rama.

## Evaluación de entrada a S-21 (2026-10-21)

S-20 cerrada **no basta** por sí sola para abrir S-21. Condiciones observadas:

| Ítem | ¿Obligatorio para salir de B2 / entrar a S-21? | Estado |
|------|-----------------------------------------------|--------|
| S-20 cierre + aislamiento + hash | Sí (cumplido) | Hecho |
| B2-08 / B2-09 E2E finish + resultado | Sí para validar ciclo vocacional estudiante | Hecho (sesión 139) |
| B2-05c / B2-06 | Sí para varias abiertas y guardado | Hecho |
| B2-07 diálogo dirty | No bloqueante si queda documentado parcial + TEST | Parcial — aplazable |
| B2-01 / B2-02 JWT/logout E2E | No bloqueantes si quedan aplazados con cobertura TEST | Aplazados |
| B2-10 recomendaciones E2E | No es salida de B2: es **producto pendiente** (Fase 14 / pantalla 40) | **E2E aislado hecho** (sesión 156); ver `docs/fase-14-recomendaciones.md` |

**Conclusión:** S-21 implementada y validada en E2E aislado (`:3001`/`:8001`/`avov_test`). Cierre formal en `main` pendiente de merge autorizado de PR #1 y luego PR #2. Evidencia detallada en `docs/fase-14-recomendaciones.md`.

### Alcance S-21 (autorizado e implementado)

1. **Recomendaciones de carreras (Fase 14):** router registrado, servicio híbrido RIASEC+Qdrant con fallback MySQL, contratos, pruebas `avov_test`, UI en resultado vocacional.
2. Siguiente producto sugerido: **PDF de resultados (Fase 15)**.

Dependencias de integración: fusionar PR [#1](https://github.com/boris13jbb/avov-platform/pull/1) antes que PR [#2](https://github.com/boris13jbb/avov-platform/pull/2); conservar 137/138/139. No hay workflows CI en el repo.

**Estado Git (2026-10-21):** rama `feature/s21-career-recommendations` @ `95f4796` + correcciones locales pendientes de commit (filtro hits Qdrant obsoletos, tests Flutter, docs E2E). Sin merge ni despliegue en esta pasada.

## Trabajo de producto, aún no validado en ejecución

- Reconciliar `docs/plan-desarrollo.md` con el código real (el plan histórico de fases 5–32 está desfasado respecto al avance en `docs/windows-continuity`).
- Tras cierre formal S-21: iniciar **Fase 15 (PDF)** con autorización explícita.
- La arquitectura de referencia sigue siendo `docs/arquitectura.md`.
