"""Seed administrador institucional de prueba (FASE 28)."""

from __future__ import annotations

import sys

from sqlalchemy import select

from app.core.enums import UserRole, UserStatus
from app.db.session import SessionLocal
from app.models.student import Student
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.security.password import hash_password

INSTITUTION_ADMIN_EMAIL = "admin.institucion.test.fase28@instituto.edu.co"
INSTITUTION_ADMIN_PASSWORD = "InstAdmin1234!"
STUDENT_EMAIL = "estudiante.test.fase11@instituto.edu.co"


def main() -> int:
    session = SessionLocal()
    try:
        student = session.scalar(
            select(Student)
            .join(User, Student.user_id == User.id)
            .where(User.email == STUDENT_EMAIL)
        )
        if student is None:
            print(
                f"No se encontró el estudiante {STUDENT_EMAIL}. "
                "Créalo primero en el entorno de desarrollo."
            )
            return 1

        user_repo = UserRepository(session)
        admin = user_repo.get_by_email(INSTITUTION_ADMIN_EMAIL)
        if admin is None:
            admin = user_repo.create_raw(
                email=INSTITUTION_ADMIN_EMAIL,
                password=INSTITUTION_ADMIN_PASSWORD,
                first_name="Admin",
                last_name="Institución F28",
                role=UserRole.INSTITUTION_ADMIN,
                status=UserStatus.ACTIVE,
                institution_id=student.institution_id,
            )
            print(f"Administrador institucional creado: {INSTITUTION_ADMIN_EMAIL}")
        else:
            admin.institution_id = student.institution_id
            admin.status = UserStatus.ACTIVE
            admin.role = UserRole.INSTITUTION_ADMIN
            admin.password_hash = hash_password(INSTITUTION_ADMIN_PASSWORD)
            session.add(admin)
            session.commit()
            print(f"Administrador institucional actualizado: {INSTITUTION_ADMIN_EMAIL}")

        print(f"Institución vinculada: {student.institution_id}")
        print(
            "Credenciales admin institucional: "
            f"{INSTITUTION_ADMIN_EMAIL} / {INSTITUTION_ADMIN_PASSWORD}"
        )
        return 0
    finally:
        session.close()


if __name__ == "__main__":
    sys.exit(main())
