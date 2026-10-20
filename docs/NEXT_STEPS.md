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
   - S-20.29–S-20.31: selección visual **bloqueada**. El Chrome hijo del Flutter E2E (`:3001`) se observó en `:3000/#/login`; la pestaña `:3001` era huérfana. DDC/DWDS: hipótesis secundaria sin confirmación. **Próxima acción manual:** en la ventana Chrome del `flutter run` E2E, abrir exactamente `http://127.0.0.1:3001/` y reportar splash/login/blanco/dashboard (sin tocar `:3000` ni sesiones 137/138). No suite destructiva ni S-21; S-20 **ABIERTA**.

## Trabajo de producto, aún no validado en ejecución

- Reconciliar `docs/plan-desarrollo.md` con el código: hay rutas y pruebas de fases posteriores a la 4, y el frontend solo muestra splash, home y login.
- No implementar pantallas nuevas hasta confirmar con el usuario cuál es la fase vigente.
- La arquitectura de referencia sigue siendo `docs/arquitectura.md`. No hace falta otro documento de arquitectura.
