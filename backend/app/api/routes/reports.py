from fastapi import APIRouter, Depends, Request
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.models.user import User
from app.services.report_service import ReportService

router = APIRouter(prefix="/reports", tags=["Reportes"])


@router.get("/{session_id}/pdf", dependencies=[Depends(security)])
def download_session_pdf(
    session_id: int,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Genera o descarga el PDF de una evaluación COMPLETED autorizada."""
    forwarded = request.headers.get("x-forwarded-for")
    ip_address = None
    if forwarded:
        ip_address = forwarded.split(",")[-1].strip() or None
    if not ip_address and request.client:
        ip_address = request.client.host

    user_agent = request.headers.get("user-agent")
    if user_agent and len(user_agent) > 500:
        user_agent = user_agent[:500]

    result = ReportService(db).get_session_pdf(
        session_id,
        current_user,
        ip_address=ip_address,
        user_agent=user_agent,
    )
    headers = {
        "Content-Disposition": f'attachment; filename="{result.filename}"',
        "X-Report-Code": result.report_code,
        "Cache-Control": "no-store",
    }
    return Response(
        content=result.content,
        media_type="application/pdf",
        headers=headers,
    )
