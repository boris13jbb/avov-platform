from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.enums import UserRole, UserStatus
from app.core.responses import success_response
from app.models.user import User
from app.schemas.user import UserCreate, UserStatusUpdate, UserUpdate
from app.security.permissions import require_roles
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["Usuarios"])


@router.get("", dependencies=[Depends(security)])
def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: str | None = Query(None, max_length=100),
    role: UserRole | None = None,
    institution_id: int | None = None,
    status: UserStatus | None = None,
    current_user: User = Depends(
        require_roles(UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN)
    ),
    db: Session = Depends(get_db),
):
    result = UserService(db).list_users(
        current_user,
        page=page,
        page_size=page_size,
        search=search,
        role=role,
        institution_id=institution_id,
        status=status,
    )
    return success_response(
        data=result.model_dump(mode="json"),
        message="Usuarios obtenidos correctamente",
    )


@router.get("/{user_id}", dependencies=[Depends(security)])
def get_user(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user = UserService(db).get_user(user_id, current_user)
    return success_response(
        data=user.model_dump(mode="json"),
        message="Usuario obtenido correctamente",
    )


@router.post("", dependencies=[Depends(security)])
def create_user(
    body: UserCreate,
    current_user: User = Depends(
        require_roles(UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN)
    ),
    db: Session = Depends(get_db),
):
    user = UserService(db).create_user(body, current_user)
    return success_response(
        data=user.model_dump(mode="json"),
        message="Usuario creado correctamente",
    )


@router.put("/{user_id}", dependencies=[Depends(security)])
def update_user(
    user_id: int,
    body: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user = UserService(db).update_user(user_id, body, current_user)
    return success_response(
        data=user.model_dump(mode="json"),
        message="Usuario actualizado correctamente",
    )


@router.patch("/{user_id}/status", dependencies=[Depends(security)])
def update_user_status(
    user_id: int,
    body: UserStatusUpdate,
    current_user: User = Depends(
        require_roles(UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN)
    ),
    db: Session = Depends(get_db),
):
    user = UserService(db).update_user_status(user_id, body, current_user)
    return success_response(
        data=user.model_dump(mode="json"),
        message="Estado del usuario actualizado correctamente",
    )
