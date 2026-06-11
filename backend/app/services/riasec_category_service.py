from sqlalchemy.orm import Session

from app.repositories.riasec_category_repository import RiasecCategoryRepository
from app.schemas.riasec_category import RiasecCategoryResponse


class RiasecCategoryService:
    def __init__(self, db: Session) -> None:
        self.repo = RiasecCategoryRepository(db)

    def list_categories(self) -> list[RiasecCategoryResponse]:
        categories = self.repo.list_all()
        return [RiasecCategoryResponse.model_validate(item) for item in categories]
