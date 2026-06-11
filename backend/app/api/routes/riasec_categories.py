from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.responses import success_response
from app.models.user import User
from app.services.riasec_category_service import RiasecCategoryService

router = APIRouter(prefix="/riasec-categories", tags=["Categorías RIASEC"])


@router.get("", dependencies=[Depends(security)])
def list_riasec_categories(
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    categories = RiasecCategoryService(db).list_categories()
    return success_response(
        data=[item.model_dump(mode="json") for item in categories],
        message="Categorías RIASEC obtenidas correctamente",
    )
