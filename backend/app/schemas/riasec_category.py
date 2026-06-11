from datetime import datetime

from pydantic import BaseModel, ConfigDict


class RiasecCategoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    code: str
    name: str
    description: str | None
    created_at: datetime
    updated_at: datetime
