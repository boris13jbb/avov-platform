# AVOV — Asistente Virtual de Orientación Vocacional con IA

Aplicación multiplataforma profesional para orientación vocacional basada en el modelo RIASEC, con recomendaciones inteligentes, reportes PDF y panel institucional.

## Stack tecnológico

| Capa | Tecnología |
|------|------------|
| Frontend | Flutter, Riverpod, GoRouter, Dio |
| Backend | FastAPI, SQLAlchemy, Alembic, Pydantic |
| Base de datos | MySQL 8, phpMyAdmin |
| Motor vectorial | Qdrant |
| Caché / colas | Redis |
| IA | DeepSeek API |
| Infraestructura | Docker, Docker Compose, Nginx |

## Requisitos

- Docker Desktop 4.x+
- Python 3.12+ (desarrollo local del backend)
- Flutter 3.24+ (desarrollo local del frontend)
- Git

## Estructura del proyecto

```
aplicstibi/
├── backend/                 # API FastAPI (capas: api → service → repository → model)
│   ├── app/
│   │   ├── api/routes/      # Endpoints HTTP
│   │   ├── core/            # Config, enums, excepciones, logging
│   │   ├── db/              # Sesión SQLAlchemy
│   │   ├── models/          # ORM
│   │   ├── schemas/         # Pydantic
│   │   ├── repositories/    # Acceso a datos
│   │   ├── services/        # Lógica de negocio + llm/
│   │   ├── security/        # JWT, permisos, rate limit
│   │   └── utils/           # Validadores, almacenamiento
│   ├── alembic/             # Migraciones
│   └── tests/               # pytest
├── frontend/                # App Flutter (feature-first)
│   └── lib/
│       ├── core/            # Network, theme, storage, validators
│       ├── config/          # Configuración por entorno
│       ├── features/        # Módulos por dominio
│       ├── shared/          # Widgets reutilizables
│       └── router/          # GoRouter + guards
├── database/
│   ├── init/                # Bootstrap SQL
│   └── seeds/               # Datos iniciales
├── docker/                  # Config Docker adicional
├── docs/                    # Documentación técnica
├── nginx/                   # Proxy reverso (producción)
├── qdrant/                  # Configuración Qdrant
├── scripts/                 # dev-up, verify-structure, backups
├── docker-compose.yml
├── .env.example
└── README.md
```

Verificar estructura:

```powershell
.\scripts\verify-structure.ps1
```

Validación integral (Fase 32 — 15 criterios):

```powershell
.\scripts\validate-fase32.ps1
```

Smoke E2E por API (Fase 35 — requiere Docker activo):

```powershell
.\scripts\smoke-e2e.ps1
.\scripts\smoke-e2e.ps1 -EnsureStudentSeed   # crea estudiante de prueba si falta
```

Staging producción local (Fase 36 — Nginx en puerto 8080):

```powershell
Copy-Item .env.staging.example .env.staging
.\scripts\staging-up.ps1
.\scripts\validate-staging.ps1
```

Flutter QA (Fase 37):

```powershell
.\scripts\validate-flutter-qa.ps1
```

Flujo vocacional E2E (Fase 38 — requiere Docker activo):

```powershell
.\scripts\validate-vocational-e2e.ps1
```

Validación release unificada (Fase 39):

```powershell
.\scripts\validate-release.ps1
.\scripts\validate-release.ps1 -Quick
```

Validación despliegue producción prod-local (Fase 40):

```powershell
.\scripts\preflight-prod.ps1 -EnvFile ".env.prod-local"
.\scripts\validate-prod-deploy.ps1
```

Validación SSL + post-deploy (Fase 41):

```powershell
.\scripts\validate-prod-ssl-deploy.ps1
.\scripts\post-deploy-prod.ps1 -BaseUrl "https://api.tudominio.edu.co/api/v1"
```

Checklist UI Flutter manual: [docs/fase-41-flutter-ui-manual.md](docs/fase-41-flutter-ui-manual.md)

Validación release servidor + Flutter Web (Fase 42):

```powershell
.\scripts\validate-server-release.ps1
.\scripts\build-flutter-web.ps1 -EnvFile ".env.production.server.example"
```

Servidor Linux: [docs/fase-42-servidor-release.md](docs/fase-42-servidor-release.md)

Validación operaciones VPS (Fase 43):

```powershell
.\scripts\validate-vps-readiness.ps1
.\scripts\monitor-health.ps1 -BaseUrl "http://localhost:8000/api/v1"
```

VPS Linux: [docs/fase-43-vps-operaciones.md](docs/fase-43-vps-operaciones.md)

Validación despliegue institucional (Fase 44):

```powershell
.\scripts\prod-institutional-local-up.ps1
.\scripts\validate-institutional-deploy.ps1 -SkipTlsVerify
```

Documentación: [docs/fase-44-despliegue-institucional.md](docs/fase-44-despliegue-institucional.md)

Validación soporte y rollback (Fase 45):

```powershell
.\scripts\validate-production-ops.ps1
```

Documentación: [docs/fase-45-soporte-rollback-capacitacion.md](docs/fase-45-soporte-rollback-capacitacion.md)

## Instalación local

### 1. Clonar y configurar entorno

```powershell
cd aplicstibi
Copy-Item .env.example .env
# Editar .env con tus valores (especialmente APP_SECRET_KEY y JWT_SECRET_KEY)
```

### 2. Levantar servicios con Docker (desarrollo)

```powershell
docker compose up --build -d
```

O usar el script:

```powershell
.\scripts\dev-up.ps1
```

### Producción

```powershell
Copy-Item .env.production.example .env
# Editar claves y dominios
.\scripts\preflight-prod.ps1 -EnvFile ".env"
.\scripts\prod-up.ps1
```

Simulación prod local aislada (puerto 8090, no modifica `.env` dev):

```powershell
Copy-Item .env.prod-local.example .env.prod-local
.\scripts\prod-local-up.ps1
.\scripts\validate-prod-deploy.ps1
```

Ver [docs/manual-produccion.md](docs/manual-produccion.md) y [docker/README.md](docker/README.md).

### 3. Verificar servicios

| Servicio | URL |
|----------|-----|
| API | http://localhost:8000 |
| Documentación API | http://localhost:8000/docs |
| Health check | http://localhost:8000/api/v1/health |
| phpMyAdmin | http://localhost:8081 |
| Qdrant | http://localhost:6333 |

## Desarrollo del backend (sin Docker)

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Desarrollo del frontend

```powershell
cd frontend
flutter pub get
flutter run -d chrome
```

## Comandos de prueba

```powershell
# Backend
cd backend
python -m pytest

# Frontend
cd frontend
flutter analyze
flutter test

# Docker completo
docker compose up --build
docker compose exec -T backend pytest -q

# Validacion integral Fase 32
.\scripts\validate-fase32.ps1

# Smoke E2E API (Fase 35, Docker activo)
.\scripts\smoke-e2e.ps1
```

## Variables de entorno

Ver [docs/variables-entorno.md](docs/variables-entorno.md) y `.env.example`.

## Documentación

### Fases de desarrollo

- [Fase 0 — Análisis inicial](docs/fase-0-analisis.md)
- [Fase 1 — Monorepo](docs/fase-1-monorepo.md)
- [Fase 3 — Backend base](docs/fase-3-backend-base.md)
- [Fase 4 — Modelo BD](docs/fase-4-modelo-bd.md)
- [Fase 29 — Admin CRUD y settings](docs/fase-29-admin-crud-settings.md)
- [Fase 30 — Documentación operativa](docs/fase-30-documentacion.md)
- [Fase 31 — Producción](docs/fase-31-produccion.md)
- [Fase 32 — Checklist final](docs/fase-32-checklist-final.md)

### Documentación técnica
- [Arquitectura](docs/arquitectura.md)
- [Estructura del proyecto](docs/estructura-proyecto.md)
- [Modelo de base de datos](docs/modelo-base-datos.md)
- [API Endpoints](docs/api-endpoints.md)
- [Pantallas Flutter](docs/pantallas-flutter.md)
- [Flujos del sistema](docs/flujos.md)
- [Plan de desarrollo (32 fases)](docs/plan-desarrollo.md)
- [Criterios validación Fase 0](docs/criterios-validacion-fase0.md)

### Operación y despliegue

- [Instalación local](docs/instalacion-local.md)
- [Variables de entorno](docs/variables-entorno.md)
- [Manual de usuario](docs/manual-usuario.md)
- [Manual administrador](docs/manual-administrador.md)
- [Manual de producción](docs/manual-produccion.md)
- [Checklist QA](docs/checklist-qa.md)

## Licencia

Proyecto académico / institucional — AVOV.
