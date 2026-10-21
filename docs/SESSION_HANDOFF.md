# Entrega de sesión — preparación Windows

Fecha: 2026-10-15. Equipo: Windows 11 Pro, usuario `BRS`.

## Hecho

- Diagnóstico de herramientas sin reinstalar las que ya respondían.
- Acceso HTTPS al repositorio como `boris13jbb` mediante GitHub CLI. No se mostró el token.
- Clon nuevo en `C:\Users\BRS\source\avov-platform`. `C:\Users\BRS\Documents\AVOV` estaba vacía y no se usó como destino.
- `main` en `4226c49`, working tree limpio respecto de `origin/main` en el momento del clon.
- Cursor se abrió con `cursor` sobre esa carpeta.
- Rama local `docs/windows-continuity` para esta documentación. No hay commit ni push.

## Comprobado después del clon

- `backend/.venv` con `requirements.txt`. FastAPI 0.115.6 importa correctamente.
- `.env` local creado desde `.env.example`. Está en `.gitignore`.
- `flutter pub get` correcto.
- `flutter analyze`: 8 errores por `frontend/lib/core/storage/secure_token_storage.dart` ausente.
- `flutter test`: 3 pruebas de validadores correctas; `widget_test.dart` no compiló.
- `verify-structure.ps1`: falta `frontend/lib/core/storage`.

## No hecho a propósito

- No se modificó código de la aplicación. El archivo de tokens que falta no se inventó en esta preparación.
- No se ejecutó `pytest` ni `docker compose up`: MySQL de XAMPP ocupa el puerto 3306.
- No se creó `docs/ARCHITECTURE.md` porque ya existe `docs/arquitectura.md`.
- No se duplicaron las reglas `avov-proyecto`, `avov-backend`, `avov-frontend` ni `avov-infraestructura`. Se añadió solo `avov-continuity.mdc`.

## Archivos nuevos, sin publicar

- `.cursor/rules/avov-continuity.mdc`
- `docs/PROJECT_STATUS.md`
- `docs/DEVELOPMENT_GUIDE.md`
- `docs/NEXT_STEPS.md`
- `docs/SESSION_HANDOFF.md`

## Para seguir en este equipo

Abrir `C:\Users\BRS\Documents\AVOV` en Cursor. No commitear hasta revisar el diff y autorizarlo.

## Arranque Docker, 2026-10-15 por la tarde

- Docker 29.5.3 y Compose v5.1.4 responden. `docker compose config` mantiene MySQL en `3307:3306` y Redis en `6379:6379`.
- `sc-pne-redis` sigue en marcha, red `proyecto_default`, puerto 6379. No se detuvo.
- XAMPP sigue en 3306 (PID 23684). Los puertos 3307, 6380, 8000, 8081 y 6333 estaban libres.
- No se inició el stack de AVOV, no se ejecutó `pytest` y no se borraron volúmenes.
- Redis de AVOV solo se usa en el health check y dentro de Docker apunta a `redis:6379`. Compartirlo con `sc-pne-redis` mezclaría la base lógica 0 de otro proyecto.

## Arranque verificado, 2026-10-15 por la noche

- Redis de AVOV publicado en `6380:6379`. El valor predeterminado de Windows es `127.0.0.1:6380`. Docker sigue en `redis://redis:6379/0`.
- `docker compose up --build -d` creó la red `avov_avov-network` y los volúmenes `avov_mysql_data`, `avov_redis_data` y `avov_qdrant_data`. No se ejecutó `down` ni se borraron volúmenes.
- Servicios: MySQL, Redis y Qdrant healthy; backend y phpMyAdmin en ejecución. Health HTTP 200 con MySQL, Redis y Qdrant en true. phpMyAdmin HTTP 200.
- XAMPP sigue en 3306. `sc-pne-redis` sigue en 6379, junto con `sc-pne-postgres`, `fortaleza-postgres` y `fortaleza-adminer`.
- Desde `backend/`, sin `.env` local, la URL efectiva es `127.0.0.1:3307/avov_db` y Redis `127.0.0.1:6380`. Pasaron 14 pruebas sin escritura. No se corrió el resto de `pytest` ni migraciones manuales.

## Migraciones, comprobación posterior

- Alembic tiene cuatro revisiones, cabeza `f4b5c6d7e8f9`. `upgrade` crea tablas e inserta semillas; los `DROP` y `DELETE` están en `downgrade`.
- No se pudo consultar el esquema ni hacer respaldo: Docker Desktop no estaba en ejecución y `127.0.0.1:3307` rechazó la conexión. No se ejecutó `alembic upgrade`.

## Migración aplicada después de recuperar Docker

- Docker volvió a responder. `avov-mysql` estaba healthy y el volumen `avov_mysql_data` se conservó.
- Antes de migrar, `avov_db` no tenía tablas. El respaldo lógico quedó en `C:\Users\BRS\Documents\avov-backups\avov_db-pre-alembic.sql`.
- `alembic upgrade head` llegó a `f4b5c6d7e8f9`. Health HTTP 200, estado `healthy`.
- Se creó `avov_test` en el mismo MySQL. `pytest` ejecutó 108 pruebas contra esa base. `avov_db` siguió con 1 usuario, 0 instituciones y 60 preguntas.

## Autenticación y respaldo posterior

- `verify_password` captura solo `UnknownHashError`. Un hash corrupto se trata como no coincidente y queda un aviso en el log, sin hash ni contraseña. El resto de excepciones sigue propagándose.
- El login con hash corrupto responde HTTP 401 y el mensaje `Credenciales incorrectas`, el mismo que una contraseña incorrecta o un usuario inexistente.
- La suite completa posterior pasó 115 pruebas con `DATABASE_URL` apuntando a `127.0.0.1:3307/avov_test`.
- Respaldo lógico de `avov_db`: `C:\Users\BRS\Documents\avov-backups\avov_db-post-alembic.sql`. La restauración de prueba usó `avov_restore_check` y se eliminó después de comparar conteos. `avov_db-pre-alembic.sql` sigue intacto.
