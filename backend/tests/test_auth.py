import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.enums import UserRole, UserStatus
from app.repositories.user_repository import UserRepository
from app.security.password import hash_password, verify_password
from app.security.permissions import user_has_role


def _login(client: TestClient, email: str, password: str) -> dict:
    response = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    return response


def test_login_success(client: TestClient, test_user):
    response = _login(client, test_user.email, "Test1234!")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert "access_token" in body["data"]
    assert "refresh_token" in body["data"]
    assert body["data"]["token_type"] == "bearer"


def test_login_invalid_credentials_same_message(client: TestClient, test_user):
    wrong_password = _login(client, test_user.email, "WrongPass1!")
    unknown_email = _login(client, "noexiste@instituto.edu.co", "Test1234!")

    assert wrong_password.status_code == 401
    assert unknown_email.status_code == 401
    assert wrong_password.json()["message"] == unknown_email.json()["message"]
    assert wrong_password.json()["message"] == "Credenciales incorrectas"


def test_login_inactive_user(client: TestClient, db: Session):
    repo = UserRepository(db)
    email = f"inactive_{uuid.uuid4().hex[:8]}@instituto.edu.co"
    user = repo.create_raw(
        email=email,
        password="Test1234!",
        first_name="Inactivo",
        last_name="Usuario",
        role=UserRole.STUDENT,
        status=UserStatus.INACTIVE,
    )
    try:
        response = _login(client, email, "Test1234!")
        assert response.status_code == 401
        assert "no está activa" in response.json()["message"]
    finally:
        repo.delete(user)


def test_me_requires_token(client: TestClient):
    response = client.get("/api/v1/auth/me")
    assert response.status_code == 401
    assert response.json()["success"] is False


def test_me_invalid_token(client: TestClient):
    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer token-invalido"},
    )
    assert response.status_code == 401


def test_me_success(client: TestClient, test_user, auth_headers):
    response = client.get("/api/v1/auth/me", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["email"] == test_user.email
    assert data["role"] == UserRole.STUDENT.value


def test_password_stored_hashed(db: Session):
    repo = UserRepository(db)
    email = f"hash_{uuid.uuid4().hex[:8]}@instituto.edu.co"
    plain_password = "Test1234!"
    user = repo.create_raw(
        email=email,
        password=plain_password,
        first_name="Hash",
        last_name="Test",
        role=UserRole.COUNSELOR,
    )
    try:
        assert user.password_hash != plain_password
        assert user.password_hash.startswith("$2b$")
        assert verify_password(plain_password, user.password_hash)
    finally:
        repo.delete(user)


def test_change_password_success(client: TestClient, test_user, auth_headers):
    response = client.post(
        "/api/v1/auth/change-password",
        headers=auth_headers,
        json={
            "current_password": "Test1234!",
            "new_password": "Nueva1234!",
            "confirm_password": "Nueva1234!",
        },
    )
    assert response.status_code == 200

    old_login = _login(client, test_user.email, "Test1234!")
    new_login = _login(client, test_user.email, "Nueva1234!")
    assert old_login.status_code == 401
    assert new_login.status_code == 200


def test_change_password_wrong_current(client: TestClient, auth_headers):
    response = client.post(
        "/api/v1/auth/change-password",
        headers=auth_headers,
        json={
            "current_password": "Incorrecta1!",
            "new_password": "Nueva1234!",
            "confirm_password": "Nueva1234!",
        },
    )
    assert response.status_code == 401


def test_change_password_weak_new(client: TestClient, auth_headers):
    response = client.post(
        "/api/v1/auth/change-password",
        headers=auth_headers,
        json={
            "current_password": "Test1234!",
            "new_password": "debil",
            "confirm_password": "debil",
        },
    )
    assert response.status_code == 422


def test_logout_revokes_refresh_token(client: TestClient, test_user):
    login_response = _login(client, test_user.email, "Test1234!")
    tokens = login_response.json()["data"]
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}

    logout_response = client.post(
        "/api/v1/auth/logout",
        headers=headers,
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert logout_response.status_code == 200

    refresh_response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert refresh_response.status_code == 401


def test_refresh_token_success(client: TestClient, test_user):
    login_response = _login(client, test_user.email, "Test1234!")
    old_tokens = login_response.json()["data"]

    refresh_response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": old_tokens["refresh_token"]},
    )
    assert refresh_response.status_code == 200
    new_tokens = refresh_response.json()["data"]
    assert new_tokens["access_token"]
    assert new_tokens["refresh_token"] != old_tokens["refresh_token"]


def test_user_has_role_helper(test_user):
    assert user_has_role(test_user, UserRole.STUDENT) is True
    assert user_has_role(test_user, UserRole.SUPER_ADMIN) is False
