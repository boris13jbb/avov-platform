"""Sanitización de metadatos de auditoría antes de persistir o exponerlos.

Evita que tokens, contraseñas, claves API y campos equivalentes lleguen a las
respuestas de la API (y reduce el riesgo de almacenarlos en nuevos registros).

## Capa 1 — nombres de clave

Tras normalizar el nombre (minúsculas, sin acentos, sin guiones/guiones bajos):

- Credenciales: password, passwd, pwd, contrasena, clave, credentials
- Secretos / claves: secret, clientsecret, apikey, apisecret, privatekey
- Tokens de sesión: token, jwt, bearer, accesstoken, refreshtoken, idtoken
- Cabeceras / cookies: authorization, cookie, setcookie, session, sessionid
- Hashes de contraseña: passwordhash, passworddigest
- Fragmentos: password, passwd, secret, token, apikey, authorization, cookie,
  privatekey, credential

Las claves sensibles se sustituyen por el marcador uniforme ``[REDACTED]``.

## Capa 2 — secretos incrustados en texto

Aunque la clave sea genérica (``message``, ``description``, ``error``, etc.),
se redactan fragmentos reconocibles dentro de cadenas:

- Cabeceras ``Authorization: Bearer|Basic …``
- Tokens sueltos ``Bearer …`` con valor de longitud mínima
- Asignaciones ``access_token|refresh_token|id_token|password|passwd|
  client_secret|api_key|apikey|secret_key|secret|pwd`` con ``=`` o ``:``
- Cabeceras ``Cookie`` / ``Set-Cookie``
- Bloques PEM ``BEGIN … PRIVATE KEY``
- Credenciales en URL (``scheme://usuario:secreto@host``)
- Parámetros de consulta sensibles (``?api_key=…``, ``&token=…``, etc.)
- Cadenas JSON embebidas: se reparsean y aplican ambas capas

Se conserva el texto contextual no sensible cuando es seguro. Menciones de
palabras como ``token`` o ``password`` sin valor asociado no se redactan.

## Limitaciones

- No identifica todos los secretos posibles (heurística por patrones; no es
  un detector completo de credenciales).
- Casos ambiguos como ``password=ok`` o tokens muy cortos pueden redactarse.
- Textos mayores que el límite de escaneo se ocultan por completo (fail-safe).
- No elimina secretos ya persistidos en almacenamiento histórico.
- Formatos propietarios o ofuscados pueden escapar a la detección.

La sanitización no muta la estructura original y, ante error, no reexpone datos.
"""

from __future__ import annotations

import json
import re
import unicodedata
from collections.abc import Mapping, Sequence
from typing import Any

REDACTED_MARKER = "[REDACTED]"

# Límite fail-safe: por encima no se escanea; se oculta el valor completo.
_MAX_TEXT_SCAN_CHARS = 256_000

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

# Patrones de secretos en texto (específicos; el secreto capturado se sustituye).
_ASSIGNMENT_NAMES = (
    r"access[_-]?token|refresh[_-]?token|id[_-]?token|"
    r"client[_-]?secret|api[_-]?key|apikey|secret[_-]?key|secret|"
    r"password|passwd|pwd"
)

_QUERY_SECRET_NAMES = (
    r"access[_-]?token|refresh[_-]?token|id[_-]?token|"
    r"api[_-]?key|apikey|token|password|passwd|secret|client[_-]?secret"
)

_TEXT_SECRET_PATTERNS: tuple[re.Pattern[str], ...] = (
    # Authorization: Bearer|Basic <valor>
    re.compile(
        r"(?i)(Authorization\s*:\s*(?:Bearer|Basic)\s+)\S+",
    ),
    # Bearer <token> suelto (mín. 8 caracteres para reducir falsos positivos)
    re.compile(
        r"(?i)(?<![\w-])(Bearer\s+)([A-Za-z0-9\-._~+/]{8,}={0,2})",
    ),
    # nombre=valor o nombre: valor (no atraviesa &/# de query strings)
    re.compile(
        rf"(?i)(\b(?:{_ASSIGNMENT_NAMES})\s*[:=]\s*)([^\s,;\"'&#?]+)",
    ),
    # scheme://usuario:secreto@host (incluye redis://:pass@ y mysql+pymysql://…)
    re.compile(
        r"(?i)((?:[a-z][a-z0-9+.-]*://)(?:[^/@:\s]+)?:)([^@/\s]+)(@)",
    ),
    # Parámetros de consulta sensibles
    re.compile(
        rf"(?i)([?&](?:{_QUERY_SECRET_NAMES})=)([^&\s#]+)",
    ),
    # Cookie / Set-Cookie: <resto de la línea>
    re.compile(
        r"(?i)((?:Set-)?Cookie\s*:\s*)([^\r\n]+)",
    ),
    # Bloque PEM de clave privada
    re.compile(
        r"-----BEGIN(?:[ A-Z]+)? PRIVATE KEY-----"
        r".*?"
        r"-----END(?:[ A-Z]+)? PRIVATE KEY-----",
        re.DOTALL,
    ),
)


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


def redact_secrets_in_text(text: str) -> str:
    """Redacta secretos reconocibles dentro de una cadena, conservando contexto.

    Si el texto supera el límite de escaneo, se sustituye por completo (fail-safe)
    en lugar de devolver el original sin filtrar. Las cadenas JSON se reparsean
    para aplicar también la redacción por nombre de clave.
    """
    if not text:
        return text
    if len(text) > _MAX_TEXT_SCAN_CHARS:
        return REDACTED_MARKER

    json_sanitized = _try_sanitize_embedded_json(text)
    if json_sanitized is not None:
        return json_sanitized

    return _apply_text_secret_patterns(text)


def _try_sanitize_embedded_json(text: str) -> str | None:
    """Si ``text`` es JSON objeto/lista, sanitiza la estructura y la re-serializa."""
    stripped = text.strip()
    if not stripped or stripped[0] not in "{[":
        return None
    try:
        parsed = json.loads(stripped)
    except (TypeError, ValueError, RecursionError):
        return None
    if not isinstance(parsed, (dict, list)):
        return None
    sanitized = _sanitize_value(parsed)
    try:
        return json.dumps(sanitized, ensure_ascii=False)
    except (TypeError, ValueError):
        return REDACTED_MARKER


def _apply_text_secret_patterns(text: str) -> str:
    redacted = text
    for pattern in _TEXT_SECRET_PATTERNS:

        def _replace(match: re.Match[str], *, groups: int = pattern.groups) -> str:
            if groups >= 3:
                return f"{match.group(1)}{REDACTED_MARKER}{match.group(3)}"
            if groups >= 1:
                return f"{match.group(1)}{REDACTED_MARKER}"
            return REDACTED_MARKER

        redacted = pattern.sub(_replace, redacted)
    return redacted


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
    if value is None or isinstance(value, (bool, int, float)):
        return value

    if isinstance(value, str):
        return redact_secrets_in_text(value)

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
