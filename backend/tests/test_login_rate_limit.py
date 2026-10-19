"""Límite de login, recuperación de la ventana y fallo del almacén."""

import threading

import pytest
from fastapi.testclient import TestClient

from app.core.exceptions import ServiceUnavailableException, TooManyRequestsException
from app.main import app
from app.security.login_rate_limit import (
    RATE_LIMIT_MESSAGE,
    LoginAttemptStoreError,
    LoginRateLimiter,
    MemoryLoginAttemptStore,
    RedisLoginAttemptStore,
    client_host,
    get_login_rate_limiter,
)
from tests.test_auth import _login


class BrokenStore(MemoryLoginAttemptStore):
    def get_count(self, key: str) -> tuple[int, int]:
        raise LoginAttemptStoreError("consulta")

    def increment(self, key: str, window_seconds: int) -> tuple[int, int]:
        raise LoginAttemptStoreError("incremento")


def _limiter(clock: list[float], max_attempts: int = 3) -> LoginRateLimiter:
    return LoginRateLimiter(
        MemoryLoginAttemptStore(clock=lambda: clock[0]),
        max_attempts=max_attempts,
        window_seconds=60,
    )


def test_bloquea_al_alcanzar_el_limite_sin_distinguir_la_cuenta() -> None:
    clock = [0.0]
    limiter = _limiter(clock, max_attempts=2)

    limiter.reserve("203.0.113.8", "Persona@Ejemplo.edu")

    with pytest.raises(TooManyRequestsException):
        limiter.reserve("203.0.113.8", "PERSONA@ejemplo.edu")


def test_la_ventana_vuelve_a_permitir_intentos() -> None:
    clock = [0.0]
    limiter = _limiter(clock, max_attempts=2)
    limiter.reserve("203.0.113.9", "cuenta@ejemplo.edu")

    with pytest.raises(TooManyRequestsException):
        limiter.reserve("203.0.113.9", "cuenta@ejemplo.edu")

    clock[0] = 61.0
    limiter.reserve("203.0.113.9", "cuenta@ejemplo.edu")


def test_un_acierto_reinicia_el_contador() -> None:
    clock = [0.0]
    limiter = _limiter(clock, max_attempts=2)
    limiter.reserve("198.51.100.4", "cuenta@ejemplo.edu")
    limiter.clear("198.51.100.4", "cuenta@ejemplo.edu")
    limiter.reserve("198.51.100.4", "cuenta@ejemplo.edu")

    with pytest.raises(TooManyRequestsException):
        limiter.reserve("198.51.100.4", "cuenta@ejemplo.edu")


def test_reservas_concurrentes_no_superan_el_cupo() -> None:
    limiter = _limiter([0.0], max_attempts=5)
    allowed: list[int] = []
    blocked: list[int] = []
    barrier = threading.Barrier(20)

    def worker() -> None:
        barrier.wait()
        try:
            limiter.reserve("203.0.113.40", "cuenta@ejemplo.edu")
        except TooManyRequestsException:
            blocked.append(1)
        else:
            allowed.append(1)

    threads = [threading.Thread(target=worker) for _ in range(20)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()

    assert len(allowed) == 4
    assert len(blocked) == 16


def test_fallo_de_almacen_no_se_convierte_en_credencial_invalida() -> None:
    limiter = LoginRateLimiter(
        BrokenStore(clock=lambda: 0.0),
        max_attempts=2,
        window_seconds=60,
    )

    try:
        limiter.reserve("203.0.113.10", "cuenta@ejemplo.edu")
    except ServiceUnavailableException as exc:
        assert exc.status_code == 503
        assert "203.0.113.10" not in exc.message
        assert "cuenta@ejemplo.edu" not in exc.message
    else:
        raise AssertionError("debía fallar el almacén")


def test_ignora_x_forwarded_for_si_el_proxy_no_es_de_confianza() -> None:
    request = type(
        "Request",
        (),
        {
            "headers": {"x-forwarded-for": "198.51.100.20, 203.0.113.50"},
            "client": type("Client", (), {"host": "127.0.0.1"})(),
        },
    )()

    assert client_host(request, trust_proxy_headers=False) == "127.0.0.1"
    assert client_host(request, trust_proxy_headers=True) == "203.0.113.50"


def test_endpoint_responde_429_con_el_mismo_mensaje(
    client: TestClient, test_user
) -> None:
    clock = [0.0]
    limiter = _limiter(clock, max_attempts=2)
    app.dependency_overrides[get_login_rate_limiter] = lambda: limiter
    try:
        first_known = _login(client, test_user.email, "clave-incorrecta")
        second_known = _login(client, test_user.email, "clave-incorrecta")
        unknown = _login(client, "nadie-rate-limit@ejemplo.edu", "clave-incorrecta")
        blocked_unknown = _login(client, "nadie-rate-limit@ejemplo.edu", "clave-incorrecta")
    finally:
        app.dependency_overrides.pop(get_login_rate_limiter, None)

    assert first_known.status_code == 401
    assert second_known.status_code == 429
    assert second_known.json()["message"] == RATE_LIMIT_MESSAGE
    assert "Retry-After" in second_known.headers
    assert unknown.status_code == 401
    assert blocked_unknown.status_code == 429
    assert blocked_unknown.json()["message"] == second_known.json()["message"]
    assert test_user.email not in second_known.text
    assert "clave-incorrecta" not in second_known.text


def test_redis_reserva_en_un_solo_script() -> None:
    class FakeRedis:
        def __init__(self) -> None:
            self.script = ""
            self.calls = 0

        def eval(self, script, numkeys, key, window):
            self.calls += 1
            self.script = script
            assert numkeys == 1
            assert key.startswith("avov:login-fail:")
            assert "@" not in key
            return [1, int(window)]

    fake = FakeRedis()
    store = RedisLoginAttemptStore.__new__(RedisLoginAttemptStore)
    store._client = fake
    count, ttl = store.increment("avov:login-fail:hash", 900)

    assert count == 1
    assert ttl == 900
    assert fake.calls == 1
    assert "INCR" in fake.script and "EXPIRE" in fake.script

