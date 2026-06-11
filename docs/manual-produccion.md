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

### 3.2 Levantar stack (HTTP)

**Windows:**

```powershell
.\scripts\prod-up.ps1
```

**Linux:**

```bash
docker compose -f docker-compose.prod.yml -p avov-prod up --build -d
```

El backend aplica `alembic upgrade head` automáticamente al iniciar.

### 3.3 Verificar salud

```bash
curl http://localhost/api/v1/health/live
curl http://localhost/api/v1/health
```

Respuesta esperada: `success: true`.

### 3.4 Post-despliegue

1. Login super admin (`admin@avov.edu.co` o usuario creado en migración).
2. Rebuild índice Qdrant: panel `/admin/vector`.
3. Verificar `GET /api/v1/settings/public`.
4. Configurar Flutter con `API_BASE_URL` de producción.

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

```bash
git pull
docker compose -f docker-compose.prod.yml -p avov-prod up --build -d
```

Opcional: activar `maintenance_mode` desde `/admin/settings` antes de actualizar.

---

## 6. Backups

### Automático (recomendado: cron)

```bash
# Diario 02:00
0 2 * * * cd /opt/avov && COMPOSE_FILE=docker-compose.prod.yml COMPOSE_PROJECT=avov-prod ./scripts/backup-mysql.sh
15 2 * * * cd /opt/avov && COMPOSE_FILE=docker-compose.prod.yml COMPOSE_PROJECT=avov-prod ./scripts/backup-qdrant.sh
```

**Windows (Programador de tareas):**

```powershell
.\scripts\backup-all.ps1 -Target prod
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
- [docker/README.md](../docker/README.md)
