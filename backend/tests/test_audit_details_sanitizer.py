"""Pruebas unitarias de sanitización de details de auditoría."""

from app.security.audit_details import (
    REDACTED_MARKER,
    is_sensitive_audit_key,
    redact_secrets_in_text,
    sanitize_audit_details,
)


FAKE_JWT = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.fake-payload.fake-sig"
FAKE_API = "sk-fake-embedded-api-key-999"
FAKE_PASS = "FakeEmbeddedPass999!"
FAKE_REFRESH = "fake-embedded-refresh-999"
FAKE_COOKIE = "sessionid=fake-session-cookie-abc; Path=/; HttpOnly"
FAKE_PEM = (
    "-----BEGIN RSA PRIVATE KEY-----\n"
    "MIIEowIBAAKFAKEPRIVATEKEYMATERIALFORTESTSONLY99\n"
    "-----END RSA PRIVATE KEY-----"
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
        "message": f"Authorization: Bearer {FAKE_JWT}",
    }
    sanitized = sanitize_audit_details(original)
    assert original["password"] == "must-remain-in-original"
    assert original["meta"]["token"] == "must-remain-nested"
    assert FAKE_JWT in original["message"]
    assert sanitized is not None
    assert sanitized["password"] == REDACTED_MARKER
    assert sanitized["meta"]["token"] == REDACTED_MARKER
    assert sanitized["meta"]["ok"] == 1
    assert FAKE_JWT not in sanitized["message"]


def test_sanitization_failure_never_returns_sensitive_data():
    class ExplodingMap(dict):
        def items(self):
            raise RuntimeError("fallo intencional de sanitización")

    payload = ExplodingMap(password="must-not-leak", token="must-not-leak-either")
    sanitized = sanitize_audit_details(payload)
    assert sanitized == {"_sanitization": REDACTED_MARKER}
    assert "must-not-leak" not in str(sanitized)
    assert "must-not-leak-either" not in str(sanitized)


def test_redacts_bearer_token_inside_message():
    payload = {
        "message": f"Fallo de reintento. Authorization: Bearer {FAKE_JWT}",
        "result": "error",
    }
    sanitized = sanitize_audit_details(payload)
    assert sanitized is not None
    assert "Fallo de reintento" in sanitized["message"]
    assert "Authorization:" in sanitized["message"]
    assert FAKE_JWT not in sanitized["message"]
    assert REDACTED_MARKER in sanitized["message"]
    assert sanitized["result"] == "error"


def test_redacts_key_value_credentials_inside_description():
    payload = {
        "description": (
            f"Proveedor rechazó la petición api_key={FAKE_API} "
            f"password={FAKE_PASS} refresh_token={FAKE_REFRESH}"
        ),
    }
    sanitized = sanitize_audit_details(payload)
    assert sanitized is not None
    assert "Proveedor rechazó la petición" in sanitized["description"]
    assert FAKE_API not in sanitized["description"]
    assert FAKE_PASS not in sanitized["description"]
    assert FAKE_REFRESH not in sanitized["description"]
    assert sanitized["description"].count(REDACTED_MARKER) >= 3


def test_redacts_multiline_authorization_headers():
    text = (
        "Resumen del error:\n"
        f"Authorization: Bearer {FAKE_JWT}\n"
        "estado=fallido\n"
        f"Authorization: Basic ZmFrZTp1c2Vy\n"
    )
    sanitized = redact_secrets_in_text(text)
    assert "Resumen del error" in sanitized
    assert "estado=fallido" in sanitized
    assert FAKE_JWT not in sanitized
    assert "ZmFrZTp1c2Vy" not in sanitized
    assert sanitized.count(REDACTED_MARKER) >= 2


def test_redacts_embedded_secrets_in_nested_structures():
    payload = {
        "events": [
            {"note": f"Bearer {FAKE_JWT}"},
            {"note": "sin secretos"},
        ],
        "meta": {
            "error": f"client_secret={FAKE_PASS}",
            "ok": True,
        },
    }
    sanitized = sanitize_audit_details(payload)
    assert sanitized is not None
    assert FAKE_JWT not in sanitized["events"][0]["note"]
    assert REDACTED_MARKER in sanitized["events"][0]["note"]
    assert sanitized["events"][1]["note"] == "sin secretos"
    assert FAKE_PASS not in sanitized["meta"]["error"]
    assert sanitized["meta"]["ok"] is True


def test_redacts_cookies_and_pem_private_keys():
    cookie_text = f"Cabecera recibida Cookie: {FAKE_COOKIE}"
    cookie_out = redact_secrets_in_text(cookie_text)
    assert "Cabecera recibida" in cookie_out
    assert "fake-session-cookie-abc" not in cookie_out
    assert REDACTED_MARKER in cookie_out

    pem_text = f"Material inválido:\n{FAKE_PEM}\nfin"
    pem_out = redact_secrets_in_text(pem_text)
    assert "Material inválido" in pem_out
    assert "MIIEowIBAAKFAKEPRIVATEKEYMATERIALFORTESTSONLY99" not in pem_out
    assert "BEGIN RSA PRIVATE KEY" not in pem_out
    assert REDACTED_MARKER in pem_out


def test_redacts_assignment_casing_variants():
    variants = [
        f"API_KEY={FAKE_API}",
        f"Api-Key: {FAKE_API}",
        f"ACCESS_TOKEN={FAKE_JWT}",
        f"Refresh-Token: {FAKE_REFRESH}",
        f"PASSWORD={FAKE_PASS}",
        f"Client_Secret={FAKE_PASS}",
    ]
    for sample in variants:
        out = redact_secrets_in_text(f"ctx {sample} ok")
        assert "ctx " in out
        assert " ok" in out
        assert FAKE_API not in out
        assert FAKE_JWT not in out
        assert FAKE_REFRESH not in out
        assert FAKE_PASS not in out
        assert REDACTED_MARKER in out


def test_preserves_context_around_secret():
    text = f"ANTES Authorization: Bearer {FAKE_JWT} DESPUES"
    out = redact_secrets_in_text(text)
    assert out.startswith("ANTES ")
    assert out.endswith(" DESPUES")
    assert FAKE_JWT not in out


def test_preserves_legitimate_messages_mentioning_sensitive_words():
    messages = [
        "El usuario inició sesión correctamente.",
        "Se actualizó la configuración institucional.",
        "La operación finalizó con estado 200.",
        "Se generó un token de acceso para la sesión.",
        "El usuario debe cambiar su password en el próximo inicio.",
        "La política de secret rotation se documentó.",
        "resource_id=42 entity=institution",
    ]
    for message in messages:
        assert redact_secrets_in_text(message) == message
        sanitized = sanitize_audit_details({"message": message, "entity_id": 7})
        assert sanitized == {"message": message, "entity_id": 7}


def test_oversized_text_is_fully_redacted_fail_safe():
    huge = "x" * (256_000 + 1)
    assert redact_secrets_in_text(huge) == REDACTED_MARKER


def test_redacts_credentials_in_urls_and_query_params():
    db_url = (
        f"Conexión fallida mysql+pymysql://avov_user:{FAKE_PASS}@127.0.0.1:3307/avov_db"
    )
    out = redact_secrets_in_text(db_url)
    assert "mysql+pymysql://avov_user:" in out
    assert FAKE_PASS not in out
    assert "@127.0.0.1:3307/avov_db" in out
    assert REDACTED_MARKER in out

    redis_url = f"redis://:{FAKE_PASS}@redis:6379/0"
    redis_out = redact_secrets_in_text(redis_url)
    assert FAKE_PASS not in redis_out
    assert redis_out.startswith("redis://:")
    assert "@redis:6379/0" in redis_out

    query = (
        f"callback https://api.ejemplo.test/hook?api_key={FAKE_API}"
        f"&token={FAKE_REFRESH}&resource=42"
    )
    query_out = redact_secrets_in_text(query)
    assert "resource=42" in query_out
    assert FAKE_API not in query_out
    assert FAKE_REFRESH not in query_out
    assert query_out.count(REDACTED_MARKER) >= 2


def test_redacts_secrets_inside_json_string_values():
    raw = (
        '{"event":"login","nested":{"password":"'
        + FAKE_PASS
        + '"},"note":"ok"}'
    )
    sanitized = sanitize_audit_details({"payload": raw})
    assert sanitized is not None
    assert FAKE_PASS not in sanitized["payload"]
    assert REDACTED_MARKER in sanitized["payload"]
    assert '"event": "login"' in sanitized["payload"] or '"event":"login"' in sanitized[
        "payload"
    ]
    assert "ok" in sanitized["payload"]


def test_handles_empty_unicode_numbers_and_nulls():
    assert redact_secrets_in_text("") == ""
    payload = {
        "empty": "",
        "count": 3,
        "flag": False,
        "nullable": None,
        "unicode": "Operación «éxito» — sin secretos",
        "list": [1, "sin secretos", {"ok": True}],
    }
    assert sanitize_audit_details(payload) == payload


def test_secret_assignment_without_key_suffix():
    text = f"config secret={FAKE_PASS} listo"
    out = redact_secrets_in_text(text)
    assert "config secret=" in out or "config " in out
    assert FAKE_PASS not in out
    assert REDACTED_MARKER in out
