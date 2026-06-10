import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.enums import InstitutionStatus, UserRole, UserStatus
from app.db.session import SessionLocal
from app.main import app
from app.repositories.institution_repository import InstitutionRepository
from app.repositories.user_repository import UserRepository
from app.schemas.institution import InstitutionCreate


@pytest.fixture
def client() -> TestClient:
    return TestClient(app)


@pytest.fixture
def db() -> Session:
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def test_user(db: Session, sample_institution):
    """Usuario de prueba con contraseña Test1234!"""
    repo = UserRepository(db)
    unique_email = f"test_{uuid.uuid4().hex[:12]}@instituto.edu.co"
    user = repo.create_raw(
        email=unique_email,
        password="Test1234!",
        first_name="Usuario",
        last_name="Prueba",
        role=UserRole.STUDENT,
        status=UserStatus.ACTIVE,
        institution_id=sample_institution.id,
    )
    yield user
    repo.delete(user)


@pytest.fixture
def auth_headers(client: TestClient, test_user) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/login",
        json={"email": test_user.email, "password": "Test1234!"},
    )
    assert response.status_code == 200
    tokens = response.json()["data"]
    return {
        "Authorization": f"Bearer {tokens['access_token']}",
        "X-Refresh-Token": tokens["refresh_token"],
    }


@pytest.fixture
def super_admin_headers(client: TestClient) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@avov.edu.co", "password": "Admin123!"},
    )
    assert response.status_code == 200
    tokens = response.json()["data"]
    return {"Authorization": f"Bearer {tokens['access_token']}"}


@pytest.fixture
def sample_institution(db: Session):
    repo = InstitutionRepository(db)
    unique_code = f"INST-{uuid.uuid4().hex[:8].upper()}"
    institution = repo.create(
        InstitutionCreate(
            name="Instituto Técnico Demo",
            code=unique_code,
            province="Pichincha",
            city="Quito",
            address="Av. Demo 123",
            phone="0991234567",
            email="contacto@instituto.edu.co",
            status=InstitutionStatus.ACTIVE,
        )
    )
    yield institution
    repo.delete(institution)


@pytest.fixture
def institution_admin_headers(client: TestClient, db: Session, sample_institution):
    user_repo = UserRepository(db)
    email = f"admin_{uuid.uuid4().hex[:8]}@instituto.edu.co"
    user = user_repo.create_raw(
        email=email,
        password="Test1234!",
        first_name="Admin",
        last_name="Institucional",
        role=UserRole.INSTITUTION_ADMIN,
        status=UserStatus.ACTIVE,
        institution_id=sample_institution.id,
    )
    response = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "Test1234!"},
    )
    assert response.status_code == 200
    tokens = response.json()["data"]
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}
    yield headers
    user_repo.delete(user)
