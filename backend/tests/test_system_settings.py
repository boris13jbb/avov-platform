from fastapi.testclient import TestClient

from app.services.system_setting_service import DEFAULT_SETTINGS


def test_list_settings_requires_super_admin(
    client: TestClient,
    institution_admin_headers: dict[str, str],
):
    response = client.get("/api/v1/settings", headers=institution_admin_headers)
    assert response.status_code == 403


def test_list_settings_creates_defaults(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    response = client.get("/api/v1/settings", headers=super_admin_headers)
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    keys = {item["key"] for item in body["data"]}
    assert keys == set(DEFAULT_SETTINGS.keys())


def test_update_setting_validates_value(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    client.get("/api/v1/settings", headers=super_admin_headers)

    response = client.put(
        "/api/v1/settings/max_recommendations_per_session",
        headers=super_admin_headers,
        json={"value": "99"},
    )
    assert response.status_code == 422
    assert response.json()["success"] is False


def test_update_setting_success(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    client.get("/api/v1/settings", headers=super_admin_headers)

    response = client.put(
        "/api/v1/settings/app_display_name",
        headers=super_admin_headers,
        json={"value": "AVOV Plataforma"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert body["data"]["value"] == "AVOV Plataforma"


def test_get_public_settings_without_auth(client: TestClient):
    response = client.get("/api/v1/settings/public")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    data = body["data"]
    assert "app_display_name" in data
    assert "ethical_disclaimer" in data
    assert "maintenance_mode" in data
    assert isinstance(data["maintenance_mode"], bool)


def test_login_blocked_during_maintenance_for_student(
    client: TestClient,
    test_user,
    super_admin_headers: dict[str, str],
):
    client.get("/api/v1/settings", headers=super_admin_headers)
    client.put(
        "/api/v1/settings/maintenance_mode",
        headers=super_admin_headers,
        json={"value": "true"},
    )

    response = client.post(
        "/api/v1/auth/login",
        json={"email": test_user.email, "password": "Test1234!"},
    )
    assert response.status_code == 401
    assert "mantenimiento" in response.json()["message"].lower()

    admin_login = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@avov.edu.co", "password": "Admin123!"},
    )
    assert admin_login.status_code == 200

    client.put(
        "/api/v1/settings/maintenance_mode",
        headers=super_admin_headers,
        json={"value": "false"},
    )


def test_update_unknown_setting_returns_404(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    response = client.put(
        "/api/v1/settings/unknown_key",
        headers=super_admin_headers,
        json={"value": "x"},
    )
    assert response.status_code == 404
