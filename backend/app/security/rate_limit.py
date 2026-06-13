import logging

import redis

from app.core.config import get_settings
from app.core.exceptions import TooManyRequestsException

logger = logging.getLogger(__name__)


class RedisRateLimiter:
    """Limita solicitudes por identificador (IP, usuario, etc.) usando Redis."""

    def __init__(
        self,
        key_prefix: str,
        max_attempts: int,
        window_seconds: int,
        blocked_message: str,
    ) -> None:
        settings = get_settings()
        self._key_prefix = key_prefix
        self._max_attempts = max_attempts
        self._window_seconds = window_seconds
        self._blocked_message = blocked_message
        self._redis_url = settings.redis_url
        self._client: redis.Redis | None = None

    def _get_client(self) -> redis.Redis | None:
        try:
            if self._client is None:
                self._client = redis.from_url(self._redis_url, decode_responses=True)
            self._client.ping()
            return self._client
        except Exception as exc:
            logger.warning(
                "Redis no disponible para rate limit (%s): %s",
                self._key_prefix,
                exc,
            )
            return None

    def ensure_not_blocked(self, identifier: str) -> None:
        client = self._get_client()
        if client is None:
            return

        key = f"{self._key_prefix}{identifier}"
        raw_value = client.get(key)
        if raw_value is None:
            return

        attempts = int(raw_value)
        if attempts >= self._max_attempts:
            raise TooManyRequestsException(self._blocked_message)

    def record_attempt(self, identifier: str) -> None:
        client = self._get_client()
        if client is None:
            return

        key = f"{self._key_prefix}{identifier}"
        attempts = client.incr(key)
        if attempts == 1:
            client.expire(key, self._window_seconds)

    def record_failed_attempt(self, identifier: str) -> None:
        """Alias retrocompatible con el limitador de login."""
        self.record_attempt(identifier)

    def clear(self, identifier: str) -> None:
        client = self._get_client()
        if client is None:
            return
        client.delete(f"{self._key_prefix}{identifier}")


def _build_limiters() -> tuple[
    RedisRateLimiter, RedisRateLimiter, RedisRateLimiter, RedisRateLimiter
]:
    settings = get_settings()
    login = RedisRateLimiter(
        key_prefix="avov:login_rate:",
        max_attempts=settings.login_rate_limit_max,
        window_seconds=settings.login_rate_limit_window_seconds,
        blocked_message=(
            "Demasiados intentos de inicio de sesión. "
            "Espera unos minutos e intenta de nuevo."
        ),
    )
    forgot_password = RedisRateLimiter(
        key_prefix="avov:forgot_password_rate:",
        max_attempts=settings.forgot_password_rate_limit_max,
        window_seconds=settings.forgot_password_rate_limit_window_seconds,
        blocked_message=(
            "Demasiadas solicitudes de recuperación de contraseña. "
            "Espera unos minutos e intenta de nuevo."
        ),
    )
    reset_password = RedisRateLimiter(
        key_prefix="avov:reset_password_rate:",
        max_attempts=settings.reset_password_rate_limit_max,
        window_seconds=settings.reset_password_rate_limit_window_seconds,
        blocked_message=(
            "Demasiados intentos de restablecimiento de contraseña. "
            "Espera unos minutos e intenta de nuevo."
        ),
    )
    assistant = RedisRateLimiter(
        key_prefix="avov:assistant_rate:",
        max_attempts=settings.assistant_rate_limit_max,
        window_seconds=settings.assistant_rate_limit_window_seconds,
        blocked_message=(
            "Has alcanzado el límite de consultas al asistente. "
            "Intenta de nuevo más tarde."
        ),
    )
    return login, forgot_password, reset_password, assistant


login_rate_limiter, forgot_password_rate_limiter, reset_password_rate_limiter, assistant_rate_limiter = (
    _build_limiters()
)
