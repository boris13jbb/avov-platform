from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.enums import UserRole, UserStatus
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate
from app.security.password import hash_password


class UserRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_email(self, email: str) -> User | None:
        normalized_email = email.strip().lower()
        stmt = select(User).where(User.email == normalized_email)
        return self.db.scalar(stmt)

    def get_by_id(self, user_id: int) -> User | None:
        return self.db.get(User, user_id)

    def list(
        self,
        *,
        page: int = 1,
        page_size: int = 20,
        search: str | None = None,
        role: UserRole | None = None,
        institution_id: int | None = None,
        status: UserStatus | None = None,
    ) -> tuple[list[User], int]:
        filters = self._build_filters(search, role, institution_id, status)
        offset = (page - 1) * page_size

        stmt = (
            select(User)
            .where(*filters)
            .order_by(User.last_name.asc(), User.first_name.asc())
            .offset(offset)
            .limit(page_size)
        )
        items = list(self.db.scalars(stmt).all())

        count_stmt = select(func.count()).select_from(User).where(*filters)
        total = self.db.scalar(count_stmt) or 0
        return items, total

    def create(self, payload: UserCreate) -> User:
        user = User(
            email=str(payload.email).strip().lower(),
            password_hash=hash_password(payload.password),
            first_name=payload.first_name,
            last_name=payload.last_name,
            role=payload.role,
            status=payload.status,
            institution_id=payload.institution_id,
            phone=payload.phone,
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def create_raw(
        self,
        *,
        email: str,
        password: str,
        first_name: str,
        last_name: str,
        role: UserRole,
        status: UserStatus = UserStatus.ACTIVE,
        institution_id: int | None = None,
        phone: str | None = None,
    ) -> User:
        user = User(
            email=email.strip().lower(),
            password_hash=hash_password(password),
            first_name=first_name,
            last_name=last_name,
            role=role,
            status=status,
            institution_id=institution_id,
            phone=phone,
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def update_last_login(self, user: User) -> None:
        from datetime import datetime, timezone

        user.last_login_at = datetime.now(timezone.utc).replace(tzinfo=None)
        self.db.add(user)
        self.db.commit()

    def update_password(self, user: User, password_hash: str) -> None:
        user.password_hash = password_hash
        self.db.add(user)
        self.db.commit()

    def update(self, user: User, payload: UserUpdate) -> User:
        update_data = payload.model_dump(exclude_unset=True)
        if "email" in update_data and update_data["email"] is not None:
            update_data["email"] = str(update_data["email"]).strip().lower()

        for field, value in update_data.items():
            setattr(user, field, value)

        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def update_status(self, user: User, status: UserStatus) -> User:
        user.status = status
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def delete(self, user: User) -> None:
        self.db.delete(user)
        self.db.commit()

    @staticmethod
    def _build_filters(
        search: str | None,
        role: UserRole | None,
        institution_id: int | None,
        status: UserStatus | None,
    ) -> list:
        filters = []

        if role is not None:
            filters.append(User.role == role)

        if institution_id is not None:
            filters.append(User.institution_id == institution_id)

        if status is not None:
            filters.append(User.status == status)

        if search:
            term = f"%{search.strip().lower()}%"
            filters.append(
                or_(
                    func.lower(User.first_name).like(term),
                    func.lower(User.last_name).like(term),
                    func.lower(User.email).like(term),
                )
            )

        return filters
