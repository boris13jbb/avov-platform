# Estructura del proyecto — AVOV

**Fase:** 1 — Monorepo completado  
**Workspace:** `aplicstibi/`

---

## Monorepo raíz

```
aplicstibi/
├── backend/                 # API FastAPI
├── frontend/                # App Flutter
├── database/
│   ├── init/                # Scripts SQL bootstrap (Docker)
│   └── seeds/               # Seeds: RIASEC, preguntas, carreras ejemplo
├── docker/                  # Configuraciones Docker adicionales
├── docs/                    # Documentación técnica
├── nginx/                   # Proxy reverso (producción)
├── qdrant/                  # Configuración Qdrant
├── scripts/                 # Scripts de utilidad
│   ├── dev-up.ps1
│   ├── dev-down.ps1
│   ├── backup-mysql.sh      # Fase 31
│   └── backup-qdrant.sh     # Fase 31
├── .env.example
├── .gitignore
├── docker-compose.yml
├── docker-compose.prod.yml  # Fase 31
└── README.md
```

---

## Backend (`backend/`)

### Estructura objetivo

```
backend/
├── app/
│   ├── api/
│   │   ├── deps.py                    # DB session, usuario actual, permisos
│   │   └── routes/
│   │       ├── auth.py
│   │       ├── institutions.py
│   │       ├── users.py
│   │       ├── students.py
│   │       ├── careers.py
│   │       ├── questions.py
│   │       ├── tests.py
│   │       ├── recommendations.py
│   │       ├── reports.py
│   │       ├── vector.py
│   │       ├── assistant.py
│   │       ├── audit.py
│   │       ├── dashboard.py
│   │       ├── health.py              # Existe
│   │       └── status.py
│   ├── core/
│   │   ├── config.py                  # Existe
│   │   ├── responses.py               # Existe
│   │   ├── exceptions.py
│   │   ├── logging.py
│   │   └── enums.py
│   ├── db/
│   │   ├── session.py                 # Existe
│   │   └── base.py
│   ├── models/                        # SQLAlchemy ORM
│   ├── schemas/                       # Pydantic request/response
│   ├── repositories/
│   ├── services/
│   │   ├── auth_service.py
│   │   ├── test_service.py
│   │   ├── riasec_calculator.py
│   │   ├── recommendation_service.py
│   │   ├── qdrant_service.py
│   │   ├── llm/
│   │   │   ├── provider.py
│   │   │   ├── deepseek_provider.py
│   │   │   └── fallback_provider.py
│   │   ├── pdf_service.py
│   │   └── audit_service.py
│   ├── security/
│   │   ├── jwt.py
│   │   ├── password.py
│   │   ├── permissions.py
│   │   └── rate_limit.py
│   ├── utils/
│   │   ├── validators.py
│   │   └── file_storage.py
│   └── main.py
├── alembic/
│   └── versions/
├── tests/
│   ├── conftest.py
│   ├── test_auth.py
│   ├── test_institutions.py
│   └── ...
├── requirements.txt
├── Dockerfile
└── pytest.ini
```

### Estado actual (Fase 1 completada)

| Carpeta/archivo | Estado |
|-----------------|--------|
| `app/api/routes/health.py`, `status.py` | Implementado |
| `app/api/routes/*.py` (14 routers) | Estructura creada |
| `app/core/` (config, responses, enums, exceptions, logging) | Implementado |
| `app/db/session.py`, `base.py` | Implementado |
| `app/models/`, `schemas/`, `repositories/` | Paquetes creados |
| `app/services/llm/` | Interface + fallback + deepseek stub |
| `app/security/`, `app/utils/` | Paquetes creados |
| `api/deps.py` | Implementado |
| Lógica de negocio en rutas | Pendiente Fases 5-15 |

---

## Frontend (`frontend/lib/`)

### Estructura objetivo

```
frontend/lib/
├── config/
│   └── app_config.dart                # Existe
├── core/
│   ├── constants/
│   ├── errors/
│   │   ├── app_exception.dart
│   │   └── failure_mapper.dart
│   ├── network/
│   │   ├── dio_client.dart            # Existe
│   │   └── auth_interceptor.dart
│   ├── providers/
│   ├── storage/
│   │   └── secure_token_storage.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── responsive_breakpoints.dart
│   └── validators/                    # Migrar desde shared/validators
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── splash/                        # Parcialmente existe
│   ├── home/                          # Existe (temporal, Fase 16)
│   ├── dashboard/
│   │   ├── super_admin/
│   │   ├── institution_admin/
│   │   ├── counselor/
│   │   └── student/
│   ├── institutions/
│   ├── users/
│   ├── students/
│   ├── careers/
│   ├── test/
│   ├── results/
│   ├── reports/
│   ├── assistant/
│   └── audit/
├── shared/
│   ├── validators/                    # Existe (migrar a core/)
│   ├── widgets/
│   │   ├── app_scaffold.dart
│   │   ├── loading_overlay.dart
│   │   ├── error_banner.dart
│   │   ├── data_table_paginated.dart
│   │   └── confirm_dialog.dart
│   └── extensions/
├── router/
│   ├── app_router.dart                # Existe
│   ├── route_names.dart
│   └── auth_guard.dart
└── main.dart
```

### Estado actual (Fase 1 completada)

| Carpeta/archivo | Estado |
|-----------------|--------|
| `config/app_config.dart` | Implementado |
| `core/network/`, `core/theme/`, `core/storage/` | Implementado |
| `core/validators/app_validators.dart` | Migrado desde shared |
| `features/splash/`, `features/home/`, `features/auth/` | Implementado |
| `router/app_router.dart`, `route_names.dart`, `auth_guard.dart` | Implementado |
| `shared/widgets/` (5 widgets) | Implementado |
| `features/*/data|domain|presentation/` | Carpetas creadas |
| `assets/images/` | Creado |
| Pantallas de negocio completas | Pendiente Fases 16-25 |

---

## Convenciones de nomenclatura

| Elemento | Convención | Ejemplo |
|----------|------------|---------|
| Tablas MySQL | snake_case plural | `test_sessions` |
| Modelos SQLAlchemy | PascalCase singular | `TestSession` |
| Schemas Pydantic | PascalCase + sufijo | `TestSessionCreate` |
| Rutas API | kebab-case o snake | `/api/v1/test-sessions` |
| Features Flutter | snake_case carpeta | `features/test/` |
| Providers Riverpod | camelCase + Provider | `testSessionProvider` |
| Rutas GoRouter | kebab-case | `/student/test/instructions` |
