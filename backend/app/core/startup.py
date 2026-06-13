import logging

from app.core.config import Settings

logger = logging.getLogger(__name__)

_WEAK_SECRETS = frozenset(
    {
        "",
        "change-me",
        "change-me-jwt",
        "change-me-to-a-long-random-secret-key-min-32-chars",
        "change-me-jwt-secret-key-min-32-chars",
    }
)


def validate_runtime_settings(settings: Settings) -> None:
    """Evita arrancar en producción con secretos débiles o CORS abierto."""
    if not settings.is_production:
        return

    errors: list[str] = []

    if settings.app_secret_key in _WEAK_SECRETS or len(settings.app_secret_key) < 32:
        errors.append("APP_SECRET_KEY debe tener al menos 32 caracteres seguros")

    if settings.jwt_secret_key in _WEAK_SECRETS or len(settings.jwt_secret_key) < 32:
        errors.append("JWT_SECRET_KEY debe tener al menos 32 caracteres seguros")

    if settings.app_debug:
        errors.append("APP_DEBUG debe ser false en producción")

    if "*" in settings.cors_origins:
        errors.append("BACKEND_CORS_ORIGINS no puede incluir '*' en producción")

    if errors:
        joined = "; ".join(errors)
        raise RuntimeError(f"Configuración de producción inválida: {joined}")

    logger.info("Validación de seguridad de producción completada")
