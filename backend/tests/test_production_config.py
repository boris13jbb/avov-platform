"""La producción no arranca con marcadores conocidos. El desarrollo sí."""

import pytest

from app.core.config import (
    InsecureConfigurationError,
    Settings,
    ensure_production_configuration,
)

_JWT_MARKER = "change-me-jwt-secret-key-min-32-chars"
_APP_MARKER = "change-me-to-a-long-random-secret-key-min-32-chars"
_DB_MARKER = "avov_user_secret"


def _settings(**overrides) -> Settings:
    values = {
        "app_env": "development",
        "app_secret_key": _APP_MARKER,
        "jwt_secret_key": _JWT_MARKER,
        "database_url": f"mysql+pymysql://avov_user:{_DB_MARKER}@127.0.0.1:3307/avov_db",
        "deepseek_api_key": "",
    }
    values.update(overrides)
    return Settings(_env_file=None).model_copy(update=values)


def test_desarrollo_acepta_marcadores_locales() -> None:
    ensure_production_configuration(_settings())


def test_produccion_rechaza_marcadores_sin_revelarlos() -> None:
    settings = _settings(app_env="production")

    with pytest.raises(InsecureConfigurationError) as captured:
        ensure_production_configuration(settings)

    message = str(captured.value)
    assert captured.value.fields == [
        "JWT_SECRET_KEY",
        "APP_SECRET_KEY",
        "DATABASE_URL",
        "APP_DEBUG",
    ]
    assert _JWT_MARKER not in message
    assert _APP_MARKER not in message
    assert _DB_MARKER not in message


def test_produccion_acepta_secretos_distintos_de_los_ejemplos() -> None:
    settings = _settings(
        app_env="prod",
        app_debug=False,
        app_secret_key="aplicacion-produccion-distinta-del-ejemplo-01",
        jwt_secret_key="prefijo-change-me-no-es-el-marcador-exacto",
        database_url="mysql+pymysql://avov_user:clave-produccion-distinta@mysql:3306/avov_db",
    )

    ensure_production_configuration(settings)
