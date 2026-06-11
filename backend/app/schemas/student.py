from datetime import date, datetime
from math import ceil

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator

from app.core.enums import Gender, UserStatus
from app.utils.validators import is_strong_password, is_valid_email, is_valid_phone


class StudentUserInput(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    first_name: str = Field(min_length=1, max_length=100)
    last_name: str = Field(min_length=1, max_length=100)
    phone: str | None = Field(default=None, max_length=15)

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


class StudentCreate(BaseModel):
    institution_id: int
    user: StudentUserInput
    identification: str = Field(min_length=5, max_length=50)
    birth_date: date
    gender: Gender = Gender.NOT_SPECIFIED
    grade: str = Field(min_length=1, max_length=20)
    parallel: str | None = Field(default=None, max_length=10)
    representative_name: str | None = Field(default=None, max_length=150)
    representative_phone: str | None = Field(default=None, max_length=15)
    representative_email: str | None = Field(default=None, max_length=255)
    status: UserStatus = UserStatus.ACTIVE

    @field_validator("identification", "grade", "parallel", "representative_name")
    @classmethod
    def strip_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip()

    @field_validator("identification")
    @classmethod
    def normalize_identification(cls, value: str) -> str:
        return value.strip().upper()

    @field_validator("birth_date")
    @classmethod
    def validate_birth_date(cls, value: date) -> date:
        if value > date.today():
            raise ValueError("La fecha de nacimiento no puede ser futura")
        return value

    @field_validator("representative_phone")
    @classmethod
    def validate_representative_phone(cls, value: str | None) -> str | None:
        if value is not None and not is_valid_phone(value):
            raise ValueError("El teléfono del representante debe contener entre 7 y 15 dígitos")
        return value

    @field_validator("representative_email")
    @classmethod
    def validate_representative_email(cls, value: str | None) -> str | None:
        if value is not None and value.strip() and not is_valid_email(value):
            raise ValueError("El correo del representante no es válido")
        return value.strip() if value else None


class StudentUserUpdate(BaseModel):
    email: EmailStr | None = None
    first_name: str | None = Field(default=None, min_length=1, max_length=100)
    last_name: str | None = Field(default=None, min_length=1, max_length=100)
    phone: str | None = Field(default=None, max_length=15)

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


class StudentUpdate(BaseModel):
    user: StudentUserUpdate | None = None
    identification: str | None = Field(default=None, min_length=5, max_length=50)
    birth_date: date | None = None
    gender: Gender | None = None
    grade: str | None = Field(default=None, min_length=1, max_length=20)
    parallel: str | None = Field(default=None, max_length=10)
    representative_name: str | None = Field(default=None, max_length=150)
    representative_phone: str | None = Field(default=None, max_length=15)
    representative_email: str | None = Field(default=None, max_length=255)

    @field_validator("identification", "grade", "parallel", "representative_name")
    @classmethod
    def strip_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip()

    @field_validator("identification")
    @classmethod
    def normalize_identification(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip().upper()

    @field_validator("birth_date")
    @classmethod
    def validate_birth_date(cls, value: date | None) -> date | None:
        if value is not None and value > date.today():
            raise ValueError("La fecha de nacimiento no puede ser futura")
        return value

    @field_validator("representative_phone")
    @classmethod
    def validate_representative_phone(cls, value: str | None) -> str | None:
        if value is not None and not is_valid_phone(value):
            raise ValueError("El teléfono del representante debe contener entre 7 y 15 dígitos")
        return value

    @field_validator("representative_email")
    @classmethod
    def validate_representative_email(cls, value: str | None) -> str | None:
        if value is not None and value.strip() and not is_valid_email(value):
            raise ValueError("El correo del representante no es válido")
        return value.strip() if value else None


class StudentStatusUpdate(BaseModel):
    status: UserStatus


class StudentCounselorAssignRequest(BaseModel):
    counselor_id: int = Field(gt=0)


class StudentUserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    first_name: str
    last_name: str
    status: UserStatus
    phone: str | None


class StudentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    institution_id: int
    identification: str
    birth_date: date
    gender: Gender
    grade: str
    parallel: str | None
    representative_name: str | None
    representative_phone: str | None
    representative_email: str | None
    user: StudentUserResponse
    created_at: datetime
    updated_at: datetime


class PaginatedStudents(BaseModel):
    items: list[StudentResponse]
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
    ) -> "PaginatedStudents":
        pages = ceil(total / page_size) if total > 0 else 0
        return cls(
            items=[StudentResponse.model_validate(item) for item in items],
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )
