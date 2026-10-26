# Despliegue AVOV en Google Cloud + Firebase

Estado de este documento: **preparación local**. No implica que el sistema esté publicado ni accesible desde Internet.

Región propuesta: `southamerica-east1` (São Paulo).

Autenticación: JWT + refresh del backend actual. **No** se usa Firebase Authentication ni FCM.

---

## 1. Arquitectura actual (desarrollo local)

Flutter → FastAPI (`:8000`) → MySQL Docker (`:3307`), Redis (`:6380`), Qdrant (`:6333`). PDFs en disco (`AVOV_REPORTS_DIR` / `storage/reports`).

## 2. Causa del bloqueo desde otras redes

Los clientes usan `127.0.0.1`, `10.0.2.2` o una IP LAN. Sin URL HTTPS pública de la API, un dispositivo fuera del Wi‑Fi local no alcanza el backend.

## 3. Arquitectura cloud propuesta

```
Clientes (APK / Flutter Web)
    │ HTTPS
    ├─► Firebase Hosting (Flutter Web estático)
    └─► Cloud Run (FastAPI) ──► Cloud Storage (PDFs)
              │ VPC connector (solo rangos privados)
              ├─► Cloud SQL MySQL (IP privada)
              └─► GCE e2-small: Redis + Qdrant (vía A; sin puertos DB públicos)
              └─► DeepSeek API (egress HTTPS)
```

### Vía A — Redis + Qdrant en GCE (preparada primero)

- Una VM pequeña con Docker Compose (`deploy/gcp/vm-redis-qdrant/`).
- Firewall: TCP 6379 y 6333 solo desde el rango del Serverless VPC Access connector.
- Sin IP pública en esos puertos (preferible VM sin IP pública o con IP solo para SSH vía IAP).
- Ventajas: menor coste fijo, mismos clientes Redis/Qdrant del código.
- Riesgos: SPOF operativo; hay que parchear la VM y hacer snapshots de discos/volúmenes.

### Vía B — Memorystore + Qdrant Cloud (documentada)

- Memorystore Redis (Basic) en la misma VPC.
- Qdrant Cloud con acceso restringido (allowlist / private si el plan lo permite).
- Ventajas: menos operación de SO.
- Coste recurrente más alto (sobre todo Memorystore).

---

## 4. Costos orientativos (USD/mes)

Supuestos: tráfico educativo bajo, Cloud Run `minScale=0`, Cloud SQL pequeño, GCS &lt; 10 GB, región `southamerica-east1`. **Verificar en la calculadora oficial de Google Cloud antes de aprobar gasto.** Precios cambian.

| Concepto | Vía A | Vía B |
|----------|-------|-------|
| GCE e2-small + disco | ~15–25 | — |
| Memorystore Basic ~1 GB | — | ~30–50+ |
| Qdrant Cloud (mínimo) | — | ~0–25+ |
| Cloud Run | ~0–15 | ~0–15 |
| Cloud SQL MySQL | ~10–30 | ~10–30 |
| VPC connector | ~7–15 | ~7–15 |
| GCS + Hosting bajo | ~1–10 | ~1–10 |
| **Total orientativo** | **~35–90** | **~70–150+** |

Cargos adicionales posibles: IP estática, snapshots, egress, builds de Cloud Build, dominio custom, DeepSeek (fuera de GCP), plan Blaze de Firebase.

**Facturación:** crear estos recursos exige proyecto GCP con facturación activa. Esta fase **no** la habilita.

---

## 5. Persistencia de PDF

| Entorno | `AVOV_REPORTS_BACKEND` | Notas |
|---------|------------------------|-------|
| Local / Docker Compose | `local` | Disco bajo `AVOV_REPORTS_DIR` |
| Cloud Run | `gcs` | Bucket privado; SA de Cloud Run con roles de objeto |

Variables: `AVOV_GCS_BUCKET`, `AVOV_GCS_PREFIX` (por defecto `reports`). En BD solo se guarda el nombre de archivo (basename), igual que antes.

---

## 6. Red y seguridad

- MySQL, Redis y Qdrant **no** se exponen a Internet.
- Cloud Run usa VPC connector con egress `private-ranges-only` hacia SQL y la VM.
- `TRUST_PROXY_HEADERS=true` en producción detrás del balanceador de Cloud Run.
- `BACKEND_CORS_ORIGINS` debe incluir el origen de Firebase Hosting (`https://<proyecto>.web.app`, `https://<proyecto>.firebaseapp.com` y dominio custom si aplica).
- Secretos en Secret Manager; nunca en la imagen ni en Git.
- phpMyAdmin no forma parte del despliegue cloud.

Health:

- Liveness Cloud Run: `GET /api/v1/health/live`
- Diagnóstico dependencias: `GET /api/v1/health` (puede reportar `degraded` con HTTP 200)

---

## 7. Flutter Web y APK

Flutter no lee `.env`. Compilar siempre con URL pública:

```powershell
cd frontend

# Sustituir la URL por la del servicio Cloud Run real (tras el despliegue autorizado).
$api = "https://avov-api-XXXX-sa.a.run.app/api/v1"

flutter build web --release --dart-define=API_BASE_URL=$api
firebase deploy --only hosting   # solo con autorización

flutter build apk --release --dart-define=API_BASE_URL=$api
```

Sin `--dart-define`, el binario empaqueta `127.0.0.1` o `10.0.2.2` y **no** funcionará fuera de la red local.

Roles y auth (SUPER_ADMIN, INSTITUTION_ADMIN, COUNSELOR, STUDENT), refresh JWT y almacenamiento seguro se mantienen. PIN/biometría, si se integra desde otra rama, sigue siendo local y no depende de Firebase Auth.

Configuración Hosting: `firebase.json` (publica `frontend/build/web`). Copiar `.firebaserc.example` → `.firebaserc` con el ID de proyecto (no versionar secretos).

---

## 8. Gate de aprobación (obligatorio antes de gastar)

Antes de cualquier operación que cree recursos o active facturación, el responsable debe aprobar explícitamente:

1. Proyecto GCP / Firebase y región.
2. Lista de recursos de la sección 9.
3. Estimación de coste y método de pago.
4. Que se ejecutará la vía A (o B) concreta.

Hasta esa aprobación: solo preparación local, pruebas en máquina del desarrollador y builds de imagen **sin push** a Artifact Registry.

---

## 9. Recursos exactos propuestos (vía A) — pendientes de crear

| Recurso | Nombre sugerido | Notas |
|---------|-----------------|-------|
| Proyecto GCP | (definir) | Facturación requerida |
| Artifact Registry | `avov` en `southamerica-east1` | Imagen `avov-api` |
| Cloud Run | `avov-api` | Puerto 8080, SA dedicada |
| Cloud SQL MySQL 8 | `avov-mysql` | IP privada, tier pequeño |
| VPC + subnet | `avov-vpc` | |
| Serverless VPC Access | `avov-connector` | |
| GCE | `avov-data-vm` e2-small | Redis+Qdrant; preferible sin IP pública |
| Firewall | `avov-allow-data-from-connector` | 6379, 6333 solo desde connector |
| GCS | `<project>-avov-reports` | Uniform bucket-level access |
| Secret Manager | JWT, DB URL, Redis URL, DeepSeek, etc. | |
| Firebase Hosting | mismo proyecto o vinculado | Sitio web |

APIs a habilitar (cuando se autorice): Run, SQL Admin, Compute, VPC Access, Secret Manager, Artifact Registry, Cloud Build, Storage, IAM.

Roles IAM mínimos (orientativos): Cloud Run invoker (si privado) o allUsers si API pública con auth JWT; SA de Run: Cloud SQL Client, Storage Object Admin del bucket, Secret Accessor, acceso de red a la VPC.

---

## 10. Comandos futuros (no ejecutar sin autorización)

```powershell
# 1) APIs (ejemplo)
gcloud services enable run.googleapis.com sqladmin.googleapis.com `
  compute.googleapis.com vpcaccess.googleapis.com secretmanager.googleapis.com `
  artifactregistry.googleapis.com cloudbuild.googleapis.com storage.googleapis.com `
  --project=PROJECT_ID

# 2) Build local de comprobación (sin push; permitido en preparación)
cd backend
docker build -t avov-api:local .

# 3) Push / deploy (REQUIERE AUTORIZACIÓN)
# gcloud builds submit --config=deploy/gcp/cloudbuild.yaml --project=PROJECT_ID
# gcloud run deploy avov-api --image=... --region=southamerica-east1 ...
# firebase deploy --only hosting
```

Migración de esquema: job one-shot o Cloud Run job con `alembic upgrade head` contra Cloud SQL. **No** migrar datos de producción sin plan de integridad y backup.

---

## 11. Rollback

- Cloud Run: traficar a revisión anterior (`gcloud run services update-traffic`).
- Hosting: rollback de versión en Firebase Console.
- No borrar Cloud SQL ni discos de la VM sin backup verificado.
- Volver APK/web a un build con URL anterior solo si esa API sigue viva.

---

## 12. Procedimiento de reversión de esta preparación local

Los cambios viven en el worktree `AVOV-cloud-gcp` / rama `feature/cloud-gcp-firebase`. No afectan al WIP de `AVOV`. Para descartar el worktree (solo con autorización):

```powershell
git -C C:\Users\BRS\Documents\AVOV worktree remove C:\Users\BRS\Documents\AVOV-cloud-gcp
git -C C:\Users\BRS\Documents\AVOV branch -D feature/cloud-gcp-firebase
```

---

## 13. Checklist pre-despliegue

- [ ] Facturación y presupuesto aprobados
- [ ] Secretos reales generados (no marcadores de `.env.example`)
- [ ] Cloud SQL + migraciones en entorno vacío de prueba
- [ ] VM Redis/Qdrant alcanzable solo por VPC
- [ ] Bucket GCS y SA de Run
- [ ] CORS con origen Hosting
- [ ] `flutter build` con `API_BASE_URL` HTTPS real
- [ ] Prueba de login desde red distinta al Wi‑Fi de desarrollo
- [ ] Backup/snapshot documentado
- [ ] Firma Android de release (keystore propio; no debug)
- [ ] Decidir integración de PIN/biometría desde la rama dedicada

---

## 14. Flutter / Android: firma de lanzamiento y desbloqueo local

### API por entorno

- Única fuente: `--dart-define=API_BASE_URL=https://…/api/v1` al compilar (`AppConfig`).
- Sin ese valor, el binario lleva `127.0.0.1` o `10.0.2.2` y no sirve fuera de la red local.
- Script: `scripts/build-flutter-release.ps1` (rechaza URLs locales).

### Firma y empaquetado Android (pendiente antes de Play Store)

Estado actual en esta rama (plantilla Flutter):

| Elemento | Valor actual | Acción antes de tienda |
|----------|--------------|------------------------|
| `applicationId` | `com.example.avov_frontend` | Cambiar a ID definitivo (p. ej. dominio inverso real) |
| `signingConfig` release | **debug** | Crear keystore de release; configurar `signingConfigs.release` y no versionar el keystore ni las contraseñas |
| `usesCleartextTraffic` | `true` | Poner `false` (o `networkSecurityConfig` estricto) cuando la API sea solo HTTPS |
| Etiqueta de app | `avov_frontend` | Alinear con marca AVOV |

El keystore, las contraseñas y el `key.properties` **no** deben entrar en Git. Guardarlos fuera del repo (gestor de secretos / archivo local ignorado).

### PIN / biometría (fuera de este worktree)

El desbloqueo local con PIN/huella vive en el worktree/rama `AVOV-app-unlock` / `feature/app-unlock-pin-biometric`. **No está integrado** en `feature/cloud-gcp-firebase`.

- Es desbloqueo de sesión JWT ya válida en el dispositivo; no sustituye login ni viaja al backend.
- Para producción móvil completa: fusionar o cherry-pick esa feature en una rama de release **después** de revisar conflictos con Hosting/API URL, y volver a probar login + refresh + desbloqueo.
- Esta preparación cloud no añade Firebase Auth ni FCM.

---

## 15. Exposición de MySQL, Redis y Qdrant

| Superficie | ¿Puertos a Internet? | Control |
|------------|----------------------|---------|
| Cloud SQL (plan) | No (IP privada) | Sin IP pública; solo VPC / Cloud SQL Auth Proxy si se usa admin |
| VM Redis/Qdrant (`deploy/gcp/vm-redis-qdrant`) | Compose publica 6379/6333 en la VM para que Cloud Run llegue por IP privada | **Obligatorio:** VM sin IP pública (o IAP solo para SSH) + firewall GCP que niegue `0.0.0.0/0` y permita solo el rango del VPC connector |
| `docker-compose.yml` raíz | Publica 3307/6380/6333/8000 en el host | Solo desarrollo local; no usar en GCP |
| Cloud Run / Firebase Hosting | HTTPS público de API y web | Auth JWT en backend; CORS acotado |

Las plantillas cloud **no** abren MySQL/Redis/Qdrant en Internet por sí solas; el aislamiento real lo dan VPC, firewall y la ausencia de IP pública en la VM de datos.
