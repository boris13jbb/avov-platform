"""Preflight: confirma que DATABASE_URL apunta solo a avov_test.

Uso (desde backend/, con DATABASE_URL ya fijada en el entorno):
  .venv\\Scripts\\python.exe scripts/assert_e2e_database.py

No imprime la URL ni credenciales. Solo el nombre de schema y un SELECT DATABASE().
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from sqlalchemy import create_engine, text  # noqa: E402

from tests.db_isolation import (  # noqa: E402
    AUTHORIZED_TEST_DATABASE_NAME,
    assert_authorized_test_database,
    resolve_database_name,
)


def main() -> int:
    url = os.environ.get("DATABASE_URL")
    if not url:
        print("ERROR: DATABASE_URL ausente.", file=sys.stderr)
        return 2

    assert_authorized_test_database(url)
    schema = resolve_database_name(url)
    if schema != AUTHORIZED_TEST_DATABASE_NAME:
        print(f"ERROR: schema inesperado: {schema}", file=sys.stderr)
        return 3

    engine = create_engine(url)
    try:
        with engine.connect() as connection:
            active = connection.execute(text("SELECT DATABASE()")).scalar()
    finally:
        engine.dispose()

    if active != AUTHORIZED_TEST_DATABASE_NAME:
        print(
            f"ERROR: SELECT DATABASE() devolvió «{active}», "
            f"se esperaba «{AUTHORIZED_TEST_DATABASE_NAME}».",
            file=sys.stderr,
        )
        return 4

    print(f"OK schema={schema} active={active}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
