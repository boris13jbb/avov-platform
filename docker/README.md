# Docker — AVOV

| Archivo | Uso |
|---------|-----|
| `docker-compose.yml` | Desarrollo local (phpMyAdmin, puertos expuestos, hot-reload) |
| `docker-compose.prod.yml` | Producción (Nginx, sin phpMyAdmin, volúmenes persistentes) |
| `docker-compose.prod.ssl.yml` | Override TLS para producción |

## Desarrollo

```powershell
.\scripts\dev-up.ps1
```

## Producción

```powershell
Copy-Item .env.production.example .env
# Editar claves y dominios en .env

.\scripts\prod-up.ps1
```

### Con TLS

1. Colocar `fullchain.pem` y `privkey.pem` en `nginx/certs/`.
2. Ejecutar:

```powershell
.\scripts\prod-up.ps1 -Ssl
# o: $env:AVOV_PROD_SSL = "1"; .\scripts\prod-up.ps1
```

## Backups

```powershell
.\scripts\backup-all.ps1 -Target prod
```

Variables opcionales: `COMPOSE_FILE`, `COMPOSE_PROJECT`, `BACKUP_DIR` (scripts `.sh`).
