#!/usr/bin/env bash
# AVOV - Smoke release publico (API + Flutter Web) — Fase 44
set -euo pipefail

API_URL="${1:-}"
FRONTEND_URL="${2:-}"
HTTP_API_URL="${3:-}"
CORS_ORIGIN="${CORS_ORIGIN:-$FRONTEND_URL}"

if [[ -z "$API_URL" ]]; then
  echo "Uso: $0 <API_URL> [FRONTEND_URL] [HTTP_API_URL]"
  echo "Ejemplo: $0 https://api.dominio.edu.co/api/v1 https://app.dominio.edu.co http://api.dominio.edu.co/api/v1"
  exit 1
fi

API_URL="${API_URL%/}"
if [[ "$API_URL" != */api/v1 ]]; then
  API_URL="${API_URL%/}/api/v1"
fi
if [[ -z "$FRONTEND_URL" ]]; then
  FRONTEND_URL="${API_URL%/api/v1}"
fi
FRONTEND_URL="${FRONTEND_URL%/}"
CORS_ORIGIN="${CORS_ORIGIN:-$FRONTEND_URL}"

failures=0
pass() { echo "[OK] $1"; }
fail() { echo "[FALLO] $1"; failures=$((failures + 1)); }

echo "=== AVOV Smoke Public Release (Fase 44) ==="
echo "ApiUrl: $API_URL"
echo "FrontendUrl: $FRONTEND_URL"
echo ""

if curl -fsS "$API_URL/health/live" | grep -q '"success":true'; then
  pass "Health live"
else
  fail "Health live"
fi

if curl -fsS "$API_URL/health" | grep -q '"mysql":true' && curl -fsS "$API_URL/health" | grep -q '"qdrant":true'; then
  pass "Servicios backend"
else
  fail "Servicios backend"
fi

if curl -fsS "$API_URL/settings/public" | grep -q 'app_display_name'; then
  pass "Settings publicas"
else
  fail "Settings publicas"
fi

if curl -fsS -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@avov.edu.co","password":"Admin123!"}' | grep -q 'access_token'; then
  pass "Login super admin"
else
  fail "Login super admin"
fi

if curl -fsSI -H "Origin: $CORS_ORIGIN" "$API_URL/settings/public" | grep -qi 'access-control-allow-origin'; then
  pass "CORS origin frontend"
else
  fail "CORS origin frontend"
fi

FE_BODY="$(curl -fsS "$FRONTEND_URL/" || true)"
if [[ -n "$FE_BODY" ]] && [[ "$FE_BODY" == *flutter* || "$FE_BODY" == *main.dart.js* || "$FE_BODY" == *"<!DOCTYPE html"* ]]; then
  pass "Frontend raiz"
else
  fail "Frontend raiz"
fi

SPA_BODY="$(curl -fsS "$FRONTEND_URL/login" || true)"
if [[ -n "$SPA_BODY" ]] && [[ "$SPA_BODY" == *flutter* || "$SPA_BODY" == *main.dart.js* || "$SPA_BODY" == *"<!DOCTYPE html"* ]]; then
  pass "SPA fallback /login"
else
  fail "SPA fallback /login"
fi

if [[ "$API_URL" == https://* ]]; then
  if curl -fsSI "$API_URL/health/live" | grep -qi 'strict-transport-security'; then
    pass "HSTS API"
  else
    fail "HSTS API"
  fi
fi

if [[ -n "$HTTP_API_URL" ]]; then
  HTTP_API_URL="${HTTP_API_URL%/}/health/live"
  CODE="$(curl -s -o /dev/null -w '%{http_code}' "$HTTP_API_URL" || echo 000)"
  if [[ "$CODE" =~ ^30[1278]$ ]]; then
    pass "Redirect HTTP a HTTPS"
  else
    fail "Redirect HTTP a HTTPS (codigo $CODE)"
  fi
fi

echo ""
if [[ $failures -gt 0 ]]; then
  echo "Smoke FALLO: $failures error(es)"
  exit 1
fi
echo "Smoke public release OK"
exit 0
