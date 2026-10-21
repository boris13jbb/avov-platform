"""Almacenamiento de informes PDF bajo un directorio controlado."""

from __future__ import annotations

import os
import re
from pathlib import Path

_SAFE_FILENAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,120}$")


def get_reports_dir() -> Path:
    """Directorio autorizado de reportes (absoluto, sin seguir escapes)."""
    override = os.environ.get("AVOV_REPORTS_DIR", "").strip()
    if override:
        return Path(override).expanduser().resolve()
    return (Path.cwd() / "storage" / "reports").resolve()


# Compatibilidad con imports existentes.
REPORTS_DIR = Path("storage/reports")


def ensure_reports_directory() -> Path:
    directory = get_reports_dir()
    directory.mkdir(parents=True, exist_ok=True)
    return directory


def is_safe_report_filename(filename: str) -> bool:
    if not filename or "/" in filename or "\\" in filename or ".." in filename:
        return False
    return bool(_SAFE_FILENAME.fullmatch(filename))


def resolve_report_path(filename: str) -> Path:
    """Resuelve un nombre de archivo dentro de REPORTS_DIR o lanza ValueError."""
    if not is_safe_report_filename(filename):
        raise ValueError("Nombre de archivo de informe no permitido")

    base = ensure_reports_directory()
    candidate = (base / filename).resolve()
    try:
        candidate.relative_to(base)
    except ValueError as exc:
        raise ValueError("La ruta del informe sale del directorio autorizado") from exc

    if candidate.is_symlink():
        raise ValueError("No se permiten enlaces simbólicos en informes")

    return candidate


def relative_report_path(absolute: Path) -> str:
    """Guarda en BD solo el nombre de archivo, nunca una ruta absoluta."""
    name = absolute.name
    if not is_safe_report_filename(name):
        raise ValueError("Nombre de archivo de informe no permitido")
    return name
