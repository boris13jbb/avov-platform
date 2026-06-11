import uuid

from fastapi.testclient import TestClient

from app.db.session import SessionLocal
from app.models.career import Career
from app.repositories.career_repository import CareerRepository


def _delete_career_by_id(career_id: int) -> None:
    session = SessionLocal()
    try:
        career = session.get(Career, career_id)
        if career:
            CareerRepository(session).delete(career)
    finally:
        session.close()


def _career_payload(**overrides) -> dict:
    base = {
        "name": "Ingeniería en Sistemas",
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


def test_list_careers_requires_auth(client: TestClient):
    response = client.get("/api/v1/careers")
    assert response.status_code == 401


def test_list_careers_as_authenticated_user(
    client: TestClient,
    auth_headers: dict[str, str],
):
    response = client.get("/api/v1/careers", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()["data"]
    assert "items" in data
    assert "total" in data


def test_create_career_as_super_admin(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    payload = _career_payload(name=f"Carrera {uuid.uuid4().hex[:6]}")
    response = client.post(
        "/api/v1/careers",
        headers=super_admin_headers,
        json=payload,
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["riasec_profile"] == "IRC"
    _delete_career_by_id(data["id"])


def test_create_career_forbidden_for_student(
    client: TestClient,
    auth_headers: dict[str, str],
):
    response = client.post(
        "/api/v1/careers",
        headers=auth_headers,
        json=_career_payload(),
    )
    assert response.status_code == 403


def test_create_career_invalid_riasec(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    response = client.post(
        "/api/v1/careers",
        headers=super_admin_headers,
        json=_career_payload(riasec_profile="XYZ"),
    )
    assert response.status_code == 422


def test_get_career_success(
    client: TestClient,
    super_admin_headers: dict[str, str],
    auth_headers: dict[str, str],
):
    created = client.post(
        "/api/v1/careers",
        headers=super_admin_headers,
        json=_career_payload(name=f"Detalle {uuid.uuid4().hex[:6]}"),
    )
    career_id = created.json()["data"]["id"]

    response = client.get(
        f"/api/v1/careers/{career_id}",
        headers=auth_headers,
    )
    assert response.status_code == 200
    _delete_career_by_id(career_id)


def test_update_career_success(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    created = client.post(
        "/api/v1/careers",
        headers=super_admin_headers,
        json=_career_payload(name=f"Update {uuid.uuid4().hex[:6]}"),
    )
    career_id = created.json()["data"]["id"]

    response = client.put(
        f"/api/v1/careers/{career_id}",
        headers=super_admin_headers,
        json={"name": "Ingeniería en Software"},
    )
    assert response.status_code == 200
    assert response.json()["data"]["name"] == "Ingeniería en Software"
    _delete_career_by_id(career_id)


def test_create_career_reports_vector_sync_status(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    from app.services.qdrant_service import QdrantService

    response = client.post(
        "/api/v1/careers",
        headers=super_admin_headers,
        json=_career_payload(name=f"VectorSync {uuid.uuid4().hex[:6]}"),
    )
    assert response.status_code == 200
    body = response.json()
    assert "vector_synced" in body["data"]

    if QdrantService().is_available():
        assert body["data"]["vector_synced"] is True
        assert "vectorial" in body["message"].lower()
    else:
        assert body["data"]["vector_synced"] is False

    _delete_career_by_id(body["data"]["id"])


def test_update_career_reports_vector_sync_status(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    from app.services.qdrant_service import QdrantService

    created = client.post(
        "/api/v1/careers",
        headers=super_admin_headers,
        json=_career_payload(name=f"UpdateSync {uuid.uuid4().hex[:6]}"),
    )
    career_id = created.json()["data"]["id"]

    response = client.put(
        f"/api/v1/careers/{career_id}",
        headers=super_admin_headers,
        json={"description": "Descripción actualizada para prueba vectorial."},
    )
    assert response.status_code == 200
    body = response.json()
    assert "vector_synced" in body["data"]

    if QdrantService().is_available():
        assert body["data"]["vector_synced"] is True
    else:
        assert body["data"]["vector_synced"] is False

    _delete_career_by_id(career_id)


def test_delete_career_reports_vector_sync_status(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    from app.services.qdrant_service import QdrantService

    created = client.post(
        "/api/v1/careers",
        headers=super_admin_headers,
        json=_career_payload(name=f"DeleteSync {uuid.uuid4().hex[:6]}"),
    )
    career_id = created.json()["data"]["id"]

    response = client.delete(
        f"/api/v1/careers/{career_id}",
        headers=super_admin_headers,
    )
    assert response.status_code == 200
    body = response.json()
    assert "vector_synced" in body["data"]

    if QdrantService().is_available():
        assert body["data"]["vector_synced"] is True
    else:
        assert body["data"]["vector_synced"] is False

    _delete_career_by_id(career_id)


def test_delete_career_soft_delete(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    created = client.post(
        "/api/v1/careers",
        headers=super_admin_headers,
        json=_career_payload(name=f"Delete {uuid.uuid4().hex[:6]}"),
    )
    career_id = created.json()["data"]["id"]

    response = client.delete(
        f"/api/v1/careers/{career_id}",
        headers=super_admin_headers,
    )
    assert response.status_code == 200
    assert response.json()["data"]["status"] == "INACTIVE"

    get_response = client.get(
        f"/api/v1/careers/{career_id}",
        headers=super_admin_headers,
    )
    assert get_response.json()["data"]["status"] == "INACTIVE"
    _delete_career_by_id(career_id)


def test_filter_careers_by_area(
    client: TestClient,
    super_admin_headers: dict[str, str],
    auth_headers: dict[str, str],
):
    unique_area = f"Area{uuid.uuid4().hex[:4]}"
    created = client.post(
        "/api/v1/careers",
        headers=super_admin_headers,
        json=_career_payload(
            name=f"Filtro {uuid.uuid4().hex[:6]}",
            area=unique_area,
        ),
    )
    career_id = created.json()["data"]["id"]

    response = client.get(
        "/api/v1/careers",
        headers=auth_headers,
        params={"area": unique_area},
    )
    assert response.status_code == 200
    items = response.json()["data"]["items"]
    assert any(item["id"] == career_id for item in items)
    _delete_career_by_id(career_id)


def test_get_career_not_found(
    client: TestClient,
    auth_headers: dict[str, str],
):
    response = client.get("/api/v1/careers/999999", headers=auth_headers)
    assert response.status_code == 404
