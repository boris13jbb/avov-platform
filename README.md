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

## Instalación local

### 1. Clonar y configurar entorno

```powershell
cd aplicstibi
Copy-Item .env.example .env
# Editar .env con tus valores (especialmente APP_SECRET_KEY y JWT_SECRET_KEY)
```

### 2. Levantar servicios con Docker

```powershell
docker compose up --build -d
```

O usar el script:

```powershell
.\scripts\dev-up.ps1
```

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
```

## Variables de entorno

Ver [docs/variables-entorno.md](docs/variables-entorno.md) y `.env.example`.

## Documentación

### Fases de desarrollo

- [Fase 0 — Análisis inicial](docs/fase-0-analisis.md)
- [Fase 1 — Monorepo](docs/fase-1-monorepo.md)
- [Fase 3 — Backend base](docs/fase-3-backend-base.md)
- [Fase 4 — Modelo BD](docs/fase-4-modelo-bd.md)

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
