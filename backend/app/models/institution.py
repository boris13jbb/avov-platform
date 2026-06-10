from sqlalchemy import Enum, Index, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import InstitutionStatus
from app.db.base import Base
from app.models.mixins import BigIntPKMixin, TimestampMixin


class Institution(Base, BigIntPKMixin, TimestampMixin):
    __tablename__ = "institutions"
    __table_args__ = (
        Index("ix_institutions_status", "status"),
        Index("ix_institutions_province_city", "province", "city"),
    )

    name: Mapped[str] = mapped_column(String(150), nullable=False)
    code: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    province: Mapped[str] = mapped_column(String(100), nullable=False)
    city: Mapped[str] = mapped_column(String(100), nullable=False)
    address: Mapped[str | None] = mapped_column(String(255), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(15), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    logo_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    status: Mapped[InstitutionStatus] = mapped_column(
        Enum(InstitutionStatus, name="institution_status"),
        nullable=False,
        default=InstitutionStatus.ACTIVE,
    )

    users = relationship("User", back_populates="institution")
    students = relationship("Student", back_populates="institution")
