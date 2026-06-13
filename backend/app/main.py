from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi

from app.api.routes import (
    assistant,
    audit,
    auth,
    careers,
    dashboard,
    exports,
    health,
    institutions,
    media,
    questions,
    recommendations,
    reports,
    riasec_categories,
    settings as settings_routes,
    status,
    students,
    tests,
    users,
    vector,
)
from app.core.config import get_settings
from app.core.handlers import register_exception_handlers
from app.core.logging import setup_logging
from app.core.responses import success_response
from app.core.startup import validate_runtime_settings
from app.security.middleware import register_security_middleware

app_settings = get_settings()
setup_logging()


@asynccontextmanager
async def lifespan(_app: FastAPI):
    validate_runtime_settings(app_settings)
    yield


app = FastAPI(
    title="AVOV API",
    description="Asistente Virtual de Orientación Vocacional con IA",
    version="0.1.0",
    docs_url="/docs" if app_settings.app_debug else None,
    redoc_url="/redoc" if app_settings.app_debug else None,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=app_settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

register_security_middleware(app, app_settings)
register_exception_handlers(app)

API_PREFIX = "/api/v1"
app.include_router(health.router, prefix=API_PREFIX)
app.include_router(status.router, prefix=API_PREFIX)
app.include_router(auth.router, prefix=API_PREFIX)
app.include_router(audit.router, prefix=API_PREFIX)
app.include_router(institutions.router, prefix=API_PREFIX)
app.include_router(media.router, prefix=API_PREFIX)
app.include_router(users.router, prefix=API_PREFIX)
app.include_router(students.router, prefix=API_PREFIX)
app.include_router(careers.router, prefix=API_PREFIX)
app.include_router(questions.router, prefix=API_PREFIX)
app.include_router(tests.router, prefix=API_PREFIX)
app.include_router(vector.router, prefix=API_PREFIX)
app.include_router(assistant.router, prefix=API_PREFIX)
app.include_router(recommendations.router, prefix=API_PREFIX)
app.include_router(reports.router, prefix=API_PREFIX)
app.include_router(dashboard.router, prefix=API_PREFIX)
app.include_router(exports.router, prefix=API_PREFIX)
app.include_router(riasec_categories.router, prefix=API_PREFIX)
app.include_router(settings_routes.router, prefix=API_PREFIX)


@app.get(f"{API_PREFIX}/")
def api_root():
    payload: dict[str, str] = {
        "name": app_settings.app_name,
        "version": "0.1.0",
        "api_prefix": API_PREFIX,
    }
    if app_settings.app_debug:
        payload["docs"] = "/docs"
    return success_response(
        data=payload,
        message="Bienvenido a la API de AVOV",
    )


def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema

    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    openapi_schema.setdefault("components", {}).setdefault("securitySchemes", {})[
        "BearerAuth"
    ] = {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "JWT",
        "description": "Token JWT obtenido en POST /api/v1/auth/login",
    }

    protected_paths = (
        "/auth/me",
        "/auth/logout",
        "/auth/change-password",
        "/institutions",
        "/users",
        "/students",
        "/careers",
        "/questions",
        "/tests",
        "/vector",
        "/assistant",
        "/recommendations",
        "/reports",
        "/dashboard",
        "/exports",
        "/audit",
        "/settings",
        "/riasec-categories",
        "/media",
    )
    for path, path_item in openapi_schema.get("paths", {}).items():
        if any(fragment in path for fragment in protected_paths):
            for method in path_item.values():
                if isinstance(method, dict):
                    method["security"] = [{"BearerAuth": []}]

    app.openapi_schema = openapi_schema
    return app.openapi_schema


app.openapi = custom_openapi


@app.get("/")
def root():
    payload: dict[str, str] = {
        "name": app_settings.app_name,
        "version": "0.1.0",
    }
    if app_settings.app_debug:
        payload["docs"] = "/docs"
    return success_response(
        data=payload,
        message="Bienvenido a la API de AVOV",
    )
