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

## URL de la API en Flutter

Flutter no lee el `.env` del backend. La única fuente es `AppConfig.apiBaseUrl`.

| Cómo se ejecuta | URL que usa |
|-----------------|-------------|
| Windows, web, iOS o escritorio, sin definir nada | `http://127.0.0.1:8000/api/v1` |
| Emulador Android, sin definir nada | `http://10.0.2.2:8000/api/v1` |
| Cualquier plataforma con valor explícito | El valor de `--dart-define=API_BASE_URL=...` |

`localhost` dentro del emulador Android es el propio emulador, no el equipo Windows. `10.0.2.2` es el alias del anfitrión y el puerto sigue siendo `8000`. Para otro entorno, por ejemplo producción, se pasa la URL pública al compilar:

```powershell
flutter run --dart-define=API_BASE_URL=https://api.ejemplo.edu/api/v1
```

Esa URL no debe incluir contraseñas, tokens ni claves. Si no se pasa `API_BASE_URL`, la aplicación no sustituye una URL de producción por una dirección local: el valor explícito siempre gana.

## MySQL según desde dónde se conecta

| Origen | Destino |
|--------|---------|
| Proceso en Windows (Uvicorn o pytest sin `DATABASE_URL`) | `127.0.0.1:3307`, puerto publicado del contenedor AVOV |
| Backend dentro de Docker | `mysql:3306`, red interna. Compose fija esta URL |
| phpMyAdmin | Sigue en `http://localhost:8081`. Dentro de Docker habla con `mysql:3306` |
| Proceso en Windows sin `REDIS_URL` | `127.0.0.1:6380`. El 6379 del host pertenece a otro Redis |
| Backend dentro de Docker, Redis | `redis://redis:6379/0`. Compose fija esta URL |

El archivo `.env` de los contenedores conserva el host `mysql` y el puerto `3306`. Ese nombre no es el MySQL de XAMPP. Si desde Windows se reescribe el host a `localhost` o `127.0.0.1` y se deja el puerto `3306`, las pruebas escribirían en XAMPP. En ese caso el puerto debe ser `3307`. Una variable `DATABASE_URL` definida en el entorno o en el `.env` del directorio de trabajo tiene prioridad sobre el valor predeterminado del código.

## Seguridad

- Nunca commitear `.env`.
- Nunca exponer `DEEPSEEK_API_KEY` en el frontend.
- Usar claves fuertes y únicas en producción.

## Producción

`APP_ENV=production` o `APP_ENV=prod` es el modo de producción. Con ese valor el proceso no arranca si `JWT_SECRET_KEY`, `APP_SECRET_KEY` o la contraseña de `DATABASE_URL` coinciden exactamente con los marcadores conocidos, si la contraseña de la base está vacía, o si `APP_DEBUG` queda activo. La comprobación ocurre al cargar la configuración, antes de atender tráfico. El error nombra la variable y no imprime el secreto. Un secreto real que solo contenga el texto `change-me` en medio no se rechaza. En producción la respuesta de un error no controlado tampoco incluye el detalle de la excepción.

Esas tres variables, junto con `MYSQL_PASSWORD` y `MYSQL_ROOT_PASSWORD`, deben inyectarse desde el entorno del servidor o desde un gestor de secretos. No se escriben en la imagen ni en archivos versionados. El desarrollo local puede seguir con `APP_ENV=development` y los valores actuales.

`DEEPSEEK_API_KEY` vacía o igual al marcador `your-deepseek-api-key-here` se trata como no configurada. El asistente usa el fallback local y no llama a DeepSeek. Una clave distinta solo indica que hay un valor; no demuestra que el proveedor la acepte.

`TRUST_PROXY_HEADERS` queda en `false`. Sin eso, el límite usa la IP de la conexión directa e ignora `X-Forwarded-For`. Actívalo solo detrás de un proxy que añada la IP real al final de esa cabecera. El primer valor lo puede falsificar el cliente.

`LOGIN_MAX_ATTEMPTS` (5) y `LOGIN_WINDOW_SECONDS` (900) reservan cada intento en Redis de AVOV antes de comprobar la contraseña. La reserva y la caducidad se escriben en un solo script. El intento que alcanza el cupo responde HTTP 429 con `Retry-After`, igual para una cuenta existente o inexistente. Una credencial incorrecta conserva la reserva. Un login correcto o una cuenta inactiva la borran, porque la contraseña era válida. Un fallo inesperado devuelve solo ese intento. La ventana vuelve a abrir sola. Redis no disponible responde HTTP 503.

La migración `e1f2a3b4c5d6` ya está aplicada y conserva la semilla histórica. No se reescribe. Las instalaciones nuevas no deben depender de esa contraseña: el alta explícita está en `app/security/admin_bootstrap.py`, rechaza esa contraseña pública y no se ejecuta al arrancar. Cambiar la cuenta ya creada en `avov_db` requiere una decisión aparte; no forma parte de este arranque.
