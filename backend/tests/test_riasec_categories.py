from fastapi.testclient import TestClient


def test_list_riasec_categories_requires_auth(client: TestClient):
    response = client.get("/api/v1/riasec-categories")
    assert response.status_code == 401


def test_list_riasec_categories_success(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    response = client.get(
        "/api/v1/riasec-categories",
        headers=super_admin_headers,
    )
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert len(body["data"]) == 6
    codes = {item["code"] for item in body["data"]}
    assert codes == {"R", "I", "A", "S", "E", "C"}
