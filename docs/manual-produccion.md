# Manual de producción — AVOV

**Estado:** operativo para preparación go-live (F8). Sustituye el stub anterior.

**Compose:** `docker-compose.prod.yml` · **Nginx TLS:** `nginx/nginx.prod.conf`

## 1. Requisitos previos

- Host con Docker y Docker Compose.
- Dominio y certificados TLS (`nginx/certs/fullchain.pem`, `privkey.pem`).
- Archivo `.env` de producción (nunca marcadores de ejemplo; `APP_ENV=production`, `APP_DEBUG=false`).
- Build Flutter Web (o artefacto) montado en el volumen `avov_frontend_dist`.
- Decisiones de producto: hosting, RPO/RTO, SMTP, presupuesto DeepSeek (`docs/decisiones-producto-pendientes.md`).

## 2. Despliegue

```bash
# 1. Configurar .env de producción (fuera del repo si aplica)
# 2. Colocar certificados en nginx/certs/
# 3. Publicar build Flutter Web en el volumen frontend
docker compose -f docker-compose.prod.yml up --build -d
docker compose -f docker-compose.prod.yml ps
curl -fsS https://<dominio>/api/v1/health
```

Aplicar migraciones **solo** con autorización y contra la base de producción prevista:

```bash
docker compose -f docker-compose.prod.yml exec backend alembic upgrade head
```

## 3. Backups

| Recurso | Script | Notas |
|---------|--------|-------|
| MySQL | `scripts/backup-mysql.sh` | Dump vía `docker exec avov-mysql` |
| Qdrant | `scripts/backup-qdrant.sh` | Tar del volumen |

Programar ejecución (cron/Task Scheduler) y retención según RPO.

## 4. Restore (drill obligatorio)

| Recurso | Script | Destino seguro por defecto |
|---------|--------|----------------------------|
| MySQL | `scripts/restore-mysql.sh backup.sql [schema]` | `avov_restore_check` |
| Qdrant | `scripts/restore-qdrant.sh backup.tar.gz [dir]` | `/tmp/avov-qdrant-restore-check` |

**Procedimiento de ensayo:**

1. Tomar backup reciente.
2. Restaurar MySQL a `avov_restore_check` (no a `avov_db`).
3. Comparar conteos de tablas críticas (`users`, `students`, `test_sessions`).
4. Expandir Qdrant en directorio temporal y verificar estructura.
5. Documentar fecha, operador, RTO observado y eliminar esquema/directorio de prueba.

Sin este drill documentado, **no** se declara F8-BK cerrado.

## 5. Rollback

1. Mantener imagen/tag anterior del backend.
2. `docker compose -f docker-compose.prod.yml up -d backend` con imagen previa.
3. Si hubo migración incompatible: restaurar MySQL desde backup previo (autorización explícita).
4. Verificar `/api/v1/health` y login.

## 6. Observabilidad mínima

- Health: `GET /api/v1/health` y `/health/live`.
- Logs del contenedor `avov-backend` (sin secretos).
- Alertas recomendadas: health fallido, disco, fallo SMTP, errores 5xx sostenidos.

## 7. Seguridad

- No publicar phpMyAdmin en producción.
- CORS restringido a orígenes reales.
- JWT y secretos rotables; `TRUST_PROXY_HEADERS=true` solo detrás de Nginx de confianza.
- SMTP y DeepSeek solo por variables de entorno.

## 8. Checklist go-live (F8-GATE)

- [ ] `.env` producción sin marcadores de ejemplo
- [ ] TLS válido
- [ ] Health verde
- [ ] Login roles smoke
- [ ] Backup + restore drill documentado
- [ ] Runbook de incidente asignado
- [ ] Aprobación humana de release
