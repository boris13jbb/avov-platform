from functools import lru_cache
from typing import List

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
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

    database_url: str = Field(
        default="mysql+pymysql://avov_user:avov_user_secret@localhost:3306/avov_db",
        alias="DATABASE_URL",
    )

    redis_url: str = Field(default="redis://localhost:6379/0", alias="REDIS_URL")

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

    login_rate_limit_max: int = Field(default=5, alias="LOGIN_RATE_LIMIT_MAX")
    login_rate_limit_window_seconds: int = Field(
        default=900,
        alias="LOGIN_RATE_LIMIT_WINDOW_SECONDS",
    )
    forgot_password_rate_limit_max: int = Field(
        default=3,
        alias="FORGOT_PASSWORD_RATE_LIMIT_MAX",
    )
    forgot_password_rate_limit_window_seconds: int = Field(
        default=900,
        alias="FORGOT_PASSWORD_RATE_LIMIT_WINDOW_SECONDS",
    )
    reset_password_rate_limit_max: int = Field(
        default=5,
        alias="RESET_PASSWORD_RATE_LIMIT_MAX",
    )
    reset_password_rate_limit_window_seconds: int = Field(
        default=900,
        alias="RESET_PASSWORD_RATE_LIMIT_WINDOW_SECONDS",
    )
    assistant_rate_limit_max: int = Field(
        default=30,
        alias="ASSISTANT_RATE_LIMIT_MAX",
    )
    assistant_rate_limit_window_seconds: int = Field(
        default=3600,
        alias="ASSISTANT_RATE_LIMIT_WINDOW_SECONDS",
    )

    security_headers_enabled: bool = Field(
        default=True,
        alias="SECURITY_HEADERS_ENABLED",
    )
    backend_allowed_hosts: str = Field(
        default="localhost,127.0.0.1",
        alias="BACKEND_ALLOWED_HOSTS",
    )

    password_reset_expire_hours: int = Field(
        default=1,
        alias="PASSWORD_RESET_EXPIRE_HOURS",
    )
    frontend_base_url: str = Field(
        default="http://localhost:8080",
        alias="FRONTEND_BASE_URL",
    )

    smtp_enabled: bool = Field(default=False, alias="SMTP_ENABLED")
    smtp_host: str = Field(default="localhost", alias="SMTP_HOST")
    smtp_port: int = Field(default=587, alias="SMTP_PORT")
    smtp_use_tls: bool = Field(default=True, alias="SMTP_USE_TLS")
    smtp_username: str = Field(default="", alias="SMTP_USERNAME")
    smtp_password: str = Field(default="", alias="SMTP_PASSWORD")
    smtp_from_email: str = Field(
        default="noreply@avov.local",
        alias="SMTP_FROM_EMAIL",
    )

    deepseek_api_key: str = Field(default="", alias="DEEPSEEK_API_KEY")
    deepseek_api_base_url: str = Field(
        default="https://api.deepseek.com",
        alias="DEEPSEEK_API_BASE_URL",
    )
    deepseek_model: str = Field(default="deepseek-chat", alias="DEEPSEEK_MODEL")
    deepseek_timeout_seconds: int = Field(default=60, alias="DEEPSEEK_TIMEOUT_SECONDS")
    deepseek_max_retries: int = Field(default=3, alias="DEEPSEEK_MAX_RETRIES")

    @property
    def is_production(self) -> bool:
        return self.app_env.strip().lower() == "production"

    @property
    def cors_origins(self) -> List[str]:
        return [
            origin.strip()
            for origin in self.backend_cors_origins.split(",")
            if origin.strip()
        ]

    @property
    def trusted_hosts(self) -> List[str]:
        return [
            host.strip()
            for host in self.backend_allowed_hosts.split(",")
            if host.strip()
        ]


@lru_cache
def get_settings() -> Settings:
    return Settings()
