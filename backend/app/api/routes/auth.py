from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.config import get_settings
from app.core.exceptions import UnauthorizedException
from app.core.responses import success_response
from app.models.user import User
from app.schemas.auth import (
    ChangePasswordRequest,
    LoginRequest,
    LogoutRequest,
    RefreshRequest,
)
from app.security.login_rate_limit import (
    LoginRateLimiter,
    client_host,
    get_login_rate_limiter,
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Autenticación"])


@router.post("/login")
def login(
    body: LoginRequest,
    request: Request,
    db: Session = Depends(get_db),
    limiter: LoginRateLimiter = Depends(get_login_rate_limiter),
):
    settings = get_settings()
    host = client_host(request, trust_proxy_headers=settings.trust_proxy_headers)
    # La reserva ya cuenta el intento. Solo se conserva si las credenciales
    # son incorrectas. Un acierto o una cuenta inactiva la retiran porque la
    # contraseña era válida. Un fallo inesperado devuelve solo ese intento.
    limiter.reserve(host, body.email)
    try:
        tokens = AuthService(db).login(body.email, body.password)
    except UnauthorizedException as exc:
        if exc.message != AuthService.INVALID_CREDENTIALS_MSG:
            limiter.clear(host, body.email)
        raise
    except Exception:
        limiter.release(host, body.email)
        raise
    limiter.clear(host, body.email)
    return success_response(
        data=tokens.model_dump(),
        message="Inicio de sesión exitoso",
    )


@router.post("/logout", dependencies=[Depends(security)])
def logout(
    body: LogoutRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    AuthService(db).logout(body.refresh_token, current_user.id)
    return success_response(message="Sesión cerrada correctamente")


@router.post("/refresh")
def refresh_token(body: RefreshRequest, db: Session = Depends(get_db)):
    tokens = AuthService(db).refresh(body.refresh_token)
    return success_response(
        data=tokens.model_dump(),
        message="Token renovado correctamente",
    )


@router.get("/me", dependencies=[Depends(security)])
def get_me(current_user: User = Depends(get_current_user)):
    profile = AuthService.build_profile(current_user)
    return success_response(
        data=profile.model_dump(),
        message="Perfil obtenido correctamente",
    )


@router.post("/change-password", dependencies=[Depends(security)])
def change_password(
    body: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    AuthService(db).change_password(current_user, body)
    return success_response(message="Contraseña actualizada correctamente")
