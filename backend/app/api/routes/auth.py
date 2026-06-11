from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.exceptions import UnauthorizedException
from app.core.responses import success_response
from app.models.user import User
from app.security.rate_limit import login_rate_limiter
from app.schemas.auth import (
    ChangePasswordRequest,
    ForgotPasswordRequest,
    LoginRequest,
    LogoutRequest,
    RefreshRequest,
    ResetPasswordRequest,
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Autenticación"])


@router.post("/login")
def login(body: LoginRequest, request: Request, db: Session = Depends(get_db)):
    client_ip = request.client.host if request.client else "unknown"
    rate_key = f"{client_ip}:{body.email.strip().lower()}"
    login_rate_limiter.ensure_not_blocked(rate_key)

    try:
        tokens = AuthService(db).login(body.email, body.password)
    except UnauthorizedException as exc:
        if exc.message == AuthService.INVALID_CREDENTIALS_MSG:
            login_rate_limiter.record_failed_attempt(rate_key)
        raise

    login_rate_limiter.clear(rate_key)
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


@router.post("/forgot-password")
def forgot_password(
    body: ForgotPasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    client_ip = request.client.host if request.client else "unknown"
    rate_key = f"forgot:{client_ip}:{body.email.strip().lower()}"
    login_rate_limiter.ensure_not_blocked(rate_key)
    login_rate_limiter.record_failed_attempt(rate_key)

    message = AuthService(db).request_password_reset(
        body,
        ip_address=client_ip,
        user_agent=request.headers.get("user-agent"),
    )
    return success_response(message=message)


@router.post("/reset-password")
def reset_password(
    body: ResetPasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    client_ip = request.client.host if request.client else "unknown"
    AuthService(db).reset_password(
        body,
        ip_address=client_ip,
        user_agent=request.headers.get("user-agent"),
    )
    return success_response(message="Contraseña restablecida correctamente")


@router.post("/change-password", dependencies=[Depends(security)])
def change_password(
    body: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    AuthService(db).change_password(current_user, body)
    return success_response(message="Contraseña actualizada correctamente")
