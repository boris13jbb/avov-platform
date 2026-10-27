# Publicación móvil — Android / iOS (F9)

**Estado:** preparación técnica en repo; **publicación en tiendas** requiere cuentas developer y decisión de producto.

## Configuración técnica aplicada

### Android (`frontend/android/`)

- `applicationId` configurable: `com.avov.platform` (reemplaza `com.example.avov_frontend`).
- Release: **no** usa `usesCleartextTraffic` en el manifest de release; debug puede usar cleartext para E2E local.
- Firma release: requiere `key.properties` + keystore **fuera de git** (plantilla `android/key.properties.example`).
- Hasta configurar keystore, el build release documenta el bloqueo; no enviar a Play con firma debug.

### iOS (`frontend/ios/`)

- Bundle ID objetivo: `com.avov.platform` (ajustar en Xcode / `AppInfo` según cuenta Apple).
- Display name: `AVOV`.
- Requiere certificado y perfil de distribución en la cuenta del equipo.

### Web / PWA

- Actualizar `web/manifest.json` con nombre `AVOV` y descripción de orientación vocacional (sin texto genérico Flutter).

## Paridad de flujos v1

Validar en dispositivo real o emulador:

1. Login / logout / change-password / forgot-password
2. Espacio estudiante: test, resultados, PDF, asistente
3. Admin institución: estudiantes, orientadores, asignaciones
4. Orientador: listado, sesión, observaciones

API: `--dart-define=API_BASE_URL=https://<dominio>/api/v1` (HTTPS en release).

## Tiendas (bloqueado por cuentas)

| Paso | Play Console | App Store Connect |
|------|--------------|-------------------|
| Cuenta developer | Pendiente decisión | Pendiente decisión |
| Ficha / privacidad / age rating | Pendiente texto legal | Pendiente |
| Build firmado | Tras keystore | Tras certificados |
| Envío / revisión | Externo | Externo |

Evidencia de cierre F9-STORE: URL de ficha o rechazo documentado de la tienda tras cumplir requisitos técnicos.
