from __future__ import annotations

import logging
import smtplib
from email.message import EmailMessage

from app.core.config import Settings, get_settings

logger = logging.getLogger(__name__)


class EmailService:
    def __init__(self, settings: Settings | None = None) -> None:
        self.settings = settings or get_settings()

    @property
    def is_configured(self) -> bool:
        return bool(
            self.settings.smtp_host.strip()
            and self.settings.smtp_from.strip()
        )

    def send_password_reset_email(
        self,
        *,
        to_email: str,
        reset_token: str,
        user_name: str,
    ) -> None:
        subject = "Recuperación de contraseña — AVOV"
        body = (
            f"Hola {user_name},\n\n"
            "Recibimos una solicitud para restablecer tu contraseña en AVOV.\n"
            "Usa el siguiente token en la aplicación (caduca en "
            f"{self.settings.password_reset_token_expire_hours} horas):\n\n"
            f"{reset_token}\n\n"
            "Si no solicitaste este cambio, ignora este mensaje.\n"
        )

        if not self.is_configured:
            if self.settings.app_debug:
                logger.info(
                    "SMTP no configurado: correo de recuperación omitido para %s",
                    to_email,
                )
            else:
                logger.info(
                    "SMTP no configurado: no se envió correo de recuperación"
                )
            return

        message = EmailMessage()
        message["Subject"] = subject
        message["From"] = self.settings.smtp_from
        message["To"] = to_email
        message.set_content(body)

        try:
            if self.settings.smtp_use_tls:
                with smtplib.SMTP(
                    self.settings.smtp_host,
                    self.settings.smtp_port,
                    timeout=15,
                ) as smtp:
                    smtp.starttls()
                    if self.settings.smtp_user:
                        smtp.login(
                            self.settings.smtp_user,
                            self.settings.smtp_password,
                        )
                    smtp.send_message(message)
            else:
                with smtplib.SMTP(
                    self.settings.smtp_host,
                    self.settings.smtp_port,
                    timeout=15,
                ) as smtp:
                    if self.settings.smtp_user:
                        smtp.login(
                            self.settings.smtp_user,
                            self.settings.smtp_password,
                        )
                    smtp.send_message(message)
        except smtplib.SMTPException:
            logger.exception(
                "No se pudo enviar el correo de recuperación de contraseña"
            )
