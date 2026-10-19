# Guía de desarrollo en Windows — AVOV

Sirve para preparar otro equipo Windows a partir del repositorio publicado. Los datos de secretos no se copian con Git.

La guía histórica `docs/instalacion-local.md` menciona rutas de otra carpeta (`Documents\aplicstibi` y `develop\flutter`). En este equipo el clon válido es `C:\Users\BRS\source\avov-platform` y Flutter responde desde `C:\Users\BRS\flutter`.

## Requisitos comprobados en el repositorio

| Herramienta | Requisito | Para qué |
|-------------|-----------|----------|
| Git | Cualquier versión reciente | Clonar y versionar |
| Python | 3.12 o superior | Backend local |
| Flutter | 3.24 o superior; Dart `>=3.5.0 <4.0.0` | Frontend |
| Docker Desktop | 4.x o superior, con el motor en marcha | MySQL, Redis, Qdrant, phpMyAdmin y API |
| Google Chrome | Instalado | `flutter run -d chrome` |

Node.js, pnpm y Yarn no forman parte de este repositorio. No hay `package.json`.

## Clonar

```powershell
git clone https://github.com/boris13jbb/avov-platform.git "$env:USERPROFILE\source\avov-platform"
Set-Location "$env:USERPROFILE\source\avov-platform"
git status
```

Si la carpeta ya existe, no la borres ni vuelvas a clonar encima. Revisa si ya es un repositorio Git.

En Cursor: File > Open Folder y elige la carpeta clonada. También vale:

```powershell
cursor "$env:USERPROFILE\source\avov-platform"
```

## Variables locales

```powershell
Copy-Item .env.example .env
```

Edita `.env` en el equipo. No lo subas a Git. Las variables y su origen están en `docs/variables-entorno.md`. `DEEPSEEK_API_KEY` se obtiene en la cuenta de DeepSeek; el resto de secretos de desarrollo se sustituye por valores propios antes de salir de la máquina local.

## Dependencias

```powershell
Set-Location backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Set-Location ..\frontend
flutter pub get
```

`scripts\install-project-deps.ps1` hace eso y además lanza `pytest`, `flutter analyze` y `flutter test`. Revisa el script antes de ejecutarlo: `pytest` escribe en la base configurada.

## Ejecutar

Stack documentado:

```powershell
docker compose up --build -d
```

URLs documentadas: API `http://localhost:8000`, docs `http://localhost:8000/docs`, health `http://localhost:8000/api/v1/health`, phpMyAdmin `http://localhost:8081`, Qdrant `http://localhost:6333`.

MySQL de AVOV, desde Windows: `127.0.0.1:3307`. Entre contenedores sigue siendo `mysql:3306`. phpMyAdmin no cambia de puerto interno; solo se abre por `8081`.

Backend solo, con servicios ya accesibles:

```powershell
Set-Location backend
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Frontend web:

```powershell
Set-Location frontend
flutter run -d chrome
```

## MySQL de XAMPP y MySQL de AVOV

XAMPP escucha en el puerto 3306 y debe seguir haciéndolo. AVOV publica su MySQL de Docker en `3307` y el contenedor continúa escuchando en `3306`. No hace falta detener XAMPP para levantar el stack.

El puerto 6379 lo usa el contenedor `sc-pne-redis`. AVOV publica su Redis en `6380` y el contenedor sigue escuchando en `6379`. Dentro de Docker la URL es `redis://redis:6379/0`. Desde Windows, si no hay `REDIS_URL`, el valor predeterminado es `127.0.0.1:6380`.

## Recuperar trabajo publicado

```powershell
git fetch origin
git status -sb
git pull
```

Eso trae solo lo que está en GitHub. No trae `.env`, entornos virtuales ni datos de bases.
