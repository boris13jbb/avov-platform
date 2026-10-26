"""Pruebas del límite horario del asistente."""

from unittest.mock import MagicMock

import pytest

from app.core.config import Settings
from app.core.exceptions import TooManyRequestsException
from app.services.assistant_rate_limit import (
    ASSISTANT_LIMIT_MESSAGE,
    AssistantRateLimiter,
)


class _FakeRedis:
    def __init__(self) -> None:
        self._counts: dict[str, int] = {}

    def incr(self, key: str) -> int:
        self._counts[key] = self._counts.get(key, 0) + 1
        return self._counts[key]

    def expire(self, key: str, ttl: int) -> None:
        del key, ttl

    def ttl(self, key: str) -> int:
        return 3600 if key in self._counts else -1


def _limiter(max_requests: int) -> AssistantRateLimiter:
    settings = Settings(assistant_max_requests_per_hour=max_requests)
    limiter = AssistantRateLimiter(settings=settings)
    limiter._client = _FakeRedis()  # noqa: SLF001 — prueba aislada
    return limiter


def test_assistant_rate_limit_allows_under_cap() -> None:
    limiter = _limiter(2)
    limiter.check_and_increment(42)
    limiter.check_and_increment(42)


def test_assistant_rate_limit_blocks_over_cap() -> None:
    limiter = _limiter(2)
    limiter.check_and_increment(7)
    limiter.check_and_increment(7)
    with pytest.raises(TooManyRequestsException) as exc:
        limiter.check_and_increment(7)
    assert exc.value.message == ASSISTANT_LIMIT_MESSAGE


def test_assistant_rate_limit_disabled_when_zero() -> None:
    limiter = _limiter(0)
    fake = _FakeRedis()
    limiter._client = fake  # noqa: SLF001
    for _ in range(5):
        limiter.check_and_increment(99)
    assert fake._counts == {}


def test_assistant_rate_limit_fail_open_on_redis_error() -> None:
    settings = Settings(assistant_max_requests_per_hour=1)
    limiter = AssistantRateLimiter(settings=settings)
    broken = MagicMock()
    broken.incr.side_effect = RuntimeError("redis caído")
    limiter._client = broken  # noqa: SLF001
    limiter.check_and_increment(1)
