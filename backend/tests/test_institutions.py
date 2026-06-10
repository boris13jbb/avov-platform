import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.repositories.institution_repository import InstitutionRepository
from app.schemas.institution import InstitutionCreate


def _institution_payload(**overrides) -> dict:
    base = {
        "name": "Colegio Nacional AVOV",
        "code": f"CN-{uuid.uuid4().hex[:6].upper()}",
        "province": "Guayas",
        "city": "Guayaquil",
        "address": "Calle Principal 100",
        "phone": "042123456",
        "email": "info@colegio.edu.co",
        "status": "ACTIVE",
    }
    base.update(overrides)
    return base


def test_list_institutions_requires_super_admin(
    client: TestClient,
    auth_headers: dict[str, str],
):
    response = client.get("/api/v1/institutions", headers=auth_headers)
    assert response.status_code == 403


def test_list_institutions_success(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    response = client.get("/api/v1/institutions", headers=super_admin_headers)
    assert response.status_code == 200
    data = response.json()["data"]
    assert "items" in data
    assert data["total"] >= 1
    assert data["page"] == 1


def test_create_institution_success(
    client: TestClient,
    super_admin_headers: dict[str, str],
    db: Session,
):
    payload = _institution_payload()
    response = client.post(
        "/api/v1/institutions",
        headers=super_admin_headers,
        json=payload,
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["name"] == payload["name"]
    assert data["code"] == payload["code"].upper()

    repo = InstitutionRepository(db)
    created = repo.get_by_id(data["id"])
    assert created is not None
    repo.delete(created)


def test_create_institution_duplicate_code(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    response = client.post(
        "/api/v1/institutions",
        headers=super_admin_headers,
        json=_institution_payload(code=sample_institution.code),
    )
    assert response.status_code == 422
    assert "código" in response.json()["message"].lower()


def test_create_institution_invalid_phone(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    response = client.post(
        "/api/v1/institutions",
        headers=super_admin_headers,
        json=_institution_payload(phone="abc"),
    )
    assert response.status_code == 422


def test_get_institution_as_super_admin(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    response = client.get(
        f"/api/v1/institutions/{sample_institution.id}",
        headers=super_admin_headers,
    )
    assert response.status_code == 200
    assert response.json()["data"]["id"] == sample_institution.id


def test_get_institution_as_institution_admin_own(
    client: TestClient,
    institution_admin_headers: dict[str, str],
    sample_institution,
):
    response = client.get(
        f"/api/v1/institutions/{sample_institution.id}",
        headers=institution_admin_headers,
    )
    assert response.status_code == 200


def test_get_institution_as_institution_admin_other_forbidden(
    client: TestClient,
    institution_admin_headers: dict[str, str],
    db: Session,
):
    repo = InstitutionRepository(db)
    other = repo.create(
        InstitutionCreate(
            name="Otra Institución",
            code=f"OTR-{uuid.uuid4().hex[:6].upper()}",
            province="Azuay",
            city="Cuenca",
        )
    )
    try:
        response = client.get(
            f"/api/v1/institutions/{other.id}",
            headers=institution_admin_headers,
        )
        assert response.status_code == 403
    finally:
        repo.delete(other)


def test_update_institution_success(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    response = client.put(
        f"/api/v1/institutions/{sample_institution.id}",
        headers=super_admin_headers,
        json={"name": "Instituto Actualizado"},
    )
    assert response.status_code == 200
    assert response.json()["data"]["name"] == "Instituto Actualizado"


def test_delete_institution_soft_delete(
    client: TestClient,
    super_admin_headers: dict[str, str],
    db: Session,
):
    repo = InstitutionRepository(db)
    institution = repo.create(
        InstitutionCreate(
            name="Institución Temporal",
            code=f"TMP-{uuid.uuid4().hex[:6].upper()}",
            province="Manabí",
            city="Portoviejo",
        )
    )
    response = client.delete(
        f"/api/v1/institutions/{institution.id}",
        headers=super_admin_headers,
    )
    assert response.status_code == 200
    assert response.json()["data"]["status"] == "INACTIVE"

    get_response = client.get(
        f"/api/v1/institutions/{institution.id}",
        headers=super_admin_headers,
    )
    assert get_response.status_code == 200
    assert get_response.json()["data"]["status"] == "INACTIVE"

    repo.delete(institution)


def test_search_institutions(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    response = client.get(
        "/api/v1/institutions",
        headers=super_admin_headers,
        params={"search": "Técnico Demo"},
    )
    assert response.status_code == 200
    items = response.json()["data"]["items"]
    assert any(item["id"] == sample_institution.id for item in items)


def test_get_institution_not_found(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    response = client.get(
        "/api/v1/institutions/999999",
        headers=super_admin_headers,
    )
    assert response.status_code == 404
