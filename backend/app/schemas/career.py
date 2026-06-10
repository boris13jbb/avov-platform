import re
from datetime import datetime
from math import ceil

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.enums import CareerStatus, DegreeType, InstitutionType

RIASEC_PATTERN = re.compile(r"^[RIASEC]+$")


class CareerBase(BaseModel):
    name: str = Field(min_length=3, max_length=200)
    area: str = Field(min_length=1, max_length=100)
    description: str = Field(min_length=10)
    riasec_profile: str = Field(min_length=1, max_length=10)
    duration: str | None = Field(default=None, max_length=50)
    degree_type: DegreeType
    institution_type: InstitutionType
    employment_field: str = Field(min_length=1, max_length=200)
    status: CareerStatus = CareerStatus.ACTIVE

    @field_validator("name", "area", "employment_field", "duration")
    @classmethod
    def strip_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip()

    @field_validator("description")
    @classmethod
    def strip_description(cls, value: str) -> str:
        return value.strip()

    @field_validator("riasec_profile")
    @classmethod
    def validate_riasec_profile(cls, value: str) -> str:
        normalized = value.strip().upper()
        if not RIASEC_PATTERN.match(normalized):
            raise ValueError(
                "El perfil RIASEC solo puede contener las letras R, I, A, S, E o C"
            )
        return normalized


class CareerCreate(CareerBase):
    pass


class CareerUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=3, max_length=200)
    area: str | None = Field(default=None, min_length=1, max_length=100)
    description: str | None = Field(default=None, min_length=10)
    riasec_profile: str | None = Field(default=None, min_length=1, max_length=10)
    duration: str | None = Field(default=None, max_length=50)
    degree_type: DegreeType | None = None
    institution_type: InstitutionType | None = None
    employment_field: str | None = Field(default=None, min_length=1, max_length=200)
    status: CareerStatus | None = None

    @field_validator("name", "area", "employment_field", "duration")
    @classmethod
    def strip_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip()

    @field_validator("description")
    @classmethod
    def strip_description(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip()

    @field_validator("riasec_profile")
    @classmethod
    def validate_riasec_profile(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalized = value.strip().upper()
        if not RIASEC_PATTERN.match(normalized):
            raise ValueError(
                "El perfil RIASEC solo puede contener las letras R, I, A, S, E o C"
            )
        return normalized


class CareerResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    area: str
    description: str
    riasec_profile: str
    duration: str | None
    degree_type: DegreeType
    institution_type: InstitutionType
    employment_field: str
    status: CareerStatus
    created_at: datetime
    updated_at: datetime


class PaginatedCareers(BaseModel):
    items: list[CareerResponse]
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
    ) -> "PaginatedCareers":
        pages = ceil(total / page_size) if total > 0 else 0
        return cls(
            items=[CareerResponse.model_validate(item) for item in items],
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )
