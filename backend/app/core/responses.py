from typing import Any, Generic, List, Optional, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class ErrorDetail(BaseModel):
    field: Optional[str] = None
    message: str


class ApiResponse(BaseModel, Generic[T]):
    success: bool
    message: str
    data: Optional[T] = None
    errors: List[ErrorDetail] = Field(default_factory=list)


def success_response(
    data: Any = None,
    message: str = "Operación realizada correctamente",
) -> dict[str, Any]:
    return {
        "success": True,
        "message": message,
        "data": data,
        "errors": [],
    }


def error_response(
    message: str,
    errors: Optional[List[dict[str, str]]] = None,
    data: Any = None,
) -> dict[str, Any]:
    formatted_errors = [
        ErrorDetail(**error) if isinstance(error, dict) else ErrorDetail(message=str(error))
        for error in (errors or [])
    ]
    return {
        "success": False,
        "message": message,
        "data": data,
        "errors": [error.model_dump() for error in formatted_errors],
    }
