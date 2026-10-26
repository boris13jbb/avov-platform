"""Sanitización de metadatos de auditoría antes de persistir o exponerlos.

Evita que tokens, contraseñas, claves API y campos equivalentes lleguen a las
respuestas de la API (y reduce el riesgo de almacenarlos en nuevos registros).

Campos y patrones considerados sensibles (tras normalizar el nombre de la clave:
minúsculas, sin acentos, sin guiones/guiones bajos/espacios):

- Credenciales: password, passwd, pwd, contrasena, clave, credentials
- Secretos / claves: secret, clientsecret, apikey, apisecret, privatekey
- Tokens de sesión: token, jwt, bearer, accesstoken, refreshtoken, idtoken
- Cabeceras / cookies: authorization, cookie, setcookie, session, sessionid
- Hashes de contraseña: passwordhash, passworddigest
- Fragmentos: cualquier clave cuyo nombre normalizado contenga password, passwd,
  secret, token, apikey, authorization, cookie, privatekey o credential

Los valores sensibles se sustituyen por el marcador uniforme ``[REDACTED]``.
La sanitización no muta la estructura original y, ante error, no reexpone datos.
"""

from __future__ import annotations

import re
import unicodedata
from collections.abc import Mapping, Sequence
from typing import Any

REDACTED_MARKER = "[REDACTED]"

# Claves exactas tras normalización (sin separadores ni acentos).
_SENSITIVE_KEYS = frozenset(
    {
        "password",
        "passwd",
        "pwd",
        "contrasena",
        "clave",
        "secret",
        "token",
        "jwt",
        "bearer",
        "apikey",
        "apisecret",
        "authorization",
        "cookie",
        "setcookie",
        "session",
        "sessionid",
        "sessionkey",
        "accesstoken",
        "refreshtoken",
        "idtoken",
        "clientsecret",
        "privatekey",
        "passwordhash",
        "passworddigest",
        "credentials",
        "credential",
    }
)

# Si el nombre normalizado contiene alguno de estos fragmentos, se redacta.
_SENSITIVE_FRAGMENTS = (
    "password",
    "passwd",
    "secret",
    "token",
    "apikey",
    "authorization",
    "cookie",
    "privatekey",
    "credential",
)

_NON_ALNUM = re.compile(r"[^a-z0-9]")


def normalize_audit_key(key: object) -> str:
    """Normaliza el nombre de una clave para comparación estable."""
    if not isinstance(key, str):
        return ""
    decomposed = unicodedata.normalize("NFKD", key)
    without_marks = "".join(
        char for char in decomposed if not unicodedata.combining(char)
    )
    return _NON_ALNUM.sub("", without_marks.lower())


def is_sensitive_audit_key(key: object) -> bool:
    """Indica si el nombre de la clave debe tratarse como sensible."""
    normalized = normalize_audit_key(key)
    if not normalized:
        return False
    if normalized in _SENSITIVE_KEYS:
        return True
    return any(fragment in normalized for fragment in _SENSITIVE_FRAGMENTS)


def sanitize_audit_details(details: Any) -> dict[str, Any] | None:
    """Devuelve una copia sanitizada de ``details`` o ``None``.

    Ante cualquier fallo de sanitización, retorna un marcador seguro y nunca el
    valor original sin filtrar.
    """
    if details is None:
        return None
    try:
        sanitized = _sanitize_value(details)
        if sanitized is None:
            return None
        if isinstance(sanitized, dict):
            return sanitized
        # El contrato de auditoría espera un objeto JSON; no reexponer crudo.
        return {"value": REDACTED_MARKER}
    except Exception:
        return {"_sanitization": REDACTED_MARKER}


def _sanitize_value(value: Any) -> Any:
    if value is None or isinstance(value, (bool, int, float, str)):
        return value

    if isinstance(value, Mapping):
        result: dict[str, Any] = {}
        for raw_key, raw_item in value.items():
            key = str(raw_key)
            if is_sensitive_audit_key(key):
                result[key] = REDACTED_MARKER
            else:
                result[key] = _sanitize_value(raw_item)
        return result

    if isinstance(value, Sequence) and not isinstance(value, (str, bytes, bytearray)):
        return [_sanitize_value(item) for item in value]

    # Tipos no JSON habituales: no intentar serializar contenido desconocido.
    return REDACTED_MARKER
