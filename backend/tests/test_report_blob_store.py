"""Pruebas del almacén de informes (local y GCS mockeado)."""

from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from app.utils.file_storage import (
    GcsReportBlobStore,
    LocalReportBlobStore,
    get_report_blob_store,
    storage_object_name,
)


@pytest.fixture(autouse=True)
def _clear_store_cache():
    get_report_blob_store.cache_clear()
    yield
    get_report_blob_store.cache_clear()


def test_local_store_roundtrip(tmp_path, monkeypatch):
    monkeypatch.setenv("AVOV_REPORTS_DIR", str(tmp_path))
    monkeypatch.setenv("AVOV_REPORTS_BACKEND", "local")
    store = LocalReportBlobStore()
    name = "AVOV-S1-STORETEST1.pdf"
    relative = store.write_bytes(name, b"%PDF-1.4 local")
    assert relative == name
    assert store.exists(name) is True
    assert store.read_bytes(name) == b"%PDF-1.4 local"
    store.delete(name)
    assert store.exists(name) is False


def test_factory_defaults_to_local(tmp_path, monkeypatch):
    monkeypatch.setenv("AVOV_REPORTS_DIR", str(tmp_path))
    monkeypatch.delenv("AVOV_REPORTS_BACKEND", raising=False)
    store = get_report_blob_store()
    assert isinstance(store, LocalReportBlobStore)


def test_factory_rejects_unknown_backend(monkeypatch):
    monkeypatch.setenv("AVOV_REPORTS_BACKEND", "s3")
    with pytest.raises(ValueError, match="AVOV_REPORTS_BACKEND"):
        get_report_blob_store()


def test_storage_object_name_rejects_traversal():
    with pytest.raises(ValueError):
        storage_object_name("../x.pdf")


def test_gcs_store_uses_bucket_prefix():
    fake_blob = MagicMock()
    fake_blob.exists.return_value = True
    fake_blob.download_as_bytes.return_value = b"%PDF-gcs"
    fake_bucket = MagicMock()
    fake_bucket.blob.return_value = fake_blob
    fake_client = MagicMock()
    fake_client.bucket.return_value = fake_bucket

    with patch("google.cloud.storage.Client", return_value=fake_client):
        store = GcsReportBlobStore(bucket_name="avov-reports-test", prefix="reports")
        assert store.exists("AVOV-S2-GCSFILE01.pdf") is True
        assert store.read_bytes("AVOV-S2-GCSFILE01.pdf") == b"%PDF-gcs"
        store.write_bytes("AVOV-S2-GCSFILE01.pdf", b"%PDF-new")
        fake_blob.upload_from_string.assert_called_once()
        fake_bucket.blob.assert_called_with("reports/AVOV-S2-GCSFILE01.pdf")


def test_gcs_requires_bucket_name():
    with pytest.raises(ValueError, match="AVOV_GCS_BUCKET"):
        GcsReportBlobStore(bucket_name="  ")
