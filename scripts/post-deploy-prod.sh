#!/usr/bin/env bash
# AVOV - Checklist post-despliegue en servidor Linux (Fase 41)
set -euo pipefail

BASE_URL="${1:-}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@avov.edu.co}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Admin123!}"

if [[ -z "$BASE_URL" ]]; then
  echo "Uso: $0 <BASE_URL>"
  echo "Ejemplo: $0 https://api.tudominio.edu.co/api/v1"
  exit 1
fi

failures=0

pass() { echo "[OK] $1"; }
fail() { echo "[FALLO] $1"; failures=$((failures + 1)); }

echo "=== AVOV Post-Deploy (Linux) ==="
echo "BaseUrl: $BASE_URL"
echo ""

if curl -fsS "$BASE_URL/health/live" | grep -q '"success":true'; then
  pass "Health live"
else
  fail "Health live"
fi

if curl -fsS "$BASE_URL/health" | grep -q '"mysql":true'; then
  pass "Health completo MySQL"
else
  fail "Health completo MySQL"
fi

if curl -fsS "$BASE_URL/settings/public" | grep -q 'app_display_name'; then
  pass "Settings publicas"
else
  fail "Settings publicas"
fi

TOKEN=""
LOGIN_JSON="$(curl -fsS -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" 2>/dev/null || true)"

if [[ -n "$LOGIN_JSON" ]]; then
  TOKEN="$(printf '%s' "$LOGIN_JSON" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("data",{}).get("access_token",""))' 2>/dev/null || true)"
fi

if [[ -n "$TOKEN" ]]; then
  pass "Login super admin"
  if curl -fsS -H "Authorization: Bearer $TOKEN" "$BASE_URL/auth/me" | grep -q 'SUPER_ADMIN'; then
    pass "Rol super admin"
  else
    fail "Rol super admin"
  fi
  if curl -fsS -X POST -H "Authorization: Bearer $TOKEN" "$BASE_URL/vector/rebuild-careers" | grep -q '"indexed"'; then
    pass "Rebuild Qdrant"
  else
    fail "Rebuild Qdrant"
  fi
else
  fail "Login super admin"
fi

if [[ "$BASE_URL" == https://* ]]; then
  if curl -fsSI "$BASE_URL/health/live" | grep -qi 'strict-transport-security'; then
    pass "Cabecera HSTS"
  else
    fail "Cabecera HSTS"
  fi
fi

ROOT_URL="${BASE_URL%/api/v1}"
DOCS_CODE="$(curl -s -o /dev/null -w '%{http_code}' "$ROOT_URL/docs" || echo 000)"
if [[ "$DOCS_CODE" == "404" ]]; then
  pass "OpenAPI bloqueado"
else
  fail "OpenAPI bloqueado (codigo $DOCS_CODE)"
fi

echo ""
if [[ $failures -gt 0 ]]; then
  echo "Post-deploy FALLO: $failures error(es)"
  exit 1
fi

echo "Post-deploy OK"
exit 0
