"""Límite horario de uso del asistente IA (control de coste)."""

from __future__ import annotations

import logging

import redis

from app.core.config import Settings, get_settings
from app.core.exceptions import TooManyRequestsException

logger = logging.getLogger(__name__)

_KEY_PREFIX = "avov:assistant-use:"
ASSISTANT_LIMIT_MESSAGE = (
    "Has alcanzado el límite de consultas al asistente por hora. "
    "Inténtalo más tarde."
)


class AssistantRateLimiter:
    def __init__(self, settings: Settings | None = None) -> None:
        self.settings = settings or get_settings()
        self._client: redis.Redis | None = None

    def _get_client(self) -> redis.Redis:
        if self._client is None:
            self._client = redis.from_url(
                self.settings.redis_url,
                socket_connect_timeout=2,
                socket_timeout=2,
                decode_responses=True,
            )
        return self._client

    def check_and_increment(self, user_id: int) -> None:
        limit = self.settings.assistant_max_requests_per_hour
        if limit <= 0:
            return
        key = f"{_KEY_PREFIX}{user_id}"
        try:
            client = self._get_client()
            count = int(client.incr(key))
            if count == 1:
                client.expire(key, 3600)
            if count > limit:
                ttl = client.ttl(key)
                retry_after = (
                    ttl if isinstance(ttl, int) and ttl > 0 else 3600
                )
                raise TooManyRequestsException(
                    ASSISTANT_LIMIT_MESSAGE,
                    retry_after=retry_after,
                )
        except TooManyRequestsException:
            raise
        except Exception:
            logger.warning(
                "No se pudo aplicar el límite del asistente; se permite la solicitud",
                exc_info=True,
            )
