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

## Seguridad

- Nunca commitear `.env`.
- Nunca exponer `DEEPSEEK_API_KEY` en el frontend.
- Usar claves fuertes y únicas en producción.
