from sqlalchemy.orm import Session

from app.core.exceptions import NotFoundException, ValidationException
from app.models.user import User
from app.repositories.system_setting_repository import SystemSettingRepository
from app.schemas.system_setting import (
    PublicSystemSettingsResponse,
    SystemSettingResponse,
    SystemSettingUpdate,
)
from app.services.audit_service import AuditService

DEFAULT_SETTINGS: dict[str, dict[str, str]] = {
    "app_display_name": {
        "value": "AVOV",
        "description": "Nombre visible de la aplicación",
    },
    "ethical_disclaimer": {
        "value": (
            "Este resultado es orientativo y no reemplaza la orientación profesional "
            "de un psicólogo, docente u orientador educativo."
        ),
        "description": "Mensaje ético mostrado en resultados y reportes",
    },
    "max_recommendations_per_session": {
        "value": "10",
        "description": "Máximo de carreras recomendadas por sesión de test",
    },
    "maintenance_mode": {
        "value": "false",
        "description": "Modo mantenimiento (true/false)",
    },
}


class SystemSettingService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = SystemSettingRepository(db)
        self.audit = AuditService(db)

    PUBLIC_KEYS = ("app_display_name", "ethical_disclaimer", "maintenance_mode")

    def list_settings(self) -> list[SystemSettingResponse]:
        self._ensure_defaults()
        items = self.repo.list_all()
        return [SystemSettingResponse.model_validate(item) for item in items]

    def get_public_settings(self) -> PublicSystemSettingsResponse:
        self._ensure_defaults()
        values = {
            item.key: item.value
            for item in self.repo.list_all()
            if item.key in self.PUBLIC_KEYS
        }
        maintenance_raw = values.get("maintenance_mode", "false").strip().lower()
        return PublicSystemSettingsResponse(
            app_display_name=values.get(
                "app_display_name",
                DEFAULT_SETTINGS["app_display_name"]["value"],
            ),
            ethical_disclaimer=values.get(
                "ethical_disclaimer",
                DEFAULT_SETTINGS["ethical_disclaimer"]["value"],
            ),
            maintenance_mode=maintenance_raw == "true",
        )

    def is_maintenance_mode(self) -> bool:
        return self.get_public_settings().maintenance_mode

    def update_setting(
        self,
        key: str,
        payload: SystemSettingUpdate,
        current_user: User,
    ) -> SystemSettingResponse:
        if key not in DEFAULT_SETTINGS:
            raise NotFoundException("Parámetro de configuración no encontrado")

        self._ensure_defaults()
        self._validate_value(key, payload.value)

        setting = self.repo.get_by_key(key)
        if setting is None:
            raise NotFoundException("Parámetro de configuración no encontrado")

        updated = self.repo.update(
            setting,
            value=payload.value,
            updated_by=current_user.id,
        )
        self.audit.log(
            action="SYSTEM_SETTING_UPDATED",
            entity="system_settings",
            user_id=current_user.id,
            entity_id=updated.id,
            details={"key": key},
        )
        return SystemSettingResponse.model_validate(updated)

    def _ensure_defaults(self) -> None:
        for key, meta in DEFAULT_SETTINGS.items():
            if self.repo.get_by_key(key) is None:
                self.repo.create(
                    key=key,
                    value=meta["value"],
                    description=meta["description"],
                )

    @staticmethod
    def _validate_value(key: str, value: str) -> None:
        if key == "app_display_name":
            if len(value) < 3 or len(value) > 100:
                raise ValidationException(
                    "El nombre de la aplicación debe tener entre 3 y 100 caracteres"
                )
        elif key == "ethical_disclaimer":
            if len(value) < 10:
                raise ValidationException(
                    "El mensaje ético debe tener al menos 10 caracteres"
                )
        elif key == "max_recommendations_per_session":
            if not value.isdigit():
                raise ValidationException(
                    "El máximo de recomendaciones debe ser un número entero"
                )
            amount = int(value)
            if amount < 1 or amount > 50:
                raise ValidationException(
                    "El máximo de recomendaciones debe estar entre 1 y 50"
                )
        elif key == "maintenance_mode":
            normalized = value.lower()
            if normalized not in {"true", "false"}:
                raise ValidationException(
                    "El modo mantenimiento solo puede ser true o false"
                )
