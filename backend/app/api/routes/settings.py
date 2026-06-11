from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_db, security
from app.core.enums import UserRole
from app.core.responses import success_response
from app.models.user import User
from app.schemas.system_setting import SystemSettingUpdate
from app.security.permissions import require_roles
from app.services.system_setting_service import SystemSettingService

router = APIRouter(prefix="/settings", tags=["Configuración del sistema"])


@router.get("/public")
def get_public_settings(db: Session = Depends(get_db)):
    settings = SystemSettingService(db).get_public_settings()
    return success_response(
        data=settings.model_dump(mode="json"),
        message="Configuración pública obtenida correctamente",
    )


@router.get("", dependencies=[Depends(security)])
def list_system_settings(
    _current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    settings = SystemSettingService(db).list_settings()
    return success_response(
        data=[item.model_dump(mode="json") for item in settings],
        message="Configuración del sistema obtenida correctamente",
    )


@router.put("/{key}", dependencies=[Depends(security)])
def update_system_setting(
    key: str,
    body: SystemSettingUpdate,
    current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    setting = SystemSettingService(db).update_setting(key, body, current_user)
    return success_response(
        data=setting.model_dump(mode="json"),
        message="Parámetro actualizado correctamente",
    )
