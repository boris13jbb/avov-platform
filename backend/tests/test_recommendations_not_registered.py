"""Verificación documental S-18: recomendaciones no están en la API registrada."""

from app.main import app


def test_recommendations_router_not_included_in_app():
    paths = {getattr(route, "path", "") for route in app.routes}
    assert not any("/recommendations" in path for path in paths)


def test_openapi_has_no_recommendations_paths():
    openapi_paths = (app.openapi() or {}).get("paths") or {}
    assert not any("recommend" in path.lower() for path in openapi_paths)
