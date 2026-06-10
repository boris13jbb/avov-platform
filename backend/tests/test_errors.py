def test_error_response_structure():
    from app.core.responses import error_response

    result = error_response(
        message="Error de validación",
        errors=[{"field": "email", "message": "El correo no tiene un formato válido"}],
    )
    assert result["success"] is False
    assert result["message"] == "Error de validación"
    assert result["data"] is None
    assert len(result["errors"]) == 1
    assert result["errors"][0]["field"] == "email"


def test_not_found_error_format(client):
    response = client.get("/api/v1/ruta-inexistente")
    assert response.status_code == 404
    body = response.json()
    assert body["success"] is False
    assert body["data"] is None
