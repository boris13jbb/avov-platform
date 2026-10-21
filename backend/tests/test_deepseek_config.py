"""DeepSeek no se llama con clave vacía o con el marcador de ejemplo."""

from unittest.mock import patch

import pytest

from app.core.config import DEEPSEEK_API_KEY_PLACEHOLDER, Settings
from app.services.llm.llm_service import LLMService


def _service(api_key: str) -> LLMService:
    settings = Settings(_env_file=None, deepseek_api_key=api_key, deepseek_max_retries=1)
    return LLMService(settings)


def test_clave_ausente_no_esta_configurada() -> None:
    assert _service("").is_configured() is False
    assert _service("   ").is_configured() is False


def test_marcador_de_ejemplo_no_esta_configurado() -> None:
    assert _service(DEEPSEEK_API_KEY_PLACEHOLDER).is_configured() is False


def test_clave_no_vacia_distinta_del_marcador_se_considera_configurada() -> None:
    assert _service("clave-de-prueba-no-verificada").is_configured() is True


@pytest.mark.asyncio
async def test_marcador_no_abre_cliente_http() -> None:
    service = _service(DEEPSEEK_API_KEY_PLACEHOLDER)

    def forbidden_client(*args, **kwargs):
        raise AssertionError("no debe crear un cliente HTTP")

    with patch("app.services.llm.llm_service.httpx.AsyncClient", forbidden_client):
        result = await service.explain_riasec_profile({"dominant_profile": "S"})

    assert result.source == "fallback"


@pytest.mark.asyncio
async def test_clave_configurada_intenta_el_cliente_sin_red_real() -> None:
    service = _service("clave-de-prueba-no-verificada")
    calls: list[str] = []

    class FakeResponse:
        def raise_for_status(self) -> None:
            return None

        def json(self) -> dict:
            return {"choices": [{"message": {"content": "texto de prueba"}}]}

    class FakeClient:
        def __init__(self, *args, **kwargs) -> None:
            return None

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args) -> None:
            return None

        async def post(self, url, headers, json):
            calls.append(url)
            assert "clave-de-prueba-no-verificada" not in url
            return FakeResponse()

    with patch("app.services.llm.llm_service.httpx.AsyncClient", FakeClient):
        result = await service.explain_riasec_profile({"dominant_profile": "I"})

    assert calls
    assert result.source == "deepseek"
    assert result.answer == "texto de prueba"


@pytest.mark.asyncio
async def test_error_del_proveedor_no_registra_la_clave(caplog: pytest.LogCaptureFixture) -> None:
    service = _service("clave-de-prueba-no-verificada")

    class BoomClient:
        def __init__(self, *args, **kwargs) -> None:
            return None

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args) -> None:
            return None

        async def post(self, url, headers, json):
            raise RuntimeError("clave-de-prueba-no-verificada")

    with caplog.at_level("WARNING"):
        with patch("app.services.llm.llm_service.httpx.AsyncClient", BoomClient):
            result = await service.explain_riasec_profile({"dominant_profile": "S"})

    assert result.source == "fallback"
    assert "clave-de-prueba-no-verificada" not in caplog.text
    assert "RuntimeError" in caplog.text
