from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi

from app.api.routes import (
    assistant,
    auth,
    careers,
    health,
    institutions,
    questions,
    recommendations,
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

settings = get_settings()
setup_logging()

app = FastAPI(
    title="AVOV API",
    description="Asistente Virtual de Orientación Vocacional con IA",
    version="0.1.0",
    docs_url="/docs" if settings.app_debug else None,
    redoc_url="/redoc" if settings.app_debug else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

register_exception_handlers(app)

API_PREFIX = "/api/v1"
app.include_router(health.router, prefix=API_PREFIX)
app.include_router(status.router, prefix=API_PREFIX)
app.include_router(auth.router, prefix=API_PREFIX)
app.include_router(institutions.router, prefix=API_PREFIX)
app.include_router(users.router, prefix=API_PREFIX)
app.include_router(students.router, prefix=API_PREFIX)
app.include_router(careers.router, prefix=API_PREFIX)
app.include_router(questions.router, prefix=API_PREFIX)
app.include_router(tests.router, prefix=API_PREFIX)
app.include_router(recommendations.router, prefix=API_PREFIX)
app.include_router(vector.router, prefix=API_PREFIX)
app.include_router(assistant.router, prefix=API_PREFIX)


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
        "/recommendations",
        "/vector",
        "/assistant",
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
    return success_response(
        data={
            "name": settings.app_name,
            "version": "0.1.0",
            "docs": "/docs",
        },
        message="Bienvenido a la API de AVOV",
    )
