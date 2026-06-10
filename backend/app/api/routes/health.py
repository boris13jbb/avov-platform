import redis
from fastapi import APIRouter
from qdrant_client import QdrantClient
from qdrant_client.http.exceptions import UnexpectedResponse

from app.core.config import get_settings
from app.core.responses import success_response
from app.db.session import check_database_connection

router = APIRouter(tags=["Salud"])
settings = get_settings()


def _check_redis() -> bool:
    try:
        client = redis.from_url(settings.redis_url, socket_connect_timeout=2)
        return bool(client.ping())
    except Exception:
        return False


def _check_qdrant() -> bool:
    try:
        client = QdrantClient(
            host=settings.qdrant_host,
            port=settings.qdrant_port,
            api_key=settings.qdrant_api_key or None,
            timeout=2,
        )
        client.get_collections()
        return True
    except (UnexpectedResponse, Exception):
        return False


@router.get("/health")
def health_check():
    services = {
        "api": True,
        "mysql": check_database_connection(),
        "redis": _check_redis(),
        "qdrant": _check_qdrant(),
    }
    all_healthy = all(services.values())

    return success_response(
        data={
            "status": "healthy" if all_healthy else "degraded",
            "app": settings.app_name,
            "environment": settings.app_env,
            "services": services,
        },
        message="Servicio operativo" if all_healthy else "Servicio con dependencias degradadas",
    )


@router.get("/health/live")
def liveness_check():
    return success_response(
        data={"status": "alive"},
        message="La API está en ejecución",
    )
