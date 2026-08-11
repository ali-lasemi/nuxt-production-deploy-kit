#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

AUDIT_LOG="${AUDIT_LOG:-/var/log/nuxt-app/deployments.jsonl}"

COMMAND="${1:-show}"

case "$COMMAND" in
  show)
    node "$SCRIPT_DIR/deployment-event.mjs" show "$AUDIT_LOG"
    ;;
  verify)
    node "$SCRIPT_DIR/deployment-event.mjs" verify "$AUDIT_LOG"
    ;;
  *)
    echo "ERROR: Usage: audit-releases.sh [show|verify]"
    exit 2
    ;;
esac