from sqlalchemy import BigInteger, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import BigIntPKMixin, TimestampMixin


class Report(Base, BigIntPKMixin, TimestampMixin):
    __tablename__ = "reports"

    student_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("students.id", ondelete="RESTRICT"),
        nullable=False,
    )
    test_session_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("test_sessions.id", ondelete="RESTRICT"),
        nullable=False,
    )
    file_path: Mapped[str] = mapped_column(String(500), nullable=False)
    report_code: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    generated_by: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )

    student = relationship("Student", back_populates="reports")
    test_session = relationship("TestSession", back_populates="reports")
