# Manual de producción — AVOV

Guía operativa para desplegar y mantener AVOV en producción.

---

## 1. Arquitectura

```
Internet → Nginx (:80 / :443) → backend:8000 → MySQL
                                    ↓
                               Redis, Qdrant
Flutter (web/APK) ──────────────→ https://api.dominio/api/v1
```

| Servicio | Acceso externo | Notas |
|----------|----------------|-------|
| Nginx | Sí (80/443) | Único punto de entrada HTTP |
| Backend | No (red interna) | Uvicorn con workers |
| MySQL | No | Solo red Docker |
| Redis | No | Rate limit login |
| Qdrant | No | Embeddings carreras |
| phpMyAdmin | **No en producción** | Solo desarrollo |

---

## 2. Requisitos del servidor

- Linux (recomendado) o Windows Server con Docker Engine 24+
- 4 GB RAM mínimo (8 GB recomendado)
- 40 GB disco (MySQL + Qdrant + PDFs/logos)
- Dominio y certificados TLS (Let's Encrypt o institucional)
- Firewall: abrir solo 80/443

---

## 3. Despliegue inicial

### 3.1 Preparar entorno

```bash
git clone <repositorio> avov-platform
cd avov-platform
cp .env.production.example .env
```

Editar `.env`:

- `APP_SECRET_KEY`, `JWT_SECRET_KEY` — claves aleatorias ≥32 caracteres
- `MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD` — fuertes y únicas
- `DATABASE_URL` — debe coincidir con usuario/contraseña MySQL
- `DEEPSEEK_API_KEY` — clave válida
- `BACKEND_CORS_ORIGINS` — dominio(s) del frontend Flutter
- `API_BASE_URL` — URL pública `https://api.tudominio.edu.co/api/v1`

### 3.2 Preflight (obligatorio)

Valida secretos, CORS y coherencia de variables **antes** de levantar Docker:

**Windows:**

```powershell
.\scripts\preflight-prod.ps1 -EnvFile ".env"
```

**Linux:**

```bash
chmod +x scripts/deploy-prod.sh
# El script ejecuta preflight integrado antes de docker compose up
```

Si el preflight falla, corrige `.env` y vuelve a ejecutarlo. No despliegues con placeholders en claves JWT/APP.

### 3.3 Levantar stack (HTTP)

**Windows:**

```powershell
.\scripts\prod-up.ps1
```

**Linux:**

```bash
./scripts/deploy-prod.sh
# SSL opcional:
AVOV_PROD_SSL=1 ./scripts/deploy-prod.sh
```

### 3.4 Simulación prod-local (desarrollo, puerto 8090)

Stack aislado que no modifica `.env` de desarrollo:

```powershell
Copy-Item .env.prod-local.example .env.prod-local
.\scripts\prod-local-up.ps1
.\scripts\validate-prod-deploy.ps1
```

### 3.5 Verificar salud

```bash
curl http://localhost/api/v1/health/live
curl http://localhost/api/v1/health
```

Respuesta esperada: `success: true`.

El backend aplica `alembic upgrade head` automáticamente al iniciar.

### 3.6 Post-despliegue

1. Login super admin (`admin@avov.edu.co` o usuario creado en migración).
2. Ejecutar checklist automatizado:

**Windows:**

```powershell
.\scripts\post-deploy-prod.ps1 -BaseUrl "https://api.tudominio.edu.co/api/v1"
```

**Linux:**

```bash
chmod +x scripts/post-deploy-prod.sh
./scripts/post-deploy-prod.sh https://api.tudominio.edu.co/api/v1
```

3. Rebuild índice Qdrant (también incluido en post-deploy): panel `/admin/vector` o `POST /vector/rebuild-careers`.
4. Verificar `GET /api/v1/settings/public`.
5. Configurar Flutter con `API_BASE_URL` de producción.
6. Ejecutar checklist UI manual: [fase-41-flutter-ui-manual.md](fase-41-flutter-ui-manual.md).

### 3.7 Simulación SSL local (desarrollo)

```powershell
Copy-Item .env.prod-ssl-local.example .env.prod-ssl-local
.\scripts\validate-prod-ssl-deploy.ps1
```

### 3.8 Despliegue servidor real con Flutter Web (Fase 42)

```bash
cp .env.production.server.example .env
# Editar API_DOMAIN, FRONTEND_DOMAIN, claves, CORS

./scripts/build-flutter-web.sh
LETSENCRYPT_EMAIL=admin@instituto.edu.co ./scripts/setup-letsencrypt.sh
AVOV_PROD_SSL=1 AVOV_PROD_WEB=1 ./scripts/deploy-prod-server.sh
./scripts/post-deploy-prod.sh https://api.tudominio.edu.co/api/v1
```

Validación local antes del servidor:

```powershell
.\scripts\validate-server-release.ps1
```

Ver [fase-42-servidor-release.md](fase-42-servidor-release.md).

### 3.9 Despliegue institucional completo (Fase 44)

Simulacion local (Web + API + SSL):

```powershell
.\scripts\prod-institutional-local-up.ps1
.\scripts\validate-institutional-deploy.ps1 -SkipTlsVerify
```

VPS Linux (flujo unificado):

```bash
cp .env.production.server.example .env
# Editar dominios reales y claves

LETSENCRYPT_EMAIL=admin@instituto.edu.co RUN_LETSENCRYPT=1 ./scripts/deploy-institutional.sh
```

Checklist UI obligatorio tras despliegue:

- [fase-41-flutter-ui-manual.md](fase-41-flutter-ui-manual.md)
- Plantilla reporte: [fase-44-ui-checklist-report.template.md](fase-44-ui-checklist-report.template.md)

Ver [fase-44-despliegue-institucional.md](fase-44-despliegue-institucional.md).

---

## 4. HTTPS / TLS

1. Obtener certificados (ej. Certbot):

```bash
certbot certonly --standalone -d api.tudominio.edu.co
```

2. Copiar a `nginx/certs/`:

- `fullchain.pem`
- `privkey.pem`

3. Levantar con SSL:

```powershell
.\scripts\prod-up.ps1 -Ssl
```

O:

```bash
AVOV_PROD_SSL=1 docker compose -f docker-compose.prod.yml -f docker-compose.prod.ssl.yml -p avov-prod up -d
```

---

## 5. Actualizaciones

Actualización segura (Fase 45 — recomendado):

```bash
# Activar maintenance_mode en admin antes
./scripts/update-prod-safe.sh
```

Rollback si falla post-deploy:

```bash
./scripts/rollback-prod.sh
ROLLBACK_RESTORE_DB=1 ./scripts/rollback-prod.sh   # incluye restore BD
```

Manual:

```bash
git pull
docker compose -f docker-compose.prod.yml -p avov-prod up --build -d
```

Opcional: activar `maintenance_mode` desde `/admin/settings` antes de actualizar.

---

## 6. Backups

### Automático (recomendado: cron)

```bash
# Instalacion guiada (Fase 43)
INSTALL=1 AVOV_ROOT=/opt/avov ./scripts/install-vps-cron.sh

# O manualmente (ver docs/cron/avov-backup.cron.example)
0 2 * * * cd /opt/avov && AVOV_PROD_WEB=1 AVOV_PROD_SSL=1 ./scripts/backup-all.sh prod >> ./logs/backup-cron.log 2>&1
30 2 * * * cd /opt/avov && RETENTION_DAYS=14 ./scripts/prune-backups.sh >> ./logs/backup-cron.log 2>&1
```

**Windows (Programador de tareas):**

```powershell
.\scripts\backup-all.ps1 -Target prod
.\scripts\prune-backups.ps1 -RetentionDays 14
```

### Restaurar MySQL

```bash
docker compose -f docker-compose.prod.yml -p avov-prod exec -T mysql \
  mysql -uroot -p"$MYSQL_ROOT_PASSWORD" avov_db < backups/mysql/archivo.sql
```

### Restaurar Qdrant

Detener stack, restaurar volumen o extraer tarball al volumen `qdrant_data`, reiniciar y validar con rebuild si es necesario.

---

## 7. Logs y monitoreo

```bash
docker compose -f docker-compose.prod.yml -p avov-prod logs -f backend
docker compose -f docker-compose.prod.yml -p avov-prod logs -f nginx
```

Monitoreo automatizado (Fase 43):

```bash
./scripts/monitor-health.sh "https://api.tudominio.edu.co/api/v1"
```

```powershell
.\scripts\monitor-health.ps1 -BaseUrl "https://api.tudominio.edu.co/api/v1"
```

Cron sugerido cada 5 minutos: ver `docs/cron/avov-backup.cron.example` o `scripts/install-vps-cron.sh`.

Rotación configurada: máx. 10–20 MB × 3–5 archivos por servicio.

Alertas sugeridas:

- `GET /api/v1/health` con MySQL/Redis/Qdrant `down`
- Disco > 85 %
- 5xx sostenidos en Nginx

---

## 8. Seguridad

| Control | Estado |
|---------|--------|
| `APP_DEBUG=false` | Forzado en compose prod |
| OpenAPI `/docs` | Deshabilitado (backend + Nginx) |
| Rate limit login | Redis (`LOGIN_RATE_LIMIT_*`) |
| CORS restrictivo | `BACKEND_CORS_ORIGINS` |
| Headers seguridad | Nginx snippets |
| phpMyAdmin | No incluido en prod |
| Secrets en `.env` | Nunca en git |

---

## 9. Modo mantenimiento

1. Super admin → Configuración → `maintenance_mode` = `true`
2. Solo super admin accede
3. Tras mantenimiento → `false`

---

## 10. Escalado

- Aumentar `UVICORN_WORKERS` según CPUs (2–4 típico).
- MySQL/Qdrant en servidor dedicado: actualizar `DATABASE_URL`, `QDRANT_HOST` en `.env` y quitar servicios del compose si usas managed DB.

---

## 11. Referencias

- [variables-entorno.md](variables-entorno.md)
- [checklist-qa.md](checklist-qa.md)
- [fase-31-produccion.md](fase-31-produccion.md)
- [plan-rollback-produccion.md](plan-rollback-produccion.md)
- [runbook-soporte-produccion.md](runbook-soporte-produccion.md)
- [capacitacion-ti-institucional.md](capacitacion-ti-institucional.md)
- [docker/README.md](../docker/README.md)
