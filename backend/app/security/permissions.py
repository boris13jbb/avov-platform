from collections.abc import Callable

from fastapi import Depends

from app.api.deps import get_current_user
from app.core.enums import UserRole
from app.core.exceptions import ForbiddenException
from app.models.user import User


def require_roles(*allowed_roles: UserRole) -> Callable[..., User]:
    """Dependencia FastAPI que restringe el acceso a los roles indicados."""

    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise ForbiddenException("No tienes permisos para esta acción")
        return current_user

    return role_checker


def user_has_role(user: User, *allowed_roles: UserRole) -> bool:
    return user.role in allowed_roles
