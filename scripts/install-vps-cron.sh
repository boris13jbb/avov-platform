#!/usr/bin/env bash
# AVOV - Instala cron de backups + monitoreo en VPS Linux (Fase 43)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AVOV_ROOT="${AVOV_ROOT:-$ROOT}"
CRON_USER="${CRON_USER:-$(whoami)}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

if [[ ! -x "$AVOV_ROOT/scripts/backup-all.sh" ]]; then
  chmod +x "$AVOV_ROOT/scripts/"*.sh 2>/dev/null || true
fi

CRON_FILE="/tmp/avov-cron-$$"
cat > "$CRON_FILE" <<EOF
# AVOV - Backups y monitoreo (generado $(date -Iseconds))
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Backup completo diario 02:00
0 2 * * * cd ${AVOV_ROOT} && AVOV_PROD_WEB=\${AVOV_PROD_WEB:-1} AVOV_PROD_SSL=\${AVOV_PROD_SSL:-1} ./scripts/backup-all.sh prod >> ./logs/backup-cron.log 2>&1

# Retencion backups 02:30
30 2 * * * cd ${AVOV_ROOT} && RETENTION_DAYS=${RETENTION_DAYS} ./scripts/prune-backups.sh >> ./logs/backup-cron.log 2>&1

# Monitoreo cada 5 minutos
*/5 * * * * cd ${AVOV_ROOT} && API_BASE_URL=\$(grep -E '^API_BASE_URL=' .env | head -1 | cut -d= -f2- | tr -d '\r') ./scripts/monitor-health.sh "\${API_BASE_URL}" >> ./logs/monitor-health.log 2>&1
EOF

mkdir -p "$AVOV_ROOT/logs"

echo "=== Cron propuesto AVOV ==="
cat "$CRON_FILE"
echo ""

if [[ "${INSTALL:-0}" == "1" ]]; then
  crontab -l 2>/dev/null | grep -v '# AVOV' | grep -v 'scripts/backup-all.sh' | grep -v 'scripts/prune-backups.sh' | grep -v 'scripts/monitor-health.sh' > /tmp/avov-cron-existing || true
  cat /tmp/avov-cron-existing "$CRON_FILE" | crontab -
  echo "Crontab instalado para usuario $CRON_USER"
else
  echo "Modo preview. Para instalar: INSTALL=1 AVOV_ROOT=$AVOV_ROOT $0"
fi

rm -f "$CRON_FILE"
