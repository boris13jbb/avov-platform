"""Límite de intentos de login respaldado por Redis.

La clave combina la IP observada y el correo normalizado. No guarda la
contraseña. X-Forwarded-For solo se usa si TRUST_PROXY_HEADERS está activo.
"""

import hashlib
import logging
import threading
from collections.abc import Callable

import redis
from fastapi import Request

from app.core.config import Settings, get_settings
from app.core.exceptions import ServiceUnavailableException, TooManyRequestsException

logger = logging.getLogger(__name__)

RATE_LIMIT_MESSAGE = (
    "Demasiados intentos de inicio de sesión. Espera antes de volver a intentarlo."
)
STORE_UNAVAILABLE_MESSAGE = (
    "No se pudo comprobar el límite de intentos de inicio de sesión."
)
_KEY_PREFIX = "avov:login-fail:"


class LoginAttemptStoreError(Exception):
    """El almacén del límite no pudo completar la operación."""


class LoginAttemptStore:
    def get_count(self, key: str) -> tuple[int, int]:
        raise NotImplementedError

    def increment(self, key: str, window_seconds: int) -> tuple[int, int]:
        raise NotImplementedError

    def release_one(self, key: str) -> None:
        raise NotImplementedError

    def reset(self, key: str) -> None:
        raise NotImplementedError


# INCR y EXPIRE ocurren en un solo script para que la clave no quede sin
# caducidad y para que dos peticiones no reinicien la ventana.
_RESERVE_SCRIPT = """
local count = redis.call('INCR', KEYS[1])
local ttl = redis.call('TTL', KEYS[1])
if ttl < 0 then
  redis.call('EXPIRE', KEYS[1], ARGV[1])
  ttl = tonumber(ARGV[1])
end
return {count, ttl}
"""

_RELEASE_SCRIPT = """
local count = tonumber(redis.call('GET', KEYS[1]) or '0')
if count <= 0 then
  return 0
end
local remaining = redis.call('DECR', KEYS[1])
if remaining <= 0 then
  redis.call('DEL', KEYS[1])
  return 0
end
return remaining
"""


class RedisLoginAttemptStore(LoginAttemptStore):
    def __init__(self, redis_url: str) -> None:
        self._client = redis.from_url(
            redis_url,
            socket_connect_timeout=2,
            socket_timeout=2,
            decode_responses=True,
        )

    def get_count(self, key: str) -> tuple[int, int]:
        try:
            value = self._client.get(key)
            ttl = self._client.ttl(key)
        except redis.RedisError as exc:
            raise LoginAttemptStoreError("consulta") from exc
        count = int(value) if value else 0
        retry_after = ttl if isinstance(ttl, int) and ttl > 0 else 0
        return count, retry_after

    def increment(self, key: str, window_seconds: int) -> tuple[int, int]:
        try:
            count, ttl = self._client.eval(
                _RESERVE_SCRIPT,
                1,
                key,
                window_seconds,
            )
        except redis.RedisError as exc:
            raise LoginAttemptStoreError("incremento") from exc
        return int(count), int(ttl)

    def release_one(self, key: str) -> None:
        try:
            self._client.eval(_RELEASE_SCRIPT, 1, key)
        except redis.RedisError as exc:
            raise LoginAttemptStoreError("liberacion") from exc

    def reset(self, key: str) -> None:
        try:
            self._client.delete(key)
        except redis.RedisError as exc:
            raise LoginAttemptStoreError("limpieza") from exc


class MemoryLoginAttemptStore(LoginAttemptStore):
    """Doble de pruebas. No es el almacén del proceso de la API."""

    def __init__(self, clock: Callable[[], float]) -> None:
        self._clock = clock
        self._counts: dict[str, int] = {}
        self._expires_at: dict[str, float] = {}
        self._lock = threading.Lock()

    def _purge(self, key: str) -> None:
        expires_at = self._expires_at.get(key)
        if expires_at is not None and self._clock() >= expires_at:
            self._counts.pop(key, None)
            self._expires_at.pop(key, None)

    def get_count(self, key: str) -> tuple[int, int]:
        with self._lock:
            self._purge(key)
            count = self._counts.get(key, 0)
            expires_at = self._expires_at.get(key)
            retry_after = (
                0 if expires_at is None else max(0, int(expires_at - self._clock()))
            )
            return count, retry_after

    def increment(self, key: str, window_seconds: int) -> tuple[int, int]:
        with self._lock:
            self._purge(key)
            if key not in self._counts:
                self._expires_at[key] = self._clock() + window_seconds
            self._counts[key] = self._counts.get(key, 0) + 1
            retry_after = max(1, int(self._expires_at[key] - self._clock()))
            return self._counts[key], retry_after

    def release_one(self, key: str) -> None:
        with self._lock:
            self._purge(key)
            remaining = self._counts.get(key, 0) - 1
            if remaining <= 0:
                self._counts.pop(key, None)
                self._expires_at.pop(key, None)
                return
            self._counts[key] = remaining

    def reset(self, key: str) -> None:
        with self._lock:
            self._counts.pop(key, None)
            self._expires_at.pop(key, None)


class LoginRateLimiter:
    def __init__(
        self,
        store: LoginAttemptStore,
        *,
        max_attempts: int,
        window_seconds: int,
    ) -> None:
        if max_attempts < 1:
            raise ValueError("login_max_attempts debe ser mayor que cero")
        if window_seconds < 1:
            raise ValueError("login_window_seconds debe ser mayor que cero")
        self.store = store
        self.max_attempts = max_attempts
        self.window_seconds = window_seconds

    def reserve(self, client_host: str, email: str) -> None:
        """Reserva un intento antes de comprobar la contraseña.

        El intento que alcanza el cupo responde 429 sin consultar la cuenta.
        Los intentos anteriores quedan reservados si las credenciales fallan.
        """
        key = self._key(client_host, email)
        count, retry_after = self._call(self.store.increment, key, self.window_seconds)
        if count >= self.max_attempts:
            self._reject(retry_after)

    def release(self, client_host: str, email: str) -> None:
        """Devuelve la reserva cuando el fallo no es de credenciales."""
        key = self._key(client_host, email)
        try:
            self._call(self.store.release_one, key)
        except ServiceUnavailableException:
            logger.warning("No se pudo devolver un intento de login")

    def clear(self, client_host: str, email: str) -> None:
        key = self._key(client_host, email)
        try:
            self._call(self.store.reset, key)
        except ServiceUnavailableException:
            logger.warning("No se pudo reiniciar el contador tras un login correcto")

    def _call(self, operation, *args):
        try:
            return operation(*args)
        except LoginAttemptStoreError:
            logger.warning("No se pudo usar el almacén del límite de login")
            raise ServiceUnavailableException(STORE_UNAVAILABLE_MESSAGE) from None

    def _reject(self, retry_after: int) -> None:
        raise TooManyRequestsException(
            RATE_LIMIT_MESSAGE,
            retry_after=max(1, retry_after or self.window_seconds),
        )

    @staticmethod
    def _key(client_host: str, email: str) -> str:
        identity = f"{client_host.strip()}\n{email.strip().lower()}"
        digest = hashlib.sha256(identity.encode("utf-8")).hexdigest()
        return _KEY_PREFIX + digest


def client_host(request: Request, *, trust_proxy_headers: bool) -> str:
    """Usa la IP de la conexión directa salvo que el proxy sea de confianza.

    Con el proxy activo se toma el último valor de X-Forwarded-For, el que
    añade el proxy. El primero lo puede falsificar el cliente.
    """
    if trust_proxy_headers:
        forwarded = request.headers.get("x-forwarded-for", "")
        parts = [part.strip() for part in forwarded.split(",") if part.strip()]
        if parts:
            return parts[-1]
    if request.client is not None and request.client.host:
        return request.client.host
    return "unknown"


def build_login_rate_limiter(settings: Settings | None = None) -> LoginRateLimiter:
    current = settings or get_settings()
    return LoginRateLimiter(
        RedisLoginAttemptStore(current.redis_url),
        max_attempts=current.login_max_attempts,
        window_seconds=current.login_window_seconds,
    )


def get_login_rate_limiter() -> LoginRateLimiter:
    return build_login_rate_limiter()
