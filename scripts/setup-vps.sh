#!/usr/bin/env bash
# AVOV - Bootstrap VPS Linux (Fase 43)
# Ejecutar en servidor limpio con Docker ya instalado.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
AVOV_ROOT="${AVOV_ROOT:-$ROOT}"

echo "=== AVOV Setup VPS ==="

command -v docker >/dev/null 2>&1 || { echo "ERROR: instala Docker antes de continuar"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERROR: instala git"; exit 1; }

chmod +x scripts/*.sh 2>/dev/null || true
mkdir -p logs backups/mysql backups/qdrant backups/storage nginx/certs

if [[ ! -f .env ]]; then
  cp .env.production.server.example .env
  echo "ADVERTENCIA: .env creado. Edita dominios y claves antes de produccion."
  exit 1
fi

if [[ ! -f frontend/build/web/index.html ]]; then
  ./scripts/build-flutter-web.sh
fi

AVOV_PROD_SSL="${AVOV_PROD_SSL:-1}" AVOV_PROD_WEB="${AVOV_PROD_WEB:-1}" ./scripts/deploy-prod-server.sh

API_URL="$(grep -E '^API_BASE_URL=' .env | head -1 | cut -d= -f2- | tr -d '\r')"
./scripts/post-deploy-prod.sh "$API_URL"

echo ""
echo "=== Post-setup recomendado ==="
echo "1. LETSENCRYPT_EMAIL=... ./scripts/setup-letsencrypt.sh (si aun no hay certs)"
echo "2. INSTALL=1 AVOV_ROOT=$AVOV_ROOT ./scripts/install-vps-cron.sh"
echo "3. Ejecutar checklist UI: docs/fase-41-flutter-ui-manual.md"
