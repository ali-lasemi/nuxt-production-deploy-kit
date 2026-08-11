#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

AUDIT_LOG="${AUDIT_LOG:-/var/log/nuxt-app/deployments.jsonl}"
METRICS_FILE="${METRICS_FILE:-/var/lib/node_exporter/textfile_collector/nuxt-deployment.prom}"

if [[ ! -f "$AUDIT_LOG" ]]; then
  echo "ERROR: Deployment audit log not found: $AUDIT_LOG"
  exit 1
fi

mkdir -p "$(dirname "$METRICS_FILE")"

node "$SCRIPT_DIR/deployment-metrics.mjs" \
  "$AUDIT_LOG" \
  "$METRICS_FILE"

echo "Deployment metrics export completed."
echo "Audit log: $AUDIT_LOG"
echo "Metrics file: $METRICS_FILE"