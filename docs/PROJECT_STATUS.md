# Estado del proyecto AVOV

Fecha de comprobación en este equipo: 2026-10-15.

Este documento distingue lo que se comprobó en el clon de lo que la documentación anterior afirma y todavía no se ejecutó aquí.

## Repositorio

| Dato | Valor comprobado |
|------|------------------|
| Remoto | `https://github.com/boris13jbb/avov-platform.git` |
| Clon | `C:\Users\BRS\source\avov-platform` |
| Rama publicada | `main` en `4226c49` (`chore: update .gitignore to include local cache for Android SDK`) |
| Working tree al clonar | Limpio, alineado con `origin/main` |
| Historial visible | 3 commits: `0503d64`, `5f75476`, `4226c49` |

## Qué hay en el código

Comprobado por inspección de archivos, sin ejecutar la aplicación:

- Monorepo con `backend/` (FastAPI), `frontend/` (Flutter), `database/`, `docker-compose.yml`, `nginx/`, `qdrant/` y `docs/`.
- Backend: rutas en `backend/app/api/routes/` para health, auth, institutions, users, students, careers, questions, tests, vector, recommendations, reports, assistant, audit, dashboard y status.
- Migraciones Alembic: esquema inicial y seeds de categorías RIASEC, super admin y preguntas.
- Pruebas pytest presentes en `backend/tests/`. No se ejecutaron en esta preparación porque el MySQL de XAMPP ya escucha en el puerto 3306.
- Frontend: pantallas localizadas de splash, home y login. No se encontró el resto de módulos de interfaz descritos en el plan de 32 fases.
- `docs/plan-desarrollo.md` dice que las fases 0 a 4 están completadas y que las fases 5 a 32 están pendientes, y a la vez indica como siguiente paso la fase 1. Esa tabla no coincide con la presencia de rutas y pruebas posteriores a la fase 4. No se marca ninguna fase como validada en este equipo.

## Entorno de este Windows

| Herramienta | Comprobado |
|-------------|------------|
| Windows 11 Pro 10.0.26200 | Sí |
| Git 2.54.0.windows.1 | Sí |
| GitHub CLI 2.95.0, sesión `boris13jbb` | Sí |
| Python 3.13.14 | Sí; el README pide 3.12+ |
| Flutter 3.44.2 / Dart 3.12.2 | Sí; `pubspec.yaml` pide Dart `>=3.5.0 <4.0.0` |
| Docker 29.5.3, motor en marcha | Sí |
| Node.js 24 / npm | Instalados; el proyecto no los usa |
| MySQL | `c:\xampp\mysql\bin\mysqld.exe` escucha en 3306 |
| Redis 6379 | Contenedor ajeno `sc-pne-redis`. No se comparte |
| Redis AVOV | Publicado en 6380, interno 6379. `redis-cli ping` respondió PONG y el health de la API marcó Redis en true |
| Qdrant 6333, API 8000, phpMyAdmin 8081 | Puertos libres en la comprobación |

## Comprobado al preparar este equipo

- Dependencias Python de `backend/requirements.txt` instaladas en `backend/.venv`. `import fastapi` devuelve 0.115.6.
- `flutter pub get` terminó correctamente. No se actualizaron dependencias fuera de las restricciones del `pubspec.yaml`.
- `flutter analyze`: 8 errores. Falta `frontend/lib/core/storage/secure_token_storage.dart`, importado por `auth_interceptor.dart` y `auth_guard.dart`.
- `flutter test`: pasaron 3 pruebas de `validators_test.dart`. `widget_test.dart` no compiló por el mismo archivo ausente.
- `scripts/verify-structure.ps1` falla porque falta el directorio `frontend/lib/core/storage`.
- `pytest` y `docker compose up` no se ejecutaron: XAMPP ocupa el puerto 3306.

## Pendiente

- El 15 de octubre de 2026, por la noche, `docker compose up --build -d` creó los volúmenes nuevos `avov_mysql_data`, `avov_redis_data` y `avov_qdrant_data` y dejó los cinco servicios en marcha. No se borró ningún volumen.
- Health `http://127.0.0.1:8000/api/v1/health`: HTTP 200, estado `healthy`, con MySQL, Redis y Qdrant en true.
- phpMyAdmin `http://127.0.0.1:8081/`: HTTP 200. No se inició sesión.
- `pytest` de integración no se ejecutó: esas pruebas crean y borran instituciones, usuarios y estudiantes. Sí pasaron 14 pruebas que no escriben en MySQL.
- Alembic está en `f4b5c6d7e8f9` sobre `avov_db` en `127.0.0.1:3307`: 6 categorías RIASEC, 60 preguntas y 1 usuario. El respaldo previo está fuera del repositorio, en `C:\Users\BRS\Documents\avov-backups\avov_db-pre-alembic.sql`.
- Las 108 pruebas de backend pasaron contra la base aislada `avov_test` en el mismo puerto. `avov_db` conservó 1 usuario, 0 instituciones y 60 preguntas.
- Un hash de contraseña con formato desconocido ya no se propaga como error no controlado. `verify_password` lo rechaza, registra un aviso sin el hash ni la contraseña y el login responde 401 con el mensaje genérico de credenciales. La suite posterior pasó 115 pruebas contra `avov_test`.
- El respaldo posterior a las migraciones está en `C:\Users\BRS\Documents\avov-backups\avov_db-post-alembic.sql`. El respaldo previo no se reemplazó.
- API key real de DeepSeek. El ejemplo solo trae un marcador.
