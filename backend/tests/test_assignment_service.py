"""Pruebas unitarias del servicio de asignaciones (sin escritura en MySQL)."""

from __future__ import annotations

from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import MagicMock

import pytest
from sqlalchemy.exc import IntegrityError

from app.core.enums import AssignmentStatus, UserRole, UserStatus
from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.repositories.assignment_repository import AssignmentRepository
from app.schemas.assignment import AssignmentCreate, AssignmentStatusUpdate
from app.services.assignment_service import AssignmentService


def _integrity(message: str) -> IntegrityError:
    return IntegrityError("INSERT INTO counselor_assignments", {}, Exception(message))


def _user(
    *,
    user_id: int = 1,
    role: UserRole = UserRole.INSTITUTION_ADMIN,
    institution_id: int | None = 10,
    status: UserStatus = UserStatus.ACTIVE,
) -> SimpleNamespace:
    return SimpleNamespace(
        id=user_id,
        role=role,
        institution_id=institution_id,
        status=status,
        email=f"user{user_id}@test.edu",
        first_name="Nombre",
        last_name="Apellido",
    )


def _student(
    *,
    student_id: int = 100,
    institution_id: int = 10,
    user_status: UserStatus = UserStatus.ACTIVE,
) -> SimpleNamespace:
    return SimpleNamespace(
        id=student_id,
        institution_id=institution_id,
        identification="ID100",
        user=SimpleNamespace(
            id=200,
            email="stu@test.edu",
            first_name="Est",
            last_name="Udiante",
            status=user_status,
        ),
    )


def _assignment(
    *,
    assignment_id: int = 1,
    counselor_id: int = 5,
    student_id: int = 100,
    institution_id: int = 10,
    status: AssignmentStatus = AssignmentStatus.ACTIVE,
    student: SimpleNamespace | None = None,
) -> SimpleNamespace:
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    return SimpleNamespace(
        id=assignment_id,
        counselor_id=counselor_id,
        student_id=student_id,
        institution_id=institution_id,
        status=status,
        assigned_at=now,
        created_at=now,
        updated_at=now,
        student=student or _student(student_id=student_id, institution_id=institution_id),
    )


def _service() -> tuple[AssignmentService, MagicMock, MagicMock, MagicMock]:
    db = MagicMock()
    service = AssignmentService(db)
    service.repo = MagicMock()
    service.student_repo = MagicMock()
    service.user_repo = MagicMock()
    return service, service.repo, service.student_repo, service.user_repo


def test_create_assignment_success():
    service, repo, student_repo, user_repo = _service()
    admin = _user()
    student = _student()
    counselor = _user(user_id=5, role=UserRole.COUNSELOR, institution_id=10)
    created = _assignment(student=student)

    student_repo.get_by_id.return_value = student
    user_repo.get_by_id.side_effect = lambda uid: counselor if uid == 5 else counselor
    repo.get_by_pair.return_value = None
    repo.create.return_value = created

    result = service.create_assignment(
        AssignmentCreate(student_id=100, counselor_id=5),
        admin,
    )

    assert result.student_id == 100
    assert result.counselor_id == 5
    assert result.status == AssignmentStatus.ACTIVE
    repo.create.assert_called_once()


def test_create_reactivates_inactive_pair():
    service, repo, student_repo, user_repo = _service()
    admin = _user()
    student = _student()
    counselor = _user(user_id=5, role=UserRole.COUNSELOR)
    existing = _assignment(status=AssignmentStatus.INACTIVE, student=student)

    student_repo.get_by_id.return_value = student
    user_repo.get_by_id.return_value = counselor
    repo.get_by_pair.return_value = existing
    repo.save.return_value = existing

    result = service.create_assignment(
        AssignmentCreate(student_id=100, counselor_id=5),
        admin,
    )

    assert existing.status == AssignmentStatus.ACTIVE
    assert result.status == AssignmentStatus.ACTIVE
    repo.create.assert_not_called()
    repo.save.assert_called_once()


def test_create_rejects_duplicate_active():
    service, repo, student_repo, user_repo = _service()
    admin = _user()
    student = _student()
    counselor = _user(user_id=5, role=UserRole.COUNSELOR)
    existing = _assignment(status=AssignmentStatus.ACTIVE, student=student)

    student_repo.get_by_id.return_value = student
    user_repo.get_by_id.return_value = counselor
    repo.get_by_pair.return_value = existing

    with pytest.raises(ValidationException, match="asignación activa"):
        service.create_assignment(
            AssignmentCreate(student_id=100, counselor_id=5),
            admin,
        )


def test_create_integrity_collision_active_becomes_validation_error():
    service, repo, student_repo, user_repo = _service()
    admin = _user()
    student = _student()
    counselor = _user(user_id=5, role=UserRole.COUNSELOR)
    raced = _assignment(status=AssignmentStatus.ACTIVE, student=student)

    student_repo.get_by_id.return_value = student
    user_repo.get_by_id.return_value = counselor
    repo.get_by_pair.side_effect = [None, raced]
    repo.create.side_effect = _integrity(
        "Duplicate entry '5-100' for key 'uq_counselor_assignments'"
    )

    with pytest.raises(ValidationException, match="asignación activa"):
        service.create_assignment(
            AssignmentCreate(student_id=100, counselor_id=5),
            admin,
        )
    assert repo.create.call_count == 1


def test_create_integrity_collision_inactive_reactivates():
    service, repo, student_repo, user_repo = _service()
    admin = _user()
    student = _student()
    counselor = _user(user_id=5, role=UserRole.COUNSELOR)
    raced = _assignment(status=AssignmentStatus.INACTIVE, student=student)

    student_repo.get_by_id.return_value = student
    user_repo.get_by_id.return_value = counselor
    repo.get_by_pair.side_effect = [None, raced]
    repo.create.side_effect = _integrity(
        "Duplicate entry for key 'uq_counselor_assignments'"
    )
    repo.save.return_value = raced

    result = service.create_assignment(
        AssignmentCreate(student_id=100, counselor_id=5),
        admin,
    )

    assert raced.status == AssignmentStatus.ACTIVE
    assert result.status == AssignmentStatus.ACTIVE
    repo.save.assert_called_once()


def test_create_unrelated_integrity_error_is_not_masked():
    service, repo, student_repo, user_repo = _service()
    admin = _user()
    student = _student()
    counselor = _user(user_id=5, role=UserRole.COUNSELOR)

    student_repo.get_by_id.return_value = student
    user_repo.get_by_id.return_value = counselor
    repo.get_by_pair.return_value = None
    repo.create.side_effect = _integrity(
        "Cannot add or update a child row: a foreign key constraint fails"
    )

    with pytest.raises(IntegrityError):
        service.create_assignment(
            AssignmentCreate(student_id=100, counselor_id=5),
            admin,
        )


def test_is_assignment_unique_violation_detection():
    assert AssignmentRepository.is_assignment_unique_violation(
        _integrity("Duplicate entry for key 'uq_counselor_assignments'")
    )
    assert not AssignmentRepository.is_assignment_unique_violation(
        _integrity("foreign key constraint fails on students")
    )


def test_create_rejects_cross_institution():
    service, repo, student_repo, user_repo = _service()
    admin = _user(institution_id=10)
    student = _student(institution_id=10)
    counselor = _user(user_id=5, role=UserRole.COUNSELOR, institution_id=99)

    student_repo.get_by_id.return_value = student
    user_repo.get_by_id.return_value = counselor

    with pytest.raises(ValidationException, match="misma institución"):
        service.create_assignment(
            AssignmentCreate(student_id=100, counselor_id=5),
            admin,
        )


def test_create_rejects_non_counselor_role():
    service, _, student_repo, user_repo = _service()
    admin = _user()
    student = _student()
    not_counselor = _user(user_id=5, role=UserRole.STUDENT)

    student_repo.get_by_id.return_value = student
    user_repo.get_by_id.return_value = not_counselor

    with pytest.raises(ValidationException, match="rol de orientador"):
        service.create_assignment(
            AssignmentCreate(student_id=100, counselor_id=5),
            admin,
        )


def test_create_forbidden_for_counselor():
    service, _, _, _ = _service()
    counselor = _user(role=UserRole.COUNSELOR)

    with pytest.raises(ForbiddenException):
        service.create_assignment(
            AssignmentCreate(student_id=100, counselor_id=5),
            counselor,
        )


def test_create_student_not_found():
    service, _, student_repo, _ = _service()
    student_repo.get_by_id.return_value = None

    with pytest.raises(NotFoundException, match="Estudiante"):
        service.create_assignment(
            AssignmentCreate(student_id=999, counselor_id=5),
            _user(),
        )


def test_create_counselor_not_found():
    service, _, student_repo, user_repo = _service()
    student_repo.get_by_id.return_value = _student()
    user_repo.get_by_id.return_value = None

    with pytest.raises(NotFoundException, match="Orientador"):
        service.create_assignment(
            AssignmentCreate(student_id=100, counselor_id=999),
            _user(),
        )


def test_institution_admin_cannot_manage_other_institution():
    service, repo, student_repo, user_repo = _service()
    admin = _user(institution_id=10)
    student = _student(institution_id=20)
    counselor = _user(user_id=5, role=UserRole.COUNSELOR, institution_id=20)

    student_repo.get_by_id.return_value = student
    user_repo.get_by_id.return_value = counselor

    with pytest.raises(ForbiddenException, match="otra institución"):
        service.create_assignment(
            AssignmentCreate(student_id=100, counselor_id=5),
            admin,
        )


def test_list_counselor_forced_to_own_id():
    service, repo, _, _ = _service()
    counselor = _user(user_id=5, role=UserRole.COUNSELOR, institution_id=10)
    repo.list.return_value = ([], 0)

    service.list_assignments(counselor, page=1, page_size=20)

    kwargs = repo.list.call_args.kwargs
    assert kwargs["counselor_id"] == 5
    assert kwargs["institution_id"] == 10


def test_list_counselor_cannot_filter_other_counselor_explicitly():
    service, _, _, _ = _service()
    counselor = _user(user_id=5, role=UserRole.COUNSELOR)

    with pytest.raises(ForbiddenException, match="propias asignaciones"):
        service.list_assignments(counselor, counselor_id=7)


def test_deactivate_and_reactivate():
    service, repo, _, user_repo = _service()
    admin = _user()
    row = _assignment(status=AssignmentStatus.ACTIVE)
    user_repo.get_by_id.return_value = _user(user_id=5, role=UserRole.COUNSELOR)
    repo.get_by_id.return_value = row
    repo.save.return_value = row

    deactivated = service.update_status(
        1,
        AssignmentStatusUpdate(status=AssignmentStatus.INACTIVE),
        admin,
    )
    assert row.status == AssignmentStatus.INACTIVE
    assert deactivated.status == AssignmentStatus.INACTIVE

    row.status = AssignmentStatus.INACTIVE
    reactivated = service.update_status(
        1,
        AssignmentStatusUpdate(status=AssignmentStatus.ACTIVE),
        admin,
    )
    assert row.status == AssignmentStatus.ACTIVE
    assert reactivated.status == AssignmentStatus.ACTIVE


def test_update_status_same_value_rejected():
    service, repo, _, _ = _service()
    admin = _user()
    repo.get_by_id.return_value = _assignment(status=AssignmentStatus.ACTIVE)

    with pytest.raises(ValidationException, match="ya se encuentra"):
        service.update_status(
            1,
            AssignmentStatusUpdate(status=AssignmentStatus.ACTIVE),
            admin,
        )


def test_get_forbidden_for_other_counselor():
    service, repo, _, _ = _service()
    counselor = _user(user_id=5, role=UserRole.COUNSELOR)
    repo.get_by_id.return_value = _assignment(counselor_id=8)

    with pytest.raises(ForbiddenException):
        service.get_assignment(1, counselor)


def test_student_cannot_list():
    service, _, _, _ = _service()
    student = _user(role=UserRole.STUDENT)

    with pytest.raises(ForbiddenException):
        service.list_assignments(student)
