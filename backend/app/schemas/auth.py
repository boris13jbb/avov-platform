from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator

from app.utils.validators import is_strong_password


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1)


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str = Field(min_length=1)
    new_password: str = Field(min_length=8)
    confirm_password: str = Field(min_length=8)

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, value: str) -> str:
        if not is_strong_password(value):
            raise ValueError(
                "La contraseña debe tener al menos 8 caracteres, "
                "una mayúscula, una minúscula, un número y un símbolo"
            )
        return value

    @model_validator(mode="after")
    def validate_passwords(self) -> "ResetPasswordRequest":
        if self.new_password != self.confirm_password:
            raise ValueError("La confirmación de contraseña no coincide")
        return self


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=1)


class LogoutRequest(BaseModel):
    refresh_token: str = Field(min_length=1)


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(min_length=1)
    new_password: str = Field(min_length=8)
    confirm_password: str = Field(min_length=8)

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, value: str) -> str:
        if not is_strong_password(value):
            raise ValueError(
                "La contraseña debe tener al menos 8 caracteres, "
                "una mayúscula, una minúscula, un número y un símbolo"
            )
        return value

    @model_validator(mode="after")
    def validate_passwords(self) -> "ChangePasswordRequest":
        if self.new_password != self.confirm_password:
            raise ValueError("La confirmación de contraseña no coincide")
        return self


class TokenData(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class UserProfileData(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    first_name: str
    last_name: str
    role: str
    status: str
    institution_id: int | None
    phone: str | None
    avatar_url: str | None
    last_login_at: datetime | None
