import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.enums import UserRole, UserStatus
from app.db.session import SessionLocal
from app.models.user import User
from app.repositories.user_repository import UserRepository


def _delete_user_by_id(user_id: int) -> None:
    session = SessionLocal()
    try:
        user = session.get(User, user_id)
        if user:
            UserRepository(session).delete(user)
    finally:
        session.close()


def _user_payload(institution_id: int | None = None, **overrides) -> dict:
    base = {
        "email": f"user_{uuid.uuid4().hex[:8]}@instituto.edu.co",
        "password": "Test1234!",
        "first_name": "María",
        "last_name": "Pérez",
        "role": "COUNSELOR",
        "institution_id": institution_id,
        "phone": "0998765432",
        "status": "ACTIVE",
    }
    base.update(overrides)
    return base


def test_list_users_forbidden_for_student(
    client: TestClient,
    auth_headers: dict[str, str],
):
    response = client.get("/api/v1/users", headers=auth_headers)
    assert response.status_code == 403


def test_list_users_as_super_admin(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    response = client.get("/api/v1/users", headers=super_admin_headers)
    assert response.status_code == 200
    data = response.json()["data"]
    assert "items" in data
    assert data["total"] >= 1


def test_list_users_scoped_for_institution_admin(
    client: TestClient,
    institution_admin_headers: dict[str, str],
    sample_institution,
    db: Session,
):
    from app.repositories.institution_repository import InstitutionRepository
    from app.schemas.institution import InstitutionCreate

    inst_repo = InstitutionRepository(db)
    user_repo = UserRepository(db)
    other_institution = inst_repo.create(
        InstitutionCreate(
            name="Institución Externa",
            code=f"EXT-{uuid.uuid4().hex[:6].upper()}",
            province="Guayas",
            city="Guayaquil",
        )
    )
    other_user = user_repo.create_raw(
        email=f"externo_{uuid.uuid4().hex[:6]}@instituto.edu.co",
        password="Test1234!",
        first_name="Externo",
        last_name="Usuario",
        role=UserRole.STUDENT,
        institution_id=other_institution.id,
    )
    try:
        response = client.get("/api/v1/users", headers=institution_admin_headers)
        assert response.status_code == 200
        items = response.json()["data"]["items"]
        item_ids = [item["id"] for item in items]
        assert other_user.id not in item_ids
        for item in items:
            assert item["institution_id"] == sample_institution.id
    finally:
        user_repo.delete(other_user)
        inst_repo.delete(other_institution)


def test_create_user_as_super_admin(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
    db: Session,
):
    payload = _user_payload(institution_id=sample_institution.id)
    response = client.post(
        "/api/v1/users",
        headers=super_admin_headers,
        json=payload,
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["email"] == payload["email"]
    assert data["role"] == "COUNSELOR"
    _delete_user_by_id(data["id"])


def test_create_user_as_institution_admin(
    client: TestClient,
    institution_admin_headers: dict[str, str],
    sample_institution,
    db: Session,
):
    payload = _user_payload(institution_id=sample_institution.id, role="STUDENT")
    response = client.post(
        "/api/v1/users",
        headers=institution_admin_headers,
        json=payload,
    )
    assert response.status_code == 200
    assert response.json()["data"]["institution_id"] == sample_institution.id
    _delete_user_by_id(response.json()["data"]["id"])


def test_create_super_admin_forbidden_for_institution_admin(
    client: TestClient,
    institution_admin_headers: dict[str, str],
):
    payload = _user_payload(role="SUPER_ADMIN", institution_id=None)
    response = client.post(
        "/api/v1/users",
        headers=institution_admin_headers,
        json=payload,
    )
    assert response.status_code == 403


def test_create_user_duplicate_email(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
    test_user,
):
    payload = _user_payload(
        email=test_user.email,
        institution_id=sample_institution.id,
    )
    response = client.post(
        "/api/v1/users",
        headers=super_admin_headers,
        json=payload,
    )
    assert response.status_code == 422


def test_get_user_as_super_admin(
    client: TestClient,
    super_admin_headers: dict[str, str],
    test_user,
):
    response = client.get(
        f"/api/v1/users/{test_user.id}",
        headers=super_admin_headers,
    )
    assert response.status_code == 200
    assert response.json()["data"]["id"] == test_user.id


def test_get_user_self(
    client: TestClient,
    auth_headers: dict[str, str],
    test_user,
):
    response = client.get(
        f"/api/v1/users/{test_user.id}",
        headers=auth_headers,
    )
    assert response.status_code == 200


def test_get_user_forbidden_for_other_student(
    client: TestClient,
    auth_headers: dict[str, str],
    db: Session,
):
    repo = UserRepository(db)
    other = repo.create_raw(
        email=f"otro_{uuid.uuid4().hex[:6]}@instituto.edu.co",
        password="Test1234!",
        first_name="Otro",
        last_name="Estudiante",
        role=UserRole.STUDENT,
    )
    try:
        response = client.get(
            f"/api/v1/users/{other.id}",
            headers=auth_headers,
        )
        assert response.status_code == 403
    finally:
        repo.delete(other)


def test_update_user_success(
    client: TestClient,
    super_admin_headers: dict[str, str],
    test_user,
):
    response = client.put(
        f"/api/v1/users/{test_user.id}",
        headers=super_admin_headers,
        json={"first_name": "NombreActualizado"},
    )
    assert response.status_code == 200
    assert response.json()["data"]["first_name"] == "NombreActualizado"


def test_update_user_status_success(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    payload = _user_payload(institution_id=sample_institution.id, role="STUDENT")
    create_response = client.post(
        "/api/v1/users",
        headers=super_admin_headers,
        json=payload,
    )
    assert create_response.status_code == 200
    user_id = create_response.json()["data"]["id"]

    response = client.patch(
        f"/api/v1/users/{user_id}/status",
        headers=super_admin_headers,
        json={"status": "INACTIVE"},
    )
    assert response.status_code == 200
    assert response.json()["data"]["status"] == "INACTIVE"
    _delete_user_by_id(user_id)


def test_cannot_change_own_status(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    me = client.get("/api/v1/auth/me", headers=super_admin_headers).json()["data"]
    response = client.patch(
        f"/api/v1/users/{me['id']}/status",
        headers=super_admin_headers,
        json={"status": "INACTIVE"},
    )
    assert response.status_code == 422
