import uuid
from datetime import date

import pytest
from fastapi.testclient import TestClient

from app.core.enums import AssignmentStatus
from app.db.session import SessionLocal
from app.models.student import CounselorAssignment, Student
from app.models.user import User
from app.repositories.student_repository import StudentRepository
from app.repositories.user_repository import UserRepository


def _delete_student_by_id(student_id: int) -> None:
    session = SessionLocal()
    try:
        student = session.get(Student, student_id)
        if student:
            StudentRepository(session).delete(student)
    finally:
        session.close()


def _student_payload(institution_id: int, **overrides) -> dict:
    unique = uuid.uuid4().hex[:8].upper()
    base = {
        "institution_id": institution_id,
        "user": {
            "email": f"estudiante_{unique.lower()}@instituto.edu.co",
            "password": "Estud1234!",
            "first_name": "Carlos",
            "last_name": "Mendoza",
            "phone": "0991112233",
        },
        "identification": f"ID-{unique}",
        "birth_date": "2008-05-15",
        "gender": "MALE",
        "grade": "10",
        "parallel": "A",
        "representative_name": "María Mendoza",
        "representative_phone": "0992223344",
        "representative_email": "representante@instituto.edu.co",
        "status": "ACTIVE",
    }
    if "user" in overrides:
        base["user"] = {**base["user"], **overrides.pop("user")}
    base.update(overrides)
    return base


def test_list_students_forbidden_for_student(client: TestClient, auth_headers: dict[str, str]):
    response = client.get("/api/v1/students", headers=auth_headers)
    assert response.status_code == 403


def test_own_student_requires_authentication(client: TestClient):
    response = client.get("/api/v1/students/me")
    assert response.status_code == 401
    assert "password" not in response.text


def test_own_student_forbidden_for_super_admin(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    response = client.get("/api/v1/students/me", headers=super_admin_headers)
    assert response.status_code == 403


def test_own_student_missing_profile_is_not_created(
    client: TestClient,
    auth_headers: dict[str, str],
):
    response = client.get("/api/v1/students/me", headers=auth_headers)
    assert response.status_code == 404
    assert response.json()["message"] == "No tienes una ficha de estudiante registrada"


def test_own_student_returns_only_the_authenticated_record(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    first = _student_payload(sample_institution.id)
    second = _student_payload(sample_institution.id)
    created_first = client.post("/api/v1/students", headers=super_admin_headers, json=first)
    created_second = client.post("/api/v1/students", headers=super_admin_headers, json=second)
    assert created_first.status_code == 200
    assert created_second.status_code == 200
    first_id = created_first.json()["data"]["id"]
    second_id = created_second.json()["data"]["id"]
    try:
        login = client.post(
            "/api/v1/auth/login",
            json={"email": first["user"]["email"], "password": first["user"]["password"]},
        )
        headers = {"Authorization": f"Bearer {login.json()['data']['access_token']}"}
        own = client.get("/api/v1/students/me", headers=headers)
        assert own.status_code == 200
        data = own.json()["data"]
        assert data["id"] == first_id
        assert data["identification"] == first["identification"]
        assert data["grade"] == "10"
        assert "password" not in data["user"]
        assert "password_hash" not in response_text(data)

        foreign = client.get(f"/api/v1/students/{second_id}", headers=headers)
        assert foreign.status_code == 403
        assert second["identification"] not in foreign.text
    finally:
        _delete_student_by_id(first_id)
        _delete_student_by_id(second_id)


def response_text(data: dict) -> str:
    return str(data)


def test_create_student_as_super_admin(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    payload = _student_payload(sample_institution.id)
    response = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=payload,
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["identification"] == payload["identification"]
    assert data["user"]["email"] == payload["user"]["email"]
    assert "password" not in data["user"]
    _delete_student_by_id(data["id"])


def test_create_student_as_institution_admin(
    client: TestClient,
    institution_admin_headers: dict[str, str],
    sample_institution,
):
    payload = _student_payload(sample_institution.id)
    response = client.post(
        "/api/v1/students",
        headers=institution_admin_headers,
        json=payload,
    )
    assert response.status_code == 200
    assert response.json()["data"]["institution_id"] == sample_institution.id
    _delete_student_by_id(response.json()["data"]["id"])


def test_create_student_duplicate_identification(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    payload = _student_payload(sample_institution.id)
    first = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=payload,
    )
    assert first.status_code == 200
    student_id = first.json()["data"]["id"]

    duplicate = _student_payload(sample_institution.id, identification=payload["identification"])
    response = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=duplicate,
    )
    assert response.status_code == 422
    _delete_student_by_id(student_id)


def test_create_student_future_birth_date(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    payload = _student_payload(
        sample_institution.id,
        birth_date=(date.today().replace(year=date.today().year + 1)).isoformat(),
    )
    response = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=payload,
    )
    assert response.status_code == 422


def test_get_student_as_super_admin(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    payload = _student_payload(sample_institution.id)
    created = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=payload,
    )
    student_id = created.json()["data"]["id"]

    response = client.get(
        f"/api/v1/students/{student_id}",
        headers=super_admin_headers,
    )
    assert response.status_code == 200
    _delete_student_by_id(student_id)


def test_get_student_self(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    payload = _student_payload(sample_institution.id)
    created = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=payload,
    )
    student_id = created.json()["data"]["id"]

    login = client.post(
        "/api/v1/auth/login",
        json={
            "email": payload["user"]["email"],
            "password": payload["user"]["password"],
        },
    )
    headers = {"Authorization": f"Bearer {login.json()['data']['access_token']}"}

    response = client.get(f"/api/v1/students/{student_id}", headers=headers)
    assert response.status_code == 200
    _delete_student_by_id(student_id)


def test_counselor_sees_only_assigned_students(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    counselor_payload = {
        "email": f"orient_{uuid.uuid4().hex[:6]}@instituto.edu.co",
        "password": "Test1234!",
        "first_name": "Orient",
        "last_name": "Prueba",
        "role": "COUNSELOR",
        "institution_id": sample_institution.id,
    }
    counselor_response = client.post(
        "/api/v1/users",
        headers=super_admin_headers,
        json=counselor_payload,
    )
    assert counselor_response.status_code == 200
    counselor_id = counselor_response.json()["data"]["id"]

    assigned_payload = _student_payload(sample_institution.id)
    assigned = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=assigned_payload,
    ).json()["data"]

    unassigned_payload = _student_payload(sample_institution.id)
    unassigned = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=unassigned_payload,
    ).json()["data"]

    assignment_session = SessionLocal()
    try:
        assignment_session.add(
            CounselorAssignment(
                counselor_id=counselor_id,
                student_id=assigned["id"],
                institution_id=sample_institution.id,
                status=AssignmentStatus.ACTIVE,
            )
        )
        assignment_session.commit()
    finally:
        assignment_session.close()

    login = client.post(
        "/api/v1/auth/login",
        json={
            "email": counselor_payload["email"],
            "password": counselor_payload["password"],
        },
    )
    counselor_headers = {
        "Authorization": f"Bearer {login.json()['data']['access_token']}"
    }

    list_response = client.get("/api/v1/students", headers=counselor_headers)
    assert list_response.status_code == 200
    item_ids = [item["id"] for item in list_response.json()["data"]["items"]]
    assert assigned["id"] in item_ids
    assert unassigned["id"] not in item_ids

    get_assigned = client.get(
        f"/api/v1/students/{assigned['id']}",
        headers=counselor_headers,
    )
    assert get_assigned.status_code == 200

    get_unassigned = client.get(
        f"/api/v1/students/{unassigned['id']}",
        headers=counselor_headers,
    )
    assert get_unassigned.status_code == 403

    _delete_student_by_id(assigned["id"])
    _delete_student_by_id(unassigned["id"])

    cleanup = SessionLocal()
    try:
        counselor_user = cleanup.get(User, counselor_id)
        if counselor_user:
            UserRepository(cleanup).delete(counselor_user)
    finally:
        cleanup.close()


def test_update_student_success(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    payload = _student_payload(sample_institution.id)
    created = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=payload,
    )
    student_id = created.json()["data"]["id"]

    response = client.put(
        f"/api/v1/students/{student_id}",
        headers=super_admin_headers,
        json={"grade": "11", "user": {"first_name": "Carlos Eduardo"}},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["grade"] == "11"
    assert data["user"]["first_name"] == "Carlos Eduardo"
    _delete_student_by_id(student_id)


def test_update_student_status_success(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    payload = _student_payload(sample_institution.id)
    created = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=payload,
    )
    student_id = created.json()["data"]["id"]

    response = client.patch(
        f"/api/v1/students/{student_id}/status",
        headers=super_admin_headers,
        json={"status": "INACTIVE"},
    )
    assert response.status_code == 200
    assert response.json()["data"]["user"]["status"] == "INACTIVE"
    _delete_student_by_id(student_id)
