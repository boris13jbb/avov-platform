# Plantillas GCP para AVOV

Estas plantillas son **preparación local**. No crean recursos ni generan coste por sí solas.

| Archivo | Uso |
|---------|-----|
| `cloudbuild.yaml` | Build y push de la imagen del backend |
| `cloud-run-service.yaml` | Referencia del servicio Cloud Run |
| `vm-redis-qdrant/` | Compose Redis+Qdrant para la VM GCE (vía A) |
| `scripts/validate-cloud-config.ps1` | Comprueba que existan plantillas y vars de ejemplo |

Documentación completa: [`docs/despliegue-gcp-firebase.md`](../../docs/despliegue-gcp-firebase.md).

**No ejecutar** `gcloud builds submit`, `gcloud run deploy`, creación de SQL/VM/VPC ni `firebase deploy` sin autorización explícita del responsable del proyecto.
