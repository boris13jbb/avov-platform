# Manual de producción — AVOV

## Estado

La preparación para Google Cloud + Firebase Hosting está documentada en:

- [despliegue-gcp-firebase.md](despliegue-gcp-firebase.md) — arquitectura, costos, red privada, gate de aprobación, comandos.
- [variables-entorno.md](variables-entorno.md) — secretos, CORS, PDF local/GCS, Flutter `--dart-define`.
- `deploy/gcp/` — plantillas Cloud Build, Cloud Run y VM Redis/Qdrant (vía A).

**Preparación local ≠ despliegue público.** No afirmar acceso mundial hasta verificar login desde una red externa real.

## Elementos

| Elemento | Ubicación |
|----------|-----------|
| Imagen backend prod | `backend/Dockerfile` (`PORT`, sin `--reload`) |
| Compose Redis+Qdrant (VM) | `deploy/gcp/vm-redis-qdrant/` |
| Firebase Hosting | `firebase.json`, `.firebaserc.example` |
| Compose monolítico legacy (otro worktree) | No forma parte de este camino GCP |

## Checklist operativo (cuando exista infraestructura autorizada)

1. Secretos en Secret Manager (JWT, APP, DATABASE_URL, REDIS_URL, DeepSeek, Qdrant).
2. Cloud SQL + `alembic upgrade head` en entorno de prueba.
3. VM o Memorystore/Qdrant Cloud según vía A/B aprobada.
4. Bucket GCS y `AVOV_REPORTS_BACKEND=gcs`.
5. Cloud Run con VPC connector y probes en `/api/v1/health/live`.
6. CORS con origen de Hosting.
7. Build Flutter web/APK con `API_BASE_URL` HTTPS.
8. Backups: Cloud SQL automated backups + snapshots de discos de la VM / colección Qdrant.
9. Rollback: revisión anterior de Cloud Run + versión Hosting.

## Android y desbloqueo local

- Firma release, `applicationId` definitivo y cleartext HTTPS: ver sección 14 de [despliegue-gcp-firebase.md](despliegue-gcp-firebase.md).
- PIN/biometría: pendiente de integrar desde `feature/app-unlock-pin-biometric` (otro worktree); no forma parte de esta rama cloud.

## Autorización

Commit, push, PR, merge, facturación, creación de recursos y `firebase deploy` / `gcloud run deploy` exigen autorización explícita e independiente.
