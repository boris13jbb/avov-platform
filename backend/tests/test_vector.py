import uuid

import pytest
from fastapi.testclient import TestClient

from app.db.session import SessionLocal
from app.models.career import Career
from app.repositories.career_repository import CareerRepository
from app.services.embedding_service import (
    build_career_embedding_text,
    build_profile_search_text,
    text_to_embedding,
)


def _delete_career_by_id(career_id: int) -> None:
    session = SessionLocal()
    try:
        career = session.get(Career, career_id)
        if career:
            CareerRepository(session).delete(career)
    finally:
        session.close()


def _career_payload(**overrides) -> dict:
    unique = uuid.uuid4().hex[:6]
    base = {
        "name": f"Ingeniería Sistemas {unique}",
        "area": "Tecnología",
        "description": "Carrera orientada al desarrollo de software y sistemas informáticos.",
        "riasec_profile": "IRC",
        "duration": "4 años",
        "degree_type": "INGENIERIA",
        "institution_type": "AMBAS",
        "employment_field": "Desarrollo de software, TI, ciberseguridad",
        "status": "ACTIVE",
    }
    base.update(overrides)
    return base


@pytest.fixture
def vector_career_ids(client: TestClient, super_admin_headers: dict[str, str]):
    created_ids: list[int] = []
    payloads = [
        _career_payload(name="Medicina General Vector", riasec_profile="ISA"),
        _career_payload(name="Diseño Gráfico Vector", riasec_profile="AES"),
        _career_payload(name="Administración Empresarial Vector", riasec_profile="ESC"),
    ]
    for payload in payloads:
        response = client.post(
            "/api/v1/careers",
            headers=super_admin_headers,
            json=payload,
        )
        assert response.status_code == 200
        created_ids.append(response.json()["data"]["id"])

    yield created_ids

    for career_id in created_ids:
        _delete_career_by_id(career_id)


def test_rebuild_careers_requires_super_admin(
    client: TestClient,
    auth_headers: dict[str, str],
):
    response = client.post("/api/v1/vector/rebuild-careers", headers=auth_headers)
    assert response.status_code == 403


def test_rebuild_careers_as_super_admin(
    client: TestClient,
    super_admin_headers: dict[str, str],
    vector_career_ids,
):
    response = client.post(
        "/api/v1/vector/rebuild-careers",
        headers=super_admin_headers,
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["indexed"] >= len(vector_career_ids)
    assert data["vector_size"] >= 1


def test_search_careers_requires_auth(client: TestClient):
    response = client.post(
        "/api/v1/vector/search-careers",
        json={"riasec_profile": "RIA"},
    )
    assert response.status_code == 401


def test_search_careers_by_riasec_profile(
    client: TestClient,
    super_admin_headers: dict[str, str],
    auth_headers: dict[str, str],
    vector_career_ids,
):
    client.post("/api/v1/vector/rebuild-careers", headers=super_admin_headers)

    response = client.post(
        "/api/v1/vector/search-careers",
        headers=auth_headers,
        json={"riasec_profile": "ISA", "limit": 5},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["total"] >= 1
    assert any("ISA" in item["riasec_profile"] for item in data["items"])


def test_search_careers_requires_criteria(
    client: TestClient,
    auth_headers: dict[str, str],
):
    response = client.post(
        "/api/v1/vector/search-careers",
        headers=auth_headers,
        json={"limit": 5},
    )
    assert response.status_code == 422


def test_embedding_is_deterministic():
    first = text_to_embedding("Perfil vocacional RIA")
    second = text_to_embedding("Perfil vocacional RIA")
    assert first == second
    assert len(first) > 0


def test_build_profile_search_text_includes_riasec_labels():
    text = build_profile_search_text(riasec_profile="RIA")
    assert "RIA" in text
    assert "Realista" in text
    assert "Investigador" in text


def test_build_career_embedding_text_uses_career_fields():
    career = Career(
        name="Enfermería",
        area="Salud",
        description="Atención clínica y cuidado de pacientes.",
        riasec_profile="SIC",
        employment_field="Hospitales y clínicas",
    )
    text = build_career_embedding_text(career)
    assert "Enfermería" in text
    assert "Perfil SIC" in text
