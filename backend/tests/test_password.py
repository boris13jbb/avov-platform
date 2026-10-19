"""Pruebas de hashing con credenciales ficticias. No usan la base de datos."""

import pytest

from app.security.password import hash_password, verify_password

CLAVE_FICTICIA = "ClaveFicticia-Avov-1!"
OTRA_CLAVE = "OtraClave-Distinta-2!"


def test_genera_hash_bcrypt() -> None:
    hashed = hash_password(CLAVE_FICTICIA)

    assert hashed != CLAVE_FICTICIA
    assert hashed.startswith("$2b$")


def test_verifica_contrasena_correcta() -> None:
    hashed = hash_password(CLAVE_FICTICIA)

    assert verify_password(CLAVE_FICTICIA, hashed) is True


def test_rechaza_contrasena_incorrecta() -> None:
    hashed = hash_password(CLAVE_FICTICIA)

    assert verify_password(OTRA_CLAVE, hashed) is False


def test_hash_desconocido_se_rechaza_sin_propagar(caplog: pytest.LogCaptureFixture) -> None:
    hash_corrupto = "no-es-un-hash"

    with caplog.at_level("WARNING"):
        assert verify_password(CLAVE_FICTICIA, hash_corrupto) is False

    assert "formato no reconocido" in caplog.text
    assert hash_corrupto not in caplog.text
    assert CLAVE_FICTICIA not in caplog.text


def test_otros_errores_de_verificacion_se_propagan(monkeypatch: pytest.MonkeyPatch) -> None:
    def fallo_interno(_plain: str, _hashed: str) -> bool:
        raise RuntimeError("fallo interno de verificacion")

    monkeypatch.setattr("app.security.password.pwd_context.verify", fallo_interno)

    with pytest.raises(RuntimeError, match="fallo interno de verificacion"):
        verify_password(CLAVE_FICTICIA, "$2b$12$no-se-llega-a-verificar")


def test_dos_hashes_del_mismo_texto_siguen_siendo_validos() -> None:
    first = hash_password(CLAVE_FICTICIA)
    second = hash_password(CLAVE_FICTICIA)

    assert first != second
    assert first.startswith("$2b$")
    assert second.startswith("$2b$")
    assert verify_password(CLAVE_FICTICIA, first) is True
    assert verify_password(CLAVE_FICTICIA, second) is True
