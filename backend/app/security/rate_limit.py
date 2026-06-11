import logging

import redis

from app.core.config import get_settings
from app.core.exceptions import TooManyRequestsException

logger = logging.getLogger(__name__)


class LoginRateLimiter:
    """Limita intentos fallidos de login por IP + correo usando Redis."""

    KEY_PREFIX = "avov:login_rate:"

    def __init__(self) -> None:
        settings = get_settings()
        self._max_attempts = settings.login_rate_limit_max
        self._window_seconds = settings.login_rate_limit_window_seconds
        self._redis_url = settings.redis_url
        self._client: redis.Redis | None = None

    def _get_client(self) -> redis.Redis | None:
        try:
            if self._client is None:
                self._client = redis.from_url(self._redis_url, decode_responses=True)
            self._client.ping()
            return self._client
        except Exception as exc:
            logger.warning("Redis no disponible para rate limit de login: %s", exc)
            return None

    def ensure_not_blocked(self, identifier: str) -> None:
        client = self._get_client()
        if client is None:
            return

        key = f"{self.KEY_PREFIX}{identifier}"
        raw_value = client.get(key)
        if raw_value is None:
            return

        attempts = int(raw_value)
        if attempts >= self._max_attempts:
            raise TooManyRequestsException(
                "Demasiados intentos de inicio de sesión. "
                "Espera unos minutos e intenta de nuevo."
            )

    def record_failed_attempt(self, identifier: str) -> None:
        client = self._get_client()
        if client is None:
            return

        key = f"{self.KEY_PREFIX}{identifier}"
        attempts = client.incr(key)
        if attempts == 1:
            client.expire(key, self._window_seconds)

    def clear(self, identifier: str) -> None:
        client = self._get_client()
        if client is None:
            return
        client.delete(f"{self.KEY_PREFIX}{identifier}")


login_rate_limiter = LoginRateLimiter()
