from fastapi import APIRouter

from app.core.config import get_settings
from app.core.responses import success_response

router = APIRouter(tags=["Estado"])
settings = get_settings()


@router.get("/status")
def service_status():
    return success_response(
        data={
            "app": settings.app_name,
            "environment": settings.app_env,
            "version": "0.1.0",
        },
        message="Estado del servicio obtenido correctamente",
    )
