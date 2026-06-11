# Variables de entorno — AVOV

Copiar `.env.example` a `.env` y configurar los valores.

## Variables críticas (cambiar en producción)

| Variable | Descripción |
|----------|-------------|
| `APP_SECRET_KEY` | Clave secreta de la aplicación (mín. 32 caracteres) |
| `JWT_SECRET_KEY` | Clave para firmar tokens JWT |
| `MYSQL_ROOT_PASSWORD` | Contraseña root de MySQL |
| `MYSQL_PASSWORD` | Contraseña del usuario de aplicación |
| `DEEPSEEK_API_KEY` | API Key de DeepSeek (solo backend) |

## Variables de conexión

| Variable | Valor por defecto (Docker) |
|----------|---------------------------|
| `DATABASE_URL` | `mysql+pymysql://avov_user:...@mysql:3306/avov_db` |
| `REDIS_URL` | `redis://redis:6379/0` |
| `QDRANT_HOST` | `qdrant` |
| `API_BASE_URL` | `http://localhost:8000/api/v1` |

## Producción (Docker Compose prod)

| Variable | Descripción | Default |
|----------|-------------|---------|
| `NGINX_HTTP_PORT` | Puerto HTTP público de Nginx | `80` |
| `NGINX_HTTPS_PORT` | Puerto HTTPS (con override SSL) | `443` |
| `UVICORN_WORKERS` | Workers Uvicorn en producción | `2` |

Plantilla completa: `.env.production.example`

## Rate limiting (login)

| Variable | Descripción | Default |
|----------|-------------|---------|
| `LOGIN_RATE_LIMIT_MAX` | Intentos fallidos máximos por IP+correo | `5` |
| `LOGIN_RATE_LIMIT_WINDOW_SECONDS` | Ventana de bloqueo en segundos | `900` (15 min) |

Requiere Redis operativo. Si Redis no está disponible, el login sigue funcionando (degradación controlada con log de advertencia).

## Recuperación de contraseña y correo

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `PASSWORD_RESET_EXPIRE_HOURS` | Validez del enlace de recuperación | `1` |
| `FRONTEND_BASE_URL` | URL base de la app para enlaces en correo | `http://localhost:8080` |
| `SMTP_ENABLED` | Habilitar envío SMTP | `false` |
| `SMTP_HOST` | Servidor SMTP | `smtp.gmail.com` |
| `SMTP_PORT` | Puerto SMTP | `587` |
| `SMTP_USE_TLS` | Usar STARTTLS | `true` |
| `SMTP_USERNAME` | Usuario SMTP | — |
| `SMTP_PASSWORD` | Contraseña SMTP | — |
| `SMTP_FROM_EMAIL` | Remitente | `noreply@tu-dominio.edu.co` |

Con `SMTP_ENABLED=false`, el enlace de recuperación se escribe en los logs del backend (útil en desarrollo).

## Seguridad

- Nunca commitear `.env`.
- Nunca exponer `DEEPSEEK_API_KEY` en el frontend.
- Usar claves fuertes y únicas en producción.
