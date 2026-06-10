def test_status_endpoint(client):
    response = client.get("/api/v1/status")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert body["data"]["app"] == "AVOV"
    assert body["data"]["version"] == "0.1.0"
