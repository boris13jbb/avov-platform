from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class SystemSettingResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    key: str
    value: str
    description: str | None
    updated_by: int | None
    created_at: datetime
    updated_at: datetime


class SystemSettingUpdate(BaseModel):
    value: str = Field(min_length=1)

    @field_validator("value")
    @classmethod
    def strip_value(cls, value: str) -> str:
        return value.strip()


class PublicSystemSettingsResponse(BaseModel):
    app_display_name: str
    ethical_disclaimer: str
    maintenance_mode: bool
