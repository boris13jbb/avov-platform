from typing import Any


class AppException(Exception):
    def __init__(
        self,
        message: str,
        *,
        status_code: int = 400,
        errors: list[dict[str, Any]] | None = None,
    ) -> None:
        self.message = message
        self.status_code = status_code
        self.errors = errors or []
        self.headers: dict[str, str] | None = None
        super().__init__(message)


class NotFoundException(AppException):
    def __init__(self, message: str = "Recurso no encontrado") -> None:
        super().__init__(message, status_code=404)


class UnauthorizedException(AppException):
    def __init__(self, message: str = "No autorizado") -> None:
        super().__init__(message, status_code=401)


class ForbiddenException(AppException):
    def __init__(self, message: str = "Acceso denegado") -> None:
        super().__init__(message, status_code=403)


class TooManyRequestsException(AppException):
    def __init__(self, message: str, *, retry_after: int) -> None:
        super().__init__(message, status_code=429)
        self.headers = {"Retry-After": str(max(1, retry_after))}


class ServiceUnavailableException(AppException):
    def __init__(self, message: str = "Servicio temporalmente no disponible") -> None:
        super().__init__(message, status_code=503)


class ValidationException(AppException):
    def __init__(
        self,
        message: str = "Error de validación",
        errors: list[dict[str, Any]] | None = None,
    ) -> None:
        super().__init__(message, status_code=422, errors=errors)
