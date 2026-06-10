from datetime import datetime
from math import ceil

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.core.enums import InstitutionStatus
from app.utils.validators import is_valid_phone


class InstitutionBase(BaseModel):
    name: str = Field(min_length=3, max_length=150)
    code: str = Field(min_length=1, max_length=50)
    province: str = Field(min_length=1, max_length=100)
    city: str = Field(min_length=1, max_length=100)
    address: str | None = Field(default=None, max_length=255)
    phone: str | None = Field(default=None, max_length=15)
    email: EmailStr | None = None
    logo_url: str | None = Field(default=None, max_length=500)
    status: InstitutionStatus = InstitutionStatus.ACTIVE

    @field_validator("code")
    @classmethod
    def normalize_code(cls, value: str) -> str:
        return value.strip().upper()

    @field_validator("name", "province", "city", "address")
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


class InstitutionCreate(InstitutionBase):
    pass


class InstitutionUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=3, max_length=150)
    code: str | None = Field(default=None, min_length=1, max_length=50)
    province: str | None = Field(default=None, min_length=1, max_length=100)
    city: str | None = Field(default=None, min_length=1, max_length=100)
    address: str | None = Field(default=None, max_length=255)
    phone: str | None = Field(default=None, max_length=15)
    email: EmailStr | None = None
    logo_url: str | None = Field(default=None, max_length=500)
    status: InstitutionStatus | None = None

    @field_validator("code")
    @classmethod
    def normalize_code(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip().upper()

    @field_validator("name", "province", "city", "address")
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


class InstitutionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    code: str
    province: str
    city: str
    address: str | None
    phone: str | None
    email: str | None
    logo_url: str | None
    status: InstitutionStatus
    created_at: datetime
    updated_at: datetime


class PaginatedInstitutions(BaseModel):
    items: list[InstitutionResponse]
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
    ) -> "PaginatedInstitutions":
        pages = ceil(total / page_size) if total > 0 else 0
        return cls(
            items=[InstitutionResponse.model_validate(item) for item in items],
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )
