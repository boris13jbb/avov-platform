from datetime import datetime
from math import ceil

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator

from app.core.enums import UserRole, UserStatus
from app.utils.validators import is_strong_password, is_valid_phone


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    first_name: str = Field(min_length=1, max_length=100)
    last_name: str = Field(min_length=1, max_length=100)
    role: UserRole
    institution_id: int | None = None
    phone: str | None = Field(default=None, max_length=15)
    status: UserStatus = UserStatus.ACTIVE

    @field_validator("password")
    @classmethod
    def validate_password(cls, value: str) -> str:
        if not is_strong_password(value):
            raise ValueError(
                "La contraseña debe tener al menos 8 caracteres, "
                "una mayúscula, una minúscula, un número y un símbolo"
            )
        return value

    @field_validator("first_name", "last_name")
    @classmethod
    def strip_text(cls, value: str) -> str:
        return value.strip()

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, value: str | None) -> str | None:
        if value is not None and not is_valid_phone(value):
            raise ValueError("El teléfono debe contener entre 7 y 15 dígitos")
        return value

    @model_validator(mode="after")
    def validate_role_institution(self) -> "UserCreate":
        if self.role == UserRole.SUPER_ADMIN and self.institution_id is not None:
            raise ValueError("Un SUPER_ADMIN no debe tener institution_id")
        if self.role != UserRole.SUPER_ADMIN and self.institution_id is None:
            raise ValueError("institution_id es obligatorio para este rol")
        return self


class UserUpdate(BaseModel):
    email: EmailStr | None = None
    first_name: str | None = Field(default=None, min_length=1, max_length=100)
    last_name: str | None = Field(default=None, min_length=1, max_length=100)
    role: UserRole | None = None
    institution_id: int | None = None
    phone: str | None = Field(default=None, max_length=15)
    avatar_url: str | None = Field(default=None, max_length=500)

    @field_validator("first_name", "last_name")
    @classmethod
    def strip_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip()

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, value: str | None) -> str | None:
        if value is not None and not is_valid_phone(value):
            raise ValueError("El teléfono debe contener entre 7 y 15 dígitos")
        return value


class UserStatusUpdate(BaseModel):
    status: UserStatus


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    first_name: str
    last_name: str
    role: UserRole
    status: UserStatus
    institution_id: int | None
    phone: str | None
    avatar_url: str | None
    last_login_at: datetime | None
    created_at: datetime
    updated_at: datetime


class PaginatedUsers(BaseModel):
    items: list[UserResponse]
    total: int
    page: int
    page_size: int
    pages: int

    @classmethod
    def build(
        cls,
        items: list,
        total: int,
        page: int,
        page_size: int,
    ) -> "PaginatedUsers":
        pages = ceil(total / page_size) if total > 0 else 0
        return cls(
            items=[UserResponse.model_validate(item) for item in items],
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )
