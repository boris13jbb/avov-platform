from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.system import SystemSetting


class SystemSettingRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_all(self) -> list[SystemSetting]:
        stmt = select(SystemSetting).order_by(SystemSetting.key.asc())
        return list(self.db.scalars(stmt).all())

    def get_by_key(self, key: str) -> SystemSetting | None:
        stmt = select(SystemSetting).where(SystemSetting.key == key)
        return self.db.scalar(stmt)

    def create(self, *, key: str, value: str, description: str | None) -> SystemSetting:
        setting = SystemSetting(key=key, value=value, description=description)
        self.db.add(setting)
        self.db.commit()
        self.db.refresh(setting)
        return setting

    def update(
        self,
        setting: SystemSetting,
        *,
        value: str,
        updated_by: int | None,
    ) -> SystemSetting:
        setting.value = value
        setting.updated_by = updated_by
        self.db.commit()
        self.db.refresh(setting)
        return setting
