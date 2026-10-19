from functools import lru_cache
from typing import List
from urllib.parse import unquote, urlparse

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
        populate_by_name=True,
    )

    app_name: str = Field(default="AVOV", alias="APP_NAME")
    app_env: str = Field(default="development", alias="APP_ENV")
    app_debug: bool = Field(default=True, alias="APP_DEBUG")
    app_secret_key: str = Field(default="change-me", alias="APP_SECRET_KEY")

    backend_host: str = Field(default="0.0.0.0", alias="BACKEND_HOST")
    backend_port: int = Field(default=8000, alias="BACKEND_PORT")
    backend_cors_origins: str = Field(
        default="http://localhost:8080",
        alias="BACKEND_CORS_ORIGINS",
    )

    # Desde Windows el MySQL de AVOV se publica en 3307. El 3306 del host es XAMPP.
    # Dentro de Docker, Compose fija DATABASE_URL con el host interno mysql:3306.
    database_url: str = Field(
        default="mysql+pymysql://avov_user:avov_user_secret@127.0.0.1:3307/avov_db",
        alias="DATABASE_URL",
    )

    # Desde Windows el Redis de AVOV se publica en 6380. El 6379 del host es otro proyecto.
    # Dentro de Docker, Compose fija REDIS_URL en redis://redis:6379/0.
    redis_url: str = Field(default="redis://127.0.0.1:6380/0", alias="REDIS_URL")

    qdrant_host: str = Field(default="localhost", alias="QDRANT_HOST")
    qdrant_port: int = Field(default=6333, alias="QDRANT_PORT")
    qdrant_api_key: str | None = Field(default=None, alias="QDRANT_API_KEY")
    qdrant_collection_careers: str = Field(
        default="avov_careers",
        alias="QDRANT_COLLECTION_CAREERS",
    )
    qdrant_vector_size: int = Field(default=384, alias="QDRANT_VECTOR_SIZE")

    jwt_secret_key: str = Field(default="change-me-jwt", alias="JWT_SECRET_KEY")
    jwt_algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    jwt_access_token_expire_minutes: int = Field(
        default=30,
        alias="JWT_ACCESS_TOKEN_EXPIRE_MINUTES",
    )
    jwt_refresh_token_expire_days: int = Field(
        default=7,
        alias="JWT_REFRESH_TOKEN_EXPIRE_DAYS",
    )

    # Solo debe activarse detrás de un proxy que reescriba X-Forwarded-For.
    trust_proxy_headers: bool = Field(default=False, alias="TRUST_PROXY_HEADERS")
    login_max_attempts: int = Field(default=5, alias="LOGIN_MAX_ATTEMPTS")
    login_window_seconds: int = Field(default=900, alias="LOGIN_WINDOW_SECONDS")

    deepseek_api_key: str = Field(default="", alias="DEEPSEEK_API_KEY")
    deepseek_api_base_url: str = Field(
        default="https://api.deepseek.com",
        alias="DEEPSEEK_API_BASE_URL",
    )
    deepseek_model: str = Field(default="deepseek-chat", alias="DEEPSEEK_MODEL")
    deepseek_timeout_seconds: int = Field(default=60, alias="DEEPSEEK_TIMEOUT_SECONDS")
    deepseek_max_retries: int = Field(default=3, alias="DEEPSEEK_MAX_RETRIES")

    @property
    def cors_origins(self) -> List[str]:
        return [
            origin.strip()
            for origin in self.backend_cors_origins.split(",")
            if origin.strip()
        ]


DEEPSEEK_API_KEY_PLACEHOLDER = "your-deepseek-api-key-here"

_EXAMPLE_JWT_SECRETS = frozenset(
    {
        "change-me-jwt",
        "change-me-jwt-secret-key-min-32-chars",
    }
)
_EXAMPLE_APP_SECRETS = frozenset(
    {
        "change-me",
        "change-me-to-a-long-random-secret-key-min-32-chars",
    }
)
_EXAMPLE_DATABASE_PASSWORDS = frozenset(
    {
        "avov_user_secret",
        "avov_root_secret",
    }
)
_PRODUCTION_ENVIRONMENTS = frozenset({"production", "prod"})


class InsecureConfigurationError(RuntimeError):
    """La configuración de producción usa valores de ejemplo conocidos."""

    def __init__(self, fields: list[str]) -> None:
        self.fields = fields
        super().__init__(
            "Configuración insegura para producción en: " + ", ".join(fields)
        )


def is_production_environment(app_env: str) -> bool:
    return app_env.strip().lower() in _PRODUCTION_ENVIRONMENTS


def ensure_production_configuration(settings: Settings) -> None:
    """Rechaza marcadores conocidos cuando el entorno es producción.

    El mensaje solo nombra variables. No incluye valores.
    """
    if not is_production_environment(settings.app_env):
        return

    insecure: list[str] = []
    jwt_secret = settings.jwt_secret_key.strip()
    app_secret = settings.app_secret_key.strip()
    if not jwt_secret or jwt_secret in _EXAMPLE_JWT_SECRETS:
        insecure.append("JWT_SECRET_KEY")
    if not app_secret or app_secret in _EXAMPLE_APP_SECRETS:
        insecure.append("APP_SECRET_KEY")
    database_password = _database_password(settings.database_url)
    if database_password == "" or database_password in _EXAMPLE_DATABASE_PASSWORDS:
        insecure.append("DATABASE_URL")
    if settings.app_debug:
        insecure.append("APP_DEBUG")

    if insecure:
        raise InsecureConfigurationError(insecure)


def _database_password(database_url: str) -> str:
    parsed = urlparse(database_url)
    if parsed.password is None:
        return ""
    return unquote(parsed.password)


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    ensure_production_configuration(settings)
    return settings
