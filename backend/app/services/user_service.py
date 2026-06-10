from sqlalchemy.orm import Session

from app.core.enums import InstitutionStatus, UserRole, UserStatus
from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.models.user import User
from app.repositories.institution_repository import InstitutionRepository
from app.repositories.user_repository import UserRepository
from app.schemas.user import (
    PaginatedUsers,
    UserCreate,
    UserResponse,
    UserStatusUpdate,
    UserUpdate,
)


class UserService:
    MAX_PAGE_SIZE = 100
    INSTITUTION_ADMIN_MANAGEABLE_ROLES = {UserRole.COUNSELOR, UserRole.STUDENT}

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = UserRepository(db)
        self.institution_repo = InstitutionRepository(db)

    def list_users(
        self,
        current_user: User,
        *,
        page: int = 1,
        page_size: int = 20,
        search: str | None = None,
        role: UserRole | None = None,
        institution_id: int | None = None,
        status: UserStatus | None = None,
    ) -> PaginatedUsers:
        self._ensure_admin_access(current_user)

        if page < 1:
            raise ValidationException("La página debe ser mayor o igual a 1")
        if page_size < 1 or page_size > self.MAX_PAGE_SIZE:
            raise ValidationException(
                f"El tamaño de página debe estar entre 1 y {self.MAX_PAGE_SIZE}"
            )

        scoped_institution_id = self._resolve_list_institution_filter(
            current_user,
            institution_id,
        )

        items, total = self.repo.list(
            page=page,
            page_size=page_size,
            search=search,
            role=role,
            institution_id=scoped_institution_id,
            status=status,
        )
        return PaginatedUsers.build(items, total, page, page_size)

    def get_user(self, user_id: int, current_user: User) -> UserResponse:
        user = self._get_or_404(user_id)
        self._ensure_can_view(user, current_user)
        return UserResponse.model_validate(user)

    def create_user(self, payload: UserCreate, current_user: User) -> UserResponse:
        self._ensure_admin_access(current_user)

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            payload = payload.model_copy(
                update={"institution_id": current_user.institution_id}
            )

        self._validate_create_permissions(payload, current_user)
        self._validate_institution(payload.role, payload.institution_id)

        if self.repo.get_by_email(str(payload.email)):
            raise ValidationException("El correo electrónico ya está registrado")

        user = self.repo.create(payload)
        return UserResponse.model_validate(user)

    def update_user(
        self,
        user_id: int,
        payload: UserUpdate,
        current_user: User,
    ) -> UserResponse:
        user = self._get_or_404(user_id)
        self._ensure_can_manage(user, current_user)

        if not payload.model_dump(exclude_unset=True):
            raise ValidationException("Debe enviar al menos un campo para actualizar")

        update_data = payload.model_dump(exclude_unset=True)
        target_role = update_data.get("role", user.role)
        target_institution_id = update_data.get("institution_id", user.institution_id)

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if target_role not in self.INSTITUTION_ADMIN_MANAGEABLE_ROLES:
                raise ForbiddenException("No tienes permisos para asignar este rol")
            target_institution_id = current_user.institution_id

        if "role" in update_data or "institution_id" in update_data:
            self._validate_institution(target_role, target_institution_id)

        if payload.email:
            existing = self.repo.get_by_email(str(payload.email))
            if existing and existing.id != user.id:
                raise ValidationException("El correo electrónico ya está registrado")

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            payload = payload.model_copy(
                update={"institution_id": current_user.institution_id}
            )

        updated = self.repo.update(user, payload)
        return UserResponse.model_validate(updated)

    def update_user_status(
        self,
        user_id: int,
        payload: UserStatusUpdate,
        current_user: User,
    ) -> UserResponse:
        user = self._get_or_404(user_id)
        self._ensure_can_manage(user, current_user)

        if user.id == current_user.id:
            raise ValidationException("No puedes cambiar tu propio estado")

        updated = self.repo.update_status(user, payload.status)
        return UserResponse.model_validate(updated)

    def _get_or_404(self, user_id: int) -> User:
        user = self.repo.get_by_id(user_id)
        if user is None:
            raise NotFoundException("Usuario no encontrado")
        return user

    @staticmethod
    def _ensure_admin_access(current_user: User) -> None:
        if current_user.role not in {UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN}:
            raise ForbiddenException("No tienes permisos para esta acción")

    def _resolve_list_institution_filter(
        self,
        current_user: User,
        institution_id: int | None,
    ) -> int | None:
        if current_user.role == UserRole.SUPER_ADMIN:
            return institution_id

        if institution_id and institution_id != current_user.institution_id:
            raise ForbiddenException("No tienes permisos para ver usuarios de otra institución")

        return current_user.institution_id

    def _validate_create_permissions(
        self,
        payload: UserCreate,
        current_user: User,
    ) -> None:
        if current_user.role == UserRole.SUPER_ADMIN:
            return

        if payload.role not in self.INSTITUTION_ADMIN_MANAGEABLE_ROLES:
            raise ForbiddenException("No tienes permisos para crear usuarios con este rol")

        if payload.institution_id != current_user.institution_id:
            raise ForbiddenException(
                "Solo puedes crear usuarios para tu propia institución"
            )

    def _validate_institution(
        self,
        role: UserRole,
        institution_id: int | None,
    ) -> None:
        if role == UserRole.SUPER_ADMIN:
            if institution_id is not None:
                raise ValidationException("Un SUPER_ADMIN no debe tener institution_id")
            return

        if institution_id is None:
            raise ValidationException("institution_id es obligatorio para este rol")

        institution = self.institution_repo.get_by_id(institution_id)
        if institution is None:
            raise NotFoundException("Institución no encontrada")
        if institution.status != InstitutionStatus.ACTIVE:
            raise ValidationException("La institución no está activa")

    def _ensure_can_view(self, user: User, current_user: User) -> None:
        if current_user.id == user.id:
            return

        if current_user.role == UserRole.SUPER_ADMIN:
            return

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if (
                user.institution_id == current_user.institution_id
                and user.role in self.INSTITUTION_ADMIN_MANAGEABLE_ROLES
            ):
                return
            raise ForbiddenException("No tienes permisos para ver este usuario")

        raise ForbiddenException("No tienes permisos para ver este usuario")

    def _ensure_can_manage(self, user: User, current_user: User) -> None:
        if current_user.role == UserRole.SUPER_ADMIN:
            if user.role == UserRole.SUPER_ADMIN and user.id != current_user.id:
                return
            return

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if user.institution_id != current_user.institution_id:
                raise ForbiddenException("No tienes permisos para gestionar este usuario")
            if user.role not in self.INSTITUTION_ADMIN_MANAGEABLE_ROLES:
                raise ForbiddenException("No tienes permisos para gestionar este usuario")
            return

        raise ForbiddenException("No tienes permisos para gestionar este usuario")
