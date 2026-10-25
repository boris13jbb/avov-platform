import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.core.enums import AssignmentStatus, UserRole, UserStatus
from app.db.session import SessionLocal
from app.models.counselor import CounselorObservation
from app.models.student import CounselorAssignment
from app.models.user import User
from app.repositories.assignment_repository import AssignmentRepository
from app.repositories.user_repository import UserRepository
from tests.test_vocational_test import _delete_student_by_id, _student_payload


def _cleanup_counselor_fixture(
    *,
    session_id: int,
    student_id: int,
    counselor_id: int,
) -> None:
    cleanup = SessionLocal()
    try:
        for observation in cleanup.scalars(
            select(CounselorObservation).where(
                CounselorObservation.test_session_id == session_id
            )
        ):
            cleanup.delete(observation)

        assignment = cleanup.scalar(
            select(CounselorAssignment).where(
                CounselorAssignment.counselor_id == counselor_id,
                CounselorAssignment.student_id == student_id,
            )
        )
        if assignment is not None:
            cleanup.delete(assignment)
        cleanup.commit()
    finally:
        cleanup.close()

    _delete_student_by_id(student_id)

    cleanup = SessionLocal()
    try:
        counselor_row = cleanup.get(User, counselor_id)
        if counselor_row is not None:
            UserRepository(cleanup).delete(counselor_row)
    finally:
        cleanup.close()


@pytest.fixture
def counselor_with_assignment(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    counselor_email = f"orient_{uuid.uuid4().hex[:8]}@instituto.edu.co"
    counselor_password = "Orient1234!"
    counselor_id: int | None = None
    student_id: int | None = None
    session_id: int | None = None

    setup = SessionLocal()
    try:
        counselor = UserRepository(setup).create_raw(
            email=counselor_email,
            password=counselor_password,
            first_name="Orient",
            last_name="Prueba",
            role=UserRole.COUNSELOR,
            status=UserStatus.ACTIVE,
            institution_id=sample_institution.id,
        )
        counselor_id = counselor.id

        payload = _student_payload(sample_institution.id)
        created = client.post(
            "/api/v1/students",
            headers=super_admin_headers,
            json=payload,
        )
        assert created.status_code == 200
        student_id = created.json()["data"]["id"]

        AssignmentRepository(setup).create(
            counselor_id=counselor_id,
            student_id=student_id,
            institution_id=sample_institution.id,
            status=AssignmentStatus.ACTIVE,
        )
    finally:
        setup.close()

    login = client.post(
        "/api/v1/auth/login",
        json={"email": counselor_email, "password": counselor_password},
    )
    assert login.status_code == 200
    counselor_headers = {
        "Authorization": f"Bearer {login.json()['data']['access_token']}"
    }

    student_login = client.post(
        "/api/v1/auth/login",
        json={"email": payload["user"]["email"], "password": payload["user"]["password"]},
    )
    student_headers = {
        "Authorization": f"Bearer {student_login.json()['data']['access_token']}"
    }

    start = client.post("/api/v1/tests/start", headers=student_headers)
    assert start.status_code == 200
    session_id = start.json()["data"]["id"]

    assert counselor_id is not None
    assert student_id is not None
    assert session_id is not None

    yield {
        "counselor_headers": counselor_headers,
        "student_headers": student_headers,
        "session_id": session_id,
        "student_id": student_id,
        "counselor_id": counselor_id,
    }

    _cleanup_counselor_fixture(
        session_id=session_id,
        student_id=student_id,
        counselor_id=counselor_id,
    )


def test_create_observation_requires_counselor(
    client: TestClient,
    counselor_with_assignment,
):
    session_id = counselor_with_assignment["session_id"]
    student_headers = counselor_with_assignment["student_headers"]

    response = client.post(
        "/api/v1/observations",
        headers=student_headers,
        json={
            "test_session_id": session_id,
            "observation": "Seguimiento vocacional inicial",
        },
    )
    assert response.status_code == 403


def test_create_and_list_observations(
    client: TestClient,
    counselor_with_assignment,
    super_admin_headers,
):
    session_id = counselor_with_assignment["session_id"]
    counselor_headers = counselor_with_assignment["counselor_headers"]

    create = client.post(
        "/api/v1/observations",
        headers=counselor_headers,
        json={
            "test_session_id": session_id,
            "observation": "Primera observación del orientador",
        },
    )
    assert create.status_code == 200
    assert create.json()["success"] is True
    created_id = create.json()["data"]["id"]

    listing = client.get(
        f"/api/v1/observations?test_session_id={session_id}",
        headers=super_admin_headers,
    )
    assert listing.status_code == 200
    items = listing.json()["data"]["items"]
    assert len(items) >= 1
    assert items[0]["id"] == created_id

    latest = client.get(
        f"/api/v1/observations/latest?test_session_id={session_id}",
        headers=counselor_headers,
    )
    assert latest.status_code == 200
    assert latest.json()["data"]["observation"] == "Primera observación del orientador"
