from datetime import date, datetime

from sqlalchemy import (
    BigInteger,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import AssignmentStatus, Gender
from app.db.base import Base
from app.models.mixins import BigIntPKMixin, TimestampMixin


class Student(Base, BigIntPKMixin, TimestampMixin):
    __tablename__ = "students"
    __table_args__ = (Index("ix_students_institution_id", "institution_id"),)

    user_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        unique=True,
    )
    institution_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("institutions.id", ondelete="RESTRICT"),
        nullable=False,
    )
    identification: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    birth_date: Mapped[date] = mapped_column(Date, nullable=False)
    gender: Mapped[Gender] = mapped_column(
        Enum(Gender, name="gender"),
        nullable=False,
        default=Gender.NOT_SPECIFIED,
    )
    grade: Mapped[str] = mapped_column(String(20), nullable=False)
    parallel: Mapped[str | None] = mapped_column(String(10), nullable=True)
    representative_name: Mapped[str | None] = mapped_column(String(150), nullable=True)
    representative_phone: Mapped[str | None] = mapped_column(String(15), nullable=True)
    representative_email: Mapped[str | None] = mapped_column(String(255), nullable=True)

    user = relationship("User", back_populates="student_profile")
    institution = relationship("Institution", back_populates="students")
    test_sessions = relationship("TestSession", back_populates="student")
    riasec_results = relationship("RiasecResult", back_populates="student")
    recommendations = relationship("Recommendation", back_populates="student")
    reports = relationship("Report", back_populates="student")
    counselor_assignments = relationship("CounselorAssignment", back_populates="student")


class CounselorAssignment(Base, BigIntPKMixin, TimestampMixin):
    __tablename__ = "counselor_assignments"
    __table_args__ = (
        UniqueConstraint("counselor_id", "student_id", name="uq_counselor_assignments"),
        Index("ix_counselor_assignments_institution_id", "institution_id"),
    )

    counselor_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    student_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("students.id", ondelete="RESTRICT"),
        nullable=False,
    )
    institution_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("institutions.id", ondelete="RESTRICT"),
        nullable=False,
    )
    assigned_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.now(),
    )
    status: Mapped[AssignmentStatus] = mapped_column(
        Enum(AssignmentStatus, name="assignment_status"),
        nullable=False,
        default=AssignmentStatus.ACTIVE,
    )

    student = relationship("Student", back_populates="counselor_assignments")
