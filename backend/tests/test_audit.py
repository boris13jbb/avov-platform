from fastapi.testclient import TestClient


def test_list_audit_logs_requires_super_admin(
    client: TestClient,
    auth_headers: dict[str, str],
):
    response = client.get("/api/v1/audit/logs", headers=auth_headers)
    assert response.status_code == 403


def test_get_audit_log_detail(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    list_response = client.get(
        "/api/v1/audit/logs",
        headers=super_admin_headers,
        params={"page": 1, "page_size": 1},
    )
    assert list_response.status_code == 200
    items = list_response.json()["data"]["items"]
    if not items:
        return

    log_id = items[0]["id"]
    detail_response = client.get(
        f"/api/v1/audit/logs/{log_id}",
        headers=super_admin_headers,
    )
    assert detail_response.status_code == 200
    assert detail_response.json()["data"]["id"] == log_id


def test_get_audit_log_not_found(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    response = client.get(
        "/api/v1/audit/logs/999999999",
        headers=super_admin_headers,
    )
    assert response.status_code == 404
