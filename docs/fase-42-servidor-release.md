# Fase 42 — Servidor real, Flutter Web y release institucional

## Objetivo

Preparar el **despliegue en servidor Linux real** con:

1. Plantilla `.env` con dominios API + frontend y CORS coherentes.
2. **Preflight servidor** (HTTPS, dominios, allowed hosts).
3. **Build Flutter Web** embebido con `API_BASE_URL` de producción.
4. **Nginx** sirviendo SPA + API (`docker-compose.prod.web.yml`).
5. Script **Let's Encrypt** y despliegue unificado `deploy-prod-server.sh`.
6. Validación automatizada `validate-server-release.ps1`.

---

## Archivos creados

| Archivo | Descripción |
|---------|-------------|
| `.env.production.server.example` | Plantilla servidor real |
| `.env.server-release.example` | Env validacion local Fase 42 |
| `docker-compose.prod.web.yml` | Nginx sirve `frontend/build/web` |
| `docker-compose.prod.web.ssl.yml` | Web + TLS |
| `nginx/nginx.prod.web.conf` | SPA + API HTTP |
| `nginx/nginx.prod.ssl.web.conf` | SPA + API HTTPS |
| `scripts/preflight-server.ps1` | Preflight dominios/CORS |
| `scripts/build-flutter-web.ps1` / `.sh` | Build web release |
| `scripts/setup-letsencrypt.sh` | Certbot Let's Encrypt |
| `scripts/deploy-prod-server.sh` | Deploy API + Web + SSL |
| `scripts/validate-server-release.ps1` | Orquestador Fase 42 |
| `docs/fase-42-servidor-release.md` | Este documento |

---

## Comandos

### Validacion local Fase 42

```powershell
.\scripts\validate-server-release.ps1
```

### Build Flutter Web

```powershell
.\scripts\build-flutter-web.ps1 -EnvFile ".env.server-release.example"
```

```bash
ENV_FILE=.env ./scripts/build-flutter-web.sh
```

### Servidor Linux (flujo completo)

```bash
cp .env.production.server.example .env
# Editar dominios, claves, CORS, API_BASE_URL, FRONTEND_BASE_URL

./scripts/build-flutter-web.sh
LETSENCRYPT_EMAIL=admin@instituto.edu.co ./scripts/setup-letsencrypt.sh
AVOV_PROD_SSL=1 AVOV_PROD_WEB=1 ./scripts/deploy-prod-server.sh
./scripts/post-deploy-prod.sh https://api.tudominio.edu.co/api/v1
```

### Checklist UI manual

Ejecutar [fase-41-flutter-ui-manual.md](fase-41-flutter-ui-manual.md) contra la URL publica del frontend.

---

## Arquitectura release

```
Usuario -> https://app.dominio (Nginx SPA Flutter)
        -> https://api.dominio/api/v1 (Nginx -> backend)
Backend -> MySQL, Redis, Qdrant (red interna Docker)
```

---

## Criterios de exito Fase 42

1. `preflight-server.ps1` OK con `.env.server-release.example`.
2. `docker compose` prod+web(+ssl) sin errores de config.
3. `flutter analyze` + `flutter test` OK.
4. `flutter build web` genera `frontend/build/web/index.html`.
5. Documentacion y scripts de servidor Linux listos.

**Ultima ejecucion local:** 8 OK / 0 FALLO — ver [fase-42-server-release-validation.txt](fase-42-server-release-validation.txt).

---

## Proximo paso sugerido

Desplegar en VPS institucional, ejecutar checklist UI manual completo y configurar backups/cron en el servidor.
