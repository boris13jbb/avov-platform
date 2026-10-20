"""Fail-fast isolation for destructive pytest fixtures.

Only the database name ``avov_test`` is authorized. Validation uses URL parsing
only — no network connection is opened.
"""

from __future__ import annotations

from urllib.parse import unquote, urlparse

AUTHORIZED_TEST_DATABASE_NAME = "avov_test"


class UnauthorizedTestDatabaseError(RuntimeError):
    """Raised when pytest must not run destructive fixtures."""


def resolve_database_name(database_url: str) -> str:
    """Return the MySQL schema name from a SQLAlchemy URL, or raise.

    Does not connect. Fails closed if the name cannot be determined safely.
    """
    if database_url is None:
        raise UnauthorizedTestDatabaseError(
            "No se puede verificar la base de datos de prueba: "
            "DATABASE_URL está ausente."
        )
    raw = database_url.strip()
    if not raw:
        raise UnauthorizedTestDatabaseError(
            "No se puede verificar la base de datos de prueba: "
            "DATABASE_URL está vacía."
        )

    parsed = urlparse(raw)
    if not parsed.scheme:
        raise UnauthorizedTestDatabaseError(
            "No se puede verificar la base de datos de prueba: "
            "DATABASE_URL no tiene un esquema reconocible."
        )

    # mysql+pymysql://user:pass@host:3307/avov_test → path "/avov_test"
    path = unquote(parsed.path or "").strip()
    if not path or path == "/":
        raise UnauthorizedTestDatabaseError(
            "No se puede verificar la base de datos de prueba: "
            "DATABASE_URL no incluye el nombre de la base."
        )

    name = path.lstrip("/").split("/")[0].strip()
    if not name or "?" in name or "@" in name:
        raise UnauthorizedTestDatabaseError(
            "No se puede verificar la base de datos de prueba: "
            "el nombre de la base no es verificable."
        )
    return name


def assert_authorized_test_database(database_url: str) -> None:
    """Abort unless the configured database name is exactly ``avov_test``.

    Error messages never include credentials or the full URL.
    """
    name = resolve_database_name(database_url)
    if name != AUTHORIZED_TEST_DATABASE_NAME:
        raise UnauthorizedTestDatabaseError(
            "Las pruebas destructivas de AVOV solo pueden ejecutarse contra "
            f"la base «{AUTHORIZED_TEST_DATABASE_NAME}». "
            f"Base detectada: «{name}». "
            "Corrige DATABASE_URL (sin usar avov_db ni otras bases) "
            "antes de volver a lanzar pytest."
        )
