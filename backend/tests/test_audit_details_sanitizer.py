"""Pruebas unitarias de sanitización de details de auditoría."""

from app.security.audit_details import (
    REDACTED_MARKER,
    is_sensitive_audit_key,
    sanitize_audit_details,
)


def test_redacts_access_and_refresh_tokens():
    payload = {
        "access_token": "fake-access-token-value-001",
        "refresh_token": "fake-refresh-token-value-002",
        "result": "success",
    }
    sanitized = sanitize_audit_details(payload)
    assert sanitized is not None
    assert sanitized["access_token"] == REDACTED_MARKER
    assert sanitized["refresh_token"] == REDACTED_MARKER
    assert sanitized["result"] == "success"
    assert "fake-access-token-value-001" not in str(sanitized)
    assert "fake-refresh-token-value-002" not in str(sanitized)


def test_redacts_passwords_api_keys_and_secrets():
    payload = {
        "password": "FakePass123!",
        "api_key": "sk-fake-api-key-value",
        "client_secret": "fake-client-secret",
        "source": "login",
    }
    sanitized = sanitize_audit_details(payload)
    assert sanitized is not None
    assert sanitized["password"] == REDACTED_MARKER
    assert sanitized["api_key"] == REDACTED_MARKER
    assert sanitized["client_secret"] == REDACTED_MARKER
    assert sanitized["source"] == "login"
    assert "FakePass123!" not in str(sanitized)
    assert "sk-fake-api-key-value" not in str(sanitized)
    assert "fake-client-secret" not in str(sanitized)


def test_detects_key_casing_and_separators():
    variants = [
        "Password",
        "PASSWORD",
        "pass-word",
        "pass_word",
        "AccessToken",
        "access-token",
        "API_KEY",
        "api-Key",
        "Authorization",
        "refreshToken",
        "Contraseña",
    ]
    for key in variants:
        assert is_sensitive_audit_key(key), key
        sanitized = sanitize_audit_details({key: "sensitive-fake-value"})
        assert sanitized is not None
        assert sanitized[key] == REDACTED_MARKER
        assert "sensitive-fake-value" not in str(sanitized)


def test_redacts_nested_objects_and_lists():
    payload = {
        "event": "auth",
        "nested": {
            "Authorization": "Bearer fake-nested-token",
            "ok": True,
            "deeper": {"clientSecret": "nested-secret-value"},
        },
        "items": [
            {"refresh-token": "list-refresh-token", "status": "ok"},
            {"status": "skipped"},
        ],
    }
    sanitized = sanitize_audit_details(payload)
    assert sanitized is not None
    assert sanitized["event"] == "auth"
    assert sanitized["nested"]["Authorization"] == REDACTED_MARKER
    assert sanitized["nested"]["ok"] is True
    assert sanitized["nested"]["deeper"]["clientSecret"] == REDACTED_MARKER
    assert sanitized["items"][0]["refresh-token"] == REDACTED_MARKER
    assert sanitized["items"][0]["status"] == "ok"
    assert sanitized["items"][1]["status"] == "skipped"
    assert "fake-nested-token" not in str(sanitized)
    assert "nested-secret-value" not in str(sanitized)
    assert "list-refresh-token" not in str(sanitized)


def test_preserves_legitimate_audit_fields_and_empty_shapes():
    assert sanitize_audit_details(None) is None
    assert sanitize_audit_details({}) == {}
    assert sanitize_audit_details({"tags": []}) == {"tags": []}
    payload = {
        "action": "LOGIN",
        "entity": "auth",
        "entity_id": 42,
        "result": "success",
        "reason": "ok",
        "source": "web",
        "nullable": None,
    }
    assert sanitize_audit_details(payload) == payload


def test_does_not_mutate_original_payload():
    original = {
        "password": "must-remain-in-original",
        "meta": {"token": "must-remain-nested", "ok": 1},
    }
    sanitized = sanitize_audit_details(original)
    assert original["password"] == "must-remain-in-original"
    assert original["meta"]["token"] == "must-remain-nested"
    assert sanitized is not None
    assert sanitized["password"] == REDACTED_MARKER
    assert sanitized["meta"]["token"] == REDACTED_MARKER
    assert sanitized["meta"]["ok"] == 1


def test_sanitization_failure_never_returns_sensitive_data():
    class ExplodingMap(dict):
        def items(self):
            raise RuntimeError("fallo intencional de sanitización")

    payload = ExplodingMap(password="must-not-leak", token="must-not-leak-either")
    sanitized = sanitize_audit_details(payload)
    assert sanitized == {"_sanitization": REDACTED_MARKER}
    assert "must-not-leak" not in str(sanitized)
    assert "must-not-leak-either" not in str(sanitized)
