from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert body["data"]["name"] == "AVOV"
    assert "Bienvenido" in body["message"]


def test_liveness_endpoint():
    response = client.get("/api/v1/health/live")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert body["data"]["status"] == "alive"


def test_health_endpoint_structure():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert "services" in body["data"]
    assert "api" in body["data"]["services"]
    assert body["data"]["services"]["api"] is True
