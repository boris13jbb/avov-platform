import pytest
from fastapi.testclient import TestClient

from app.core.config import Settings
from app.core.startup import validate_runtime_settings
from app.security.rate_limit import RedisRateLimiter


def test_security_headers_present(client: TestClient):
    response = client.get("/api/v1/health/live")
    assert response.status_code == 200
    assert response.headers.get("X-Content-Type-Options") == "nosniff"
    assert response.headers.get("X-Frame-Options") == "SAMEORIGIN"
    assert response.headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"


def test_production_rejects_weak_secrets():
    settings = Settings(
        APP_ENV="production",
        APP_DEBUG=False,
        APP_SECRET_KEY="change-me",
        JWT_SECRET_KEY="change-me-jwt",
        BACKEND_CORS_ORIGINS="https://app.example.com",
    )
    with pytest.raises(RuntimeError, match="APP_SECRET_KEY"):
        validate_runtime_settings(settings)


def test_production_rejects_wildcard_cors():
    settings = Settings(
        APP_ENV="production",
        APP_DEBUG=False,
        APP_SECRET_KEY="a" * 32,
        JWT_SECRET_KEY="b" * 32,
        BACKEND_CORS_ORIGINS="*",
    )
    with pytest.raises(RuntimeError, match="CORS"):
        validate_runtime_settings(settings)


def test_development_skips_production_validation():
    settings = Settings(
        APP_ENV="development",
        APP_SECRET_KEY="change-me",
        JWT_SECRET_KEY="change-me-jwt",
    )
    validate_runtime_settings(settings)


def test_redis_rate_limiter_blocks_after_max_attempts():
    import redis

    from app.core.config import get_settings
    from app.core.exceptions import TooManyRequestsException

    try:
        redis_client = redis.from_url(get_settings().redis_url, decode_responses=True)
        redis_client.ping()
    except Exception:
        pytest.skip("Redis no disponible para probar rate limit")

    limiter = RedisRateLimiter(
        key_prefix="avov:test_rate:",
        max_attempts=2,
        window_seconds=60,
        blocked_message="Límite de prueba alcanzado",
    )
    rate_key = "unit-test-key"

    try:
        limiter.clear(rate_key)
        limiter.record_attempt(rate_key)
        limiter.record_attempt(rate_key)

        with pytest.raises(TooManyRequestsException, match="Límite de prueba"):
            limiter.ensure_not_blocked(rate_key)
    finally:
        limiter.clear(rate_key)
