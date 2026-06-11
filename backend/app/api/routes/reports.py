from fastapi import APIRouter, Depends, Request
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.responses import success_response
from app.models.user import User
from app.services.pdf_service import PDFService

router = APIRouter(prefix="/reports", tags=["Reportes PDF"])


@router.get("/{test_session_id}/pdf", dependencies=[Depends(security)])
def download_report_pdf(
    test_session_id: int,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = PDFService(db).download_pdf(test_session_id, current_user, request)
    return Response(
        content=result.content,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{result.report_code}.pdf"',
            "X-Report-Code": result.report_code,
            "X-Report-Generated": "true" if result.generated else "false",
        },
    )


@router.get("/student/{student_id}", dependencies=[Depends(security)])
def list_student_reports(
    student_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = PDFService(db).list_by_student(student_id, current_user)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Historial de reportes obtenido correctamente",
    )
