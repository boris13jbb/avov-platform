#!/usr/bin/env bash
# AVOV - Obtener certificados Let's Encrypt (Fase 42)
# Ejecutar EN EL SERVIDOR con DNS apuntando al host.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

API_DOMAIN="${API_DOMAIN:-}"
FRONTEND_DOMAIN="${FRONTEND_DOMAIN:-}"
EMAIL="${LETSENCRYPT_EMAIL:-}"

if [[ -f .env ]]; then
  [[ -n "$API_DOMAIN" ]] || API_DOMAIN="$(grep -E '^API_DOMAIN=' .env | head -1 | cut -d= -f2- | tr -d '\r' || true)"
  [[ -n "$FRONTEND_DOMAIN" ]] || FRONTEND_DOMAIN="$(grep -E '^FRONTEND_DOMAIN=' .env | head -1 | cut -d= -f2- | tr -d '\r' || true)"
fi

if [[ -z "$API_DOMAIN" || -z "$FRONTEND_DOMAIN" ]]; then
  echo "ERROR: Define API_DOMAIN y FRONTEND_DOMAIN en .env o variables de entorno"
  exit 1
fi

if [[ -z "$EMAIL" ]]; then
  echo "ERROR: Define LETSENCRYPT_EMAIL (correo para Let's Encrypt)"
  exit 1
fi

command -v certbot >/dev/null 2>&1 || {
  echo "Instala certbot: sudo apt install certbot"
  exit 1
}

mkdir -p nginx/certs

echo "=== Certbot standalone (detener nginx si esta activo) ==="
docker compose -f docker-compose.prod.yml -p "${AVOV_PROD_PROJECT:-avov-prod}" stop nginx 2>/dev/null || true

sudo certbot certonly --standalone --non-interactive --agree-tos \
  -m "$EMAIL" \
  -d "$API_DOMAIN" \
  -d "$FRONTEND_DOMAIN"

sudo cp "/etc/letsencrypt/live/${API_DOMAIN}/fullchain.pem" nginx/certs/fullchain.pem
sudo cp "/etc/letsencrypt/live/${API_DOMAIN}/privkey.pem" nginx/certs/privkey.pem
sudo chown "$(whoami)" nginx/certs/fullchain.pem nginx/certs/privkey.pem

echo ""
echo "Certificados copiados a nginx/certs/"
echo "Levanta con SSL + web:"
echo "  AVOV_PROD_SSL=1 AVOV_PROD_WEB=1 ./scripts/deploy-prod-server.sh"
