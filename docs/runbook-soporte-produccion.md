# Runbook de soporte en producción — AVOV (Fase 45)

Guía operativa para el personal de TI ante incidentes en producción.

---

## Contactos y roles

| Rol | Responsabilidad |
|-----|-----------------|
| Super admin AVOV | Configuración global, modo mantenimiento |
| Admin institución | Usuarios y estudiantes de su institución |
| TI servidor | Docker, backups, SSL, rollback |
| Orientador | Soporte funcional a estudiantes |

---

## Diagnóstico inicial (5 minutos)

```bash
# Salud API
curl -fsS https://api.tudominio.edu.co/api/v1/health | jq .

# Logs backend (ultimas 100 lineas)
docker compose -f docker-compose.prod.yml -p avov-prod logs --tail=100 backend

# Logs nginx
docker compose -f docker-compose.prod.yml -p avov-prod logs --tail=50 nginx

# Disco
df -h /

# Contenedores
docker compose -f docker-compose.prod.yml -p avov-prod ps
```

Windows:

```powershell
.\scripts\monitor-health.ps1 -BaseUrl "https://api.tudominio.edu.co/api/v1"
```

---

## Incidentes frecuentes

### API no responde (502/503)

1. Verificar contenedores: `docker compose ps`
2. Reiniciar backend: `docker compose restart backend`
3. Si persiste: revisar MySQL/Redis/Qdrant en `/health`
4. Rollback si coincide con deploy reciente

### MySQL down

```bash
docker compose -f docker-compose.prod.yml -p avov-prod restart mysql
docker compose -f docker-compose.prod.yml -p avov-prod logs mysql --tail=50
```

Si corrupción: restore backup MySQL (ver [plan-rollback-produccion.md](plan-rollback-produccion.md)).

### Qdrant down / recomendaciones vacías

1. Reiniciar: `docker compose restart qdrant`
2. Rebuild índice (super admin): POST `/api/v1/vector/rebuild-careers`
3. Fallback MySQL activo si Qdrant falla (recomendaciones básicas)

### Certificado SSL expirado

```bash
LETSENCRYPT_EMAIL=admin@instituto.edu.co ./scripts/setup-letsencrypt.sh
AVOV_PROD_SSL=1 AVOV_PROD_WEB=1 ./scripts/deploy-prod-server.sh
```

### Login masivo fallido

- Verificar Redis (rate limit)
- Revisar `LOGIN_RATE_LIMIT_*` en `.env`
- Consultar audit logs en panel admin

### Frontend en blanco / 404 en rutas

1. Verificar `frontend/build/web/index.html` existe en servidor
2. Rebuild: `./scripts/build-flutter-web.sh`
3. Redeploy nginx con compose web
4. Probar SPA: `curl -I https://app.dominio/login`

### DeepSeek / asistente IA no responde

- Verificar `DEEPSEEK_API_KEY` en `.env`
- El sistema usa fallback sin IA; no bloquea test vocacional
- Revisar logs backend (timeout, 429)

---

## Actualización planificada

```bash
# 1. Modo mantenimiento (UI admin)
# 2. Update seguro
./scripts/update-prod-safe.sh
# 3. Checklist UI si hay cambios frontend
# 4. Desactivar mantenimiento
```

---

## Monitoreo continuo

Cron cada 5 min (Fase 43):

```bash
./scripts/monitor-health.sh "https://api.tudominio.edu.co/api/v1"
```

Alertas recomendadas:

- Health `mysql/redis/qdrant = false`
- Disco > 85 %
- HTTP 5xx > 1 % en 5 min

---

## Registro de incidentes

Documentar en ticket interno:

1. Fecha/hora inicio y fin
2. Síntoma reportado
3. Comandos ejecutados
4. Backup usado (si restore)
5. Commit antes/después (si rollback)

Plantilla checklist UI post-incidente: [fase-44-ui-checklist-report.template.md](fase-44-ui-checklist-report.template.md)

---

## Referencias

- [plan-rollback-produccion.md](plan-rollback-produccion.md)
- [manual-produccion.md](manual-produccion.md)
- [capacitacion-ti-institucional.md](capacitacion-ti-institucional.md)
