#!/usr/bin/env bash
# AVOV - Build Flutter Web para produccion (Fase 42)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND="$ROOT/frontend"
ENV_FILE="${ENV_FILE:-$ROOT/.env}"
API_BASE_URL="${API_BASE_URL:-}"

if [[ -z "$API_BASE_URL" && -f "$ENV_FILE" ]]; then
  API_BASE_URL="$(grep -E '^API_BASE_URL=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r' | tr -d '"' | tr -d "'")"
fi

if [[ -z "$API_BASE_URL" ]]; then
  echo "ERROR: Define API_BASE_URL o ENV_FILE con API_BASE_URL"
  exit 1
fi

if [[ "$API_BASE_URL" == *tudominio.edu.co* || "$API_BASE_URL" == *CAMBIAR* ]]; then
  echo "ERROR: API_BASE_URL contiene placeholder"
  exit 1
fi

command -v flutter >/dev/null 2>&1 || { echo "ERROR: Flutter no instalado"; exit 1; }

cd "$FRONTEND"
echo "=== AVOV Build Flutter Web ==="
echo "API_BASE_URL: $API_BASE_URL"

flutter pub get
flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"

[[ -f build/web/index.html ]] || { echo "ERROR: falta build/web/index.html"; exit 1; }
echo "Build web OK: frontend/build/web/"
