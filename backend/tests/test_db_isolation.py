"""Regresión de la guardia fail-fast (sin conectar a MySQL)."""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

import pytest

from tests.db_isolation import (
    AUTHORIZED_TEST_DATABASE_NAME,
    UnauthorizedTestDatabaseError,
    assert_authorized_test_database,
    resolve_database_name,
)

# Credenciales ficticias solo para formar URLs de prueba; no son secretos reales.
_FAKE = "mysql+pymysql://qa_user:qa_pass_not_real@127.0.0.1:3307"
_BACKEND_ROOT = Path(__file__).resolve().parents[1]


def test_accepts_avov_test_database_name():
    url = f"{_FAKE}/{AUTHORIZED_TEST_DATABASE_NAME}"
    assert resolve_database_name(url) == AUTHORIZED_TEST_DATABASE_NAME
    assert_authorized_test_database(url)


def test_accepts_avov_test_with_query_params():
    url = f"{_FAKE}/{AUTHORIZED_TEST_DATABASE_NAME}?charset=utf8mb4"
    assert resolve_database_name(url) == AUTHORIZED_TEST_DATABASE_NAME
    assert_authorized_test_database(url)


def test_rejects_avov_db_before_any_write():
    url = f"{_FAKE}/avov_db"
    with pytest.raises(UnauthorizedTestDatabaseError) as exc:
        assert_authorized_test_database(url)
    message = str(exc.value)
    assert AUTHORIZED_TEST_DATABASE_NAME in message
    assert "avov_db" in message
    assert "qa_pass_not_real" not in message
    assert "qa_user" not in message
    assert "127.0.0.1" not in message
    assert "mysql+pymysql" not in message


def test_rejects_unknown_database_name():
    url = f"{_FAKE}/production_copy"
    with pytest.raises(UnauthorizedTestDatabaseError) as exc:
        assert_authorized_test_database(url)
    assert "production_copy" in str(exc.value)
    assert "qa_pass_not_real" not in str(exc.value)


@pytest.mark.parametrize(
    "url",
    [
        None,
        "",
        "   ",
        "not-a-url",
        "mysql+pymysql://qa_user:qa_pass_not_real@127.0.0.1:3307",
        "mysql+pymysql://qa_user:qa_pass_not_real@127.0.0.1:3307/",
    ],
)
def test_rejects_missing_incomplete_or_unverifiable(url):
    with pytest.raises(UnauthorizedTestDatabaseError) as exc:
        assert_authorized_test_database(url)  # type: ignore[arg-type]
    message = str(exc.value)
    assert "qa_pass_not_real" not in message
    assert not re.search(r"://[^@]+@", message)


def test_error_messages_never_include_full_url_or_credentials():
    url = (
        "mysql+pymysql://secret_user:SuperSecret!Pass@db.example.com:3307/avov_db"
    )
    with pytest.raises(UnauthorizedTestDatabaseError) as exc:
        assert_authorized_test_database(url)
    message = str(exc.value)
    assert "SuperSecret!Pass" not in message
    assert "secret_user" not in message
    assert "db.example.com" not in message
    assert "mysql+pymysql://" not in message
    assert AUTHORIZED_TEST_DATABASE_NAME in message


def test_conftest_does_not_import_engine_at_module_level():
    """Evita create_engine antes de pytest_configure."""
    source = Path(__file__).resolve().with_name("conftest.py").read_text(
        encoding="utf-8"
    )
    preamble = source.split("def pytest_configure", 1)[0]
    assert "from app.main import app" not in preamble
    assert "from app.db.session import" not in preamble
    assert "pytest_configure" in source
    assert "pytest_collection_finish" not in source
    assert "_is_isolation_only_session" not in source
    assert "def _app():" in source
    assert "from app.main import app" in source.split("def _app():", 1)[1][:120]


def test_pytest_aborts_on_avov_db_before_create_engine():
    """Subproceso: con schema avov_db la guardia falla y create_engine no se llama."""
    script = r"""
import sys
import sqlalchemy

def _forbidden_create_engine(*args, **kwargs):
    raise AssertionError("create_engine_invoked_before_guard")

sqlalchemy.create_engine = _forbidden_create_engine

from app.core.config import get_settings
get_settings.cache_clear()
from tests.db_isolation import (
    UnauthorizedTestDatabaseError,
    assert_authorized_test_database,
)
try:
    assert_authorized_test_database(get_settings().database_url)
except UnauthorizedTestDatabaseError as exc:
    text = str(exc)
    assert "avov_db" in text
    assert "not_a_real_secret" not in text
    assert "nobody" not in text
    sys.exit(0)
sys.exit(2)
"""
    env = os.environ.copy()
    env["DATABASE_URL"] = (
        "mysql+pymysql://nobody:not_a_real_secret@127.0.0.1:3307/avov_db"
    )
    env["PYTHONPATH"] = str(_BACKEND_ROOT)
    completed = subprocess.run(
        [sys.executable, "-c", script],
        cwd=str(_BACKEND_ROOT),
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    assert completed.returncode == 0, completed.stdout + completed.stderr
    assert "create_engine_invoked_before_guard" not in completed.stderr
    assert "not_a_real_secret" not in completed.stdout
    assert "not_a_real_secret" not in completed.stderr


def test_pytest_configure_rejects_avov_db_without_loading_session_module():
    """pytest con avov_db aborta en configure antes de coleccionar tests de datos."""
    env = os.environ.copy()
    env["DATABASE_URL"] = (
        "mysql+pymysql://nobody:not_a_real_secret@127.0.0.1:3307/avov_db"
    )
    env["PYTHONPATH"] = str(_BACKEND_ROOT)
    completed = subprocess.run(
        [
            sys.executable,
            "-m",
            "pytest",
            "tests/test_health.py",
            "-q",
            "--collect-only",
        ],
        cwd=str(_BACKEND_ROOT),
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    combined = completed.stdout + completed.stderr
    assert completed.returncode != 0
    assert "UnauthorizedTestDatabaseError" in combined
    assert "avov_db" in combined
    assert "not_a_real_secret" not in combined
    assert "nobody" not in combined
