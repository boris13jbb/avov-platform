from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session, joinedload

from app.core.enums import AssignmentStatus, Gender, UserRole, UserStatus
from app.models.student import CounselorAssignment, Student
from app.models.user import User
from app.schemas.student import StudentCreate, StudentUpdate, StudentUserUpdate
from app.security.password import hash_password


class StudentRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, student_id: int) -> Student | None:
        stmt = (
            select(Student)
            .options(joinedload(Student.user))
            .where(Student.id == student_id)
        )
        return self.db.scalar(stmt)

    def get_by_identification(self, identification: str) -> Student | None:
        normalized = identification.strip().upper()
        stmt = select(Student).where(Student.identification == normalized)
        return self.db.scalar(stmt)

    def get_by_user_id(self, user_id: int) -> Student | None:
        stmt = (
            select(Student)
            .options(joinedload(Student.user))
            .where(Student.user_id == user_id)
        )
        return self.db.scalar(stmt)

    def list(
        self,
        *,
        page: int = 1,
        page_size: int = 20,
        search: str | None = None,
        institution_id: int | None = None,
        counselor_id: int | None = None,
        status: UserStatus | None = None,
        grade: str | None = None,
        gender: Gender | None = None,
    ) -> tuple[list[Student], int]:
        filters = self._build_filters(
            search,
            institution_id,
            counselor_id,
            status,
            grade,
            gender,
        )
        offset = (page - 1) * page_size

        stmt = (
            select(Student)
            .join(User, Student.user_id == User.id)
            .options(joinedload(Student.user))
            .where(*filters)
            .order_by(User.last_name.asc(), User.first_name.asc())
            .offset(offset)
            .limit(page_size)
        )
        if counselor_id is not None:
            stmt = stmt.join(
                CounselorAssignment,
                CounselorAssignment.student_id == Student.id,
            )

        items = list(self.db.scalars(stmt).unique().all())

        count_stmt = (
            select(func.count())
            .select_from(Student)
            .join(User, Student.user_id == User.id)
            .where(*filters)
        )
        if counselor_id is not None:
            count_stmt = count_stmt.join(
                CounselorAssignment,
                CounselorAssignment.student_id == Student.id,
            )
        total = self.db.scalar(count_stmt) or 0
        return items, total

    def create_with_user(self, payload: StudentCreate) -> Student:
        user = User(
            email=str(payload.user.email).strip().lower(),
            password_hash=hash_password(payload.user.password),
            first_name=payload.user.first_name,
            last_name=payload.user.last_name,
            role=UserRole.STUDENT,
            status=payload.status,
            institution_id=payload.institution_id,
            phone=payload.user.phone,
        )
        self.db.add(user)
        self.db.flush()

        student = Student(
            user_id=user.id,
            institution_id=payload.institution_id,
            identification=payload.identification,
            birth_date=payload.birth_date,
            gender=payload.gender,
            grade=payload.grade,
            parallel=payload.parallel,
            representative_name=payload.representative_name,
            representative_phone=payload.representative_phone,
            representative_email=payload.representative_email,
        )
        self.db.add(student)
        self.db.commit()

        created = self.get_by_id(student.id)
        if created is None:
            raise RuntimeError("No se pudo recuperar el estudiante creado")
        return created

    def update(self, student: Student, payload: StudentUpdate) -> Student:
        student_data = payload.model_dump(exclude_unset=True, exclude={"user"})
        for field, value in student_data.items():
            setattr(student, field, value)

        if payload.user is not None:
            self._apply_user_update(student.user, payload.user)

        self.db.add(student)
        self.db.commit()
        updated = self.get_by_id(student.id)
        if updated is None:
            raise RuntimeError("No se pudo recuperar el estudiante actualizado")
        return updated

    def update_user_status(self, student: Student, status: UserStatus) -> Student:
        student.user.status = status
        self.db.add(student.user)
        self.db.commit()
        updated = self.get_by_id(student.id)
        if updated is None:
            raise RuntimeError("No se pudo recuperar el estudiante actualizado")
        return updated

    def delete(self, student: Student) -> None:
        user_id = student.user_id
        assignments = self.db.scalars(
            select(CounselorAssignment).where(
                CounselorAssignment.student_id == student.id
            )
        ).all()
        for assignment in assignments:
            self.db.delete(assignment)

        self.db.delete(student)
        self.db.commit()

        user = self.db.get(User, user_id)
        if user is not None:
            self.db.delete(user)
            self.db.commit()

    def assign_counselor(
        self,
        *,
        student_id: int,
        counselor_id: int,
        institution_id: int,
    ) -> CounselorAssignment:
        stmt = select(CounselorAssignment).where(
            CounselorAssignment.student_id == student_id,
            CounselorAssignment.counselor_id == counselor_id,
        )
        existing = self.db.scalar(stmt)
        if existing is not None:
            existing.status = AssignmentStatus.ACTIVE
            existing.institution_id = institution_id
            self.db.add(existing)
            self.db.commit()
            self.db.refresh(existing)
            return existing

        assignment = CounselorAssignment(
            counselor_id=counselor_id,
            student_id=student_id,
            institution_id=institution_id,
            status=AssignmentStatus.ACTIVE,
        )
        self.db.add(assignment)
        self.db.commit()
        self.db.refresh(assignment)
        return assignment

    def is_assigned_to_counselor(self, student_id: int, counselor_id: int) -> bool:
        stmt = select(CounselorAssignment.id).where(
            CounselorAssignment.student_id == student_id,
            CounselorAssignment.counselor_id == counselor_id,
            CounselorAssignment.status == AssignmentStatus.ACTIVE,
        )
        return self.db.scalar(stmt) is not None

    @staticmethod
    def _apply_user_update(user: User, payload: StudentUserUpdate) -> None:
        update_data = payload.model_dump(exclude_unset=True)
        if "email" in update_data and update_data["email"] is not None:
            update_data["email"] = str(update_data["email"]).strip().lower()
        for field, value in update_data.items():
            setattr(user, field, value)

    @staticmethod
    def _build_filters(
        search: str | None,
        institution_id: int | None,
        counselor_id: int | None,
        status: UserStatus | None,
        grade: str | None,
        gender: Gender | None,
    ) -> list:
        filters = []

        if institution_id is not None:
            filters.append(Student.institution_id == institution_id)

        if counselor_id is not None:
            filters.append(CounselorAssignment.counselor_id == counselor_id)
            filters.append(CounselorAssignment.status == AssignmentStatus.ACTIVE)

        if status is not None:
            filters.append(User.status == status)

        if grade:
            filters.append(func.lower(Student.grade).like(f"%{grade.strip().lower()}%"))

        if gender is not None:
            filters.append(Student.gender == gender)

        if search:
            term = f"%{search.strip().lower()}%"
            filters.append(
                or_(
                    func.lower(User.first_name).like(term),
                    func.lower(User.last_name).like(term),
                    func.lower(User.email).like(term),
                    func.lower(Student.identification).like(term),
                )
            )

        return filters
