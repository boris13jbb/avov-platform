#!/usr/bin/env bash
# AVOV - Monitoreo de salud API + servicios (Fase 43)
set -euo pipefail

BASE_URL="${1:-http://localhost/api/v1/health/live}"
BASE_URL="${BASE_URL%/health/live}"
BASE_URL="${BASE_URL%/}"
DISK_WARN="${DISK_WARN_PERCENT:-85}"
REPORT="${MONITOR_REPORT:-./logs/monitor-health.log}"

mkdir -p "$(dirname "$REPORT")"
ts="$(date -Iseconds)"
fail=0

check() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "[$ts] [OK] $name" | tee -a "$REPORT"
  else
    echo "[$ts] [FALLO] $name" | tee -a "$REPORT"
    fail=1
  fi
}

check "Health live" "curl -fsS '${BASE_URL}/health/live' | grep -q '\"success\":true'"
check "Health completo MySQL" "curl -fsS '${BASE_URL}/health' | grep -q '\"mysql\":true'"
check "Health completo Redis" "curl -fsS '${BASE_URL}/health' | grep -q '\"redis\":true'"
check "Health completo Qdrant" "curl -fsS '${BASE_URL}/health' | grep -q '\"qdrant\":true'"

if command -v df >/dev/null 2>&1; then
  used="$(df -P / | awk 'NR==2 {print $5}' | tr -d '%')"
  if [[ "$used" -ge "$DISK_WARN" ]]; then
    echo "[$ts] [FALLO] Disco ${used}% (umbral ${DISK_WARN}%)" | tee -a "$REPORT"
    fail=1
  else
    echo "[$ts] [OK] Disco ${used}%" | tee -a "$REPORT"
  fi
fi

exit "$fail"
