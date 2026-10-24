from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from app.core.enums import AssignmentStatus
from app.models.student import CounselorAssignment, Student
from app.models.user import User

ASSIGNMENT_UNIQUE_CONSTRAINT = "uq_counselor_assignments"


class AssignmentRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, assignment_id: int) -> CounselorAssignment | None:
        stmt = (
            select(CounselorAssignment)
            .options(
                joinedload(CounselorAssignment.student).joinedload(Student.user),
            )
            .where(CounselorAssignment.id == assignment_id)
        )
        return self.db.scalars(stmt).unique().first()

    def get_by_pair(
        self,
        *,
        counselor_id: int,
        student_id: int,
    ) -> CounselorAssignment | None:
        stmt = select(CounselorAssignment).where(
            CounselorAssignment.counselor_id == counselor_id,
            CounselorAssignment.student_id == student_id,
        )
        return self.db.scalar(stmt)

    def list(
        self,
        *,
        page: int,
        page_size: int,
        institution_id: int | None = None,
        counselor_id: int | None = None,
        student_id: int | None = None,
        status: AssignmentStatus | None = None,
    ) -> tuple[list[CounselorAssignment], int]:
        filters: list = []
        if institution_id is not None:
            filters.append(CounselorAssignment.institution_id == institution_id)
        if counselor_id is not None:
            filters.append(CounselorAssignment.counselor_id == counselor_id)
        if student_id is not None:
            filters.append(CounselorAssignment.student_id == student_id)
        if status is not None:
            filters.append(CounselorAssignment.status == status)

        offset = (page - 1) * page_size
        stmt = (
            select(CounselorAssignment)
            .options(
                joinedload(CounselorAssignment.student).joinedload(Student.user),
            )
            .where(*filters)
            .order_by(CounselorAssignment.id.desc())
            .offset(offset)
            .limit(page_size)
        )
        items = list(self.db.scalars(stmt).unique().all())

        count_stmt = select(func.count()).select_from(CounselorAssignment)
        if filters:
            count_stmt = count_stmt.where(*filters)
        total = self.db.scalar(count_stmt) or 0
        return items, total

    def create(
        self,
        *,
        counselor_id: int,
        student_id: int,
        institution_id: int,
        status: AssignmentStatus = AssignmentStatus.ACTIVE,
    ) -> CounselorAssignment:
        row = CounselorAssignment(
            counselor_id=counselor_id,
            student_id=student_id,
            institution_id=institution_id,
            status=status,
        )
        self.db.add(row)
        try:
            self.db.commit()
        except IntegrityError:
            self.db.rollback()
            raise
        loaded = self.get_by_id(row.id)
        if loaded is None:
            raise RuntimeError("No se pudo recuperar la asignación creada")
        return loaded

    def save(self, assignment: CounselorAssignment) -> CounselorAssignment:
        self.db.add(assignment)
        try:
            self.db.commit()
        except IntegrityError:
            self.db.rollback()
            raise
        loaded = self.get_by_id(assignment.id)
        if loaded is None:
            raise RuntimeError("No se pudo recuperar la asignación actualizada")
        return loaded

    @staticmethod
    def is_assignment_unique_violation(exc: IntegrityError) -> bool:
        """True solo para la restricción única counselor+student."""
        parts: list[str] = []
        orig = getattr(exc, "orig", None)
        if orig is not None:
            parts.append(str(orig))
            args = getattr(orig, "args", ())
            for arg in args:
                parts.append(str(arg))
        parts.append(str(exc))
        blob = " ".join(parts).lower()
        return ASSIGNMENT_UNIQUE_CONSTRAINT in blob

    def get_counselor_user(self, counselor_id: int) -> User | None:
        return self.db.get(User, counselor_id)
