"""Pruebas unitarias de rutas seguras de informes (sin BD)."""

from __future__ import annotations

import pytest

from app.utils.file_storage import (
    is_safe_report_filename,
    relative_report_path,
    resolve_report_path,
)


def test_rejects_path_traversal_names():
    assert is_safe_report_filename("../secret.pdf") is False
    assert is_safe_report_filename("..\\secret.pdf") is False
    assert is_safe_report_filename("/etc/passwd") is False
    assert is_safe_report_filename("a/b.pdf") is False
    assert is_safe_report_filename("") is False


def test_accepts_safe_filenames():
    assert is_safe_report_filename("AVOV-S1-ABCDEF1234.pdf") is True
    assert is_safe_report_filename("informe.pdf") is True


def test_resolve_stays_inside_reports_dir(tmp_path, monkeypatch):
    monkeypatch.setenv("AVOV_REPORTS_DIR", str(tmp_path))
    path = resolve_report_path("AVOV-S9-TESTCODE01.pdf")
    assert path.parent == tmp_path.resolve()
    assert path.name == "AVOV-S9-TESTCODE01.pdf"


def test_resolve_rejects_traversal(tmp_path, monkeypatch):
    monkeypatch.setenv("AVOV_REPORTS_DIR", str(tmp_path))
    with pytest.raises(ValueError):
        resolve_report_path("../escape.pdf")


def test_relative_report_path_keeps_basename(tmp_path, monkeypatch):
    monkeypatch.setenv("AVOV_REPORTS_DIR", str(tmp_path))
    absolute = resolve_report_path("OK-REPORT-CODE1.pdf")
    assert relative_report_path(absolute) == "OK-REPORT-CODE1.pdf"
