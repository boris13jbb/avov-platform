"""Almacenamiento de informes PDF: local (dev) o GCS (Cloud Run)."""

from __future__ import annotations

import os
import re
from abc import ABC, abstractmethod
from functools import lru_cache
from pathlib import Path

_SAFE_FILENAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,120}$")

_BACKEND_LOCAL = "local"
_BACKEND_GCS = "gcs"
_ALLOWED_BACKENDS = frozenset({_BACKEND_LOCAL, _BACKEND_GCS})


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
    """Resuelve un nombre de archivo dentro del directorio local o lanza ValueError."""
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


def storage_object_name(filename: str) -> str:
    """Nombre relativo seguro para BD / claves de objeto (solo basename).

    No normaliza rutas: si el valor incluye separadores o ``..``, se rechaza.
    """
    if not is_safe_report_filename(filename):
        raise ValueError("Nombre de archivo de informe no permitido")
    return filename


class ReportBlobStore(ABC):
    """Lectura/escritura de bytes de informes por nombre de archivo seguro."""

    @abstractmethod
    def exists(self, filename: str) -> bool:
        raise NotImplementedError

    @abstractmethod
    def read_bytes(self, filename: str) -> bytes:
        raise NotImplementedError

    @abstractmethod
    def write_bytes(self, filename: str, content: bytes) -> str:
        """Persiste el contenido y devuelve el nombre relativo para la BD."""
        raise NotImplementedError

    @abstractmethod
    def delete(self, filename: str) -> None:
        raise NotImplementedError


class LocalReportBlobStore(ReportBlobStore):
    def exists(self, filename: str) -> bool:
        path = resolve_report_path(storage_object_name(filename))
        return path.is_file()

    def read_bytes(self, filename: str) -> bytes:
        return resolve_report_path(storage_object_name(filename)).read_bytes()

    def write_bytes(self, filename: str, content: bytes) -> str:
        name = storage_object_name(filename)
        path = resolve_report_path(name)
        path.write_bytes(content)
        return relative_report_path(path)

    def delete(self, filename: str) -> None:
        path = resolve_report_path(storage_object_name(filename))
        path.unlink(missing_ok=True)


class GcsReportBlobStore(ReportBlobStore):
    """Almacenamiento en un bucket de Cloud Storage (ADC / SA de Cloud Run)."""

    def __init__(self, bucket_name: str, prefix: str = "reports") -> None:
        if not bucket_name.strip():
            raise ValueError("AVOV_GCS_BUCKET es obligatorio con AVOV_REPORTS_BACKEND=gcs")
        try:
            from google.cloud import storage as gcs_storage
        except ImportError as exc:
            raise RuntimeError(
                "google-cloud-storage no está instalado; necesario para AVOV_REPORTS_BACKEND=gcs"
            ) from exc

        self._client = gcs_storage.Client()
        self._bucket = self._client.bucket(bucket_name.strip())
        cleaned = prefix.strip().strip("/")
        self._prefix = cleaned or "reports"

    def _blob(self, filename: str):
        name = storage_object_name(filename)
        object_path = f"{self._prefix}/{name}"
        return self._bucket.blob(object_path)

    def exists(self, filename: str) -> bool:
        return bool(self._blob(filename).exists())

    def read_bytes(self, filename: str) -> bytes:
        blob = self._blob(filename)
        if not blob.exists():
            raise FileNotFoundError(filename)
        return blob.download_as_bytes()

    def write_bytes(self, filename: str, content: bytes) -> str:
        name = storage_object_name(filename)
        blob = self._blob(name)
        blob.upload_from_string(content, content_type="application/pdf")
        return name

    def delete(self, filename: str) -> None:
        blob = self._blob(filename)
        if blob.exists():
            blob.delete()


def _reports_backend_from_env() -> str:
    raw = os.environ.get("AVOV_REPORTS_BACKEND", _BACKEND_LOCAL).strip().lower()
    if not raw:
        return _BACKEND_LOCAL
    if raw not in _ALLOWED_BACKENDS:
        raise ValueError(
            f"AVOV_REPORTS_BACKEND inválido: use 'local' o 'gcs' (recibido: {raw!r})"
        )
    return raw


@lru_cache
def get_report_blob_store() -> ReportBlobStore:
    """Factory cacheada. Limpiar con get_report_blob_store.cache_clear() en tests."""
    backend = _reports_backend_from_env()
    if backend == _BACKEND_GCS:
        bucket = os.environ.get("AVOV_GCS_BUCKET", "").strip()
        prefix = os.environ.get("AVOV_GCS_PREFIX", "reports").strip() or "reports"
        return GcsReportBlobStore(bucket_name=bucket, prefix=prefix)
    return LocalReportBlobStore()
