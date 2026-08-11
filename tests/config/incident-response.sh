#!/usr/bin/env bash
set -Eeuo pipefail

RUNBOOK="${1:-docs/incident-response.md}"
DIAGNOSTIC_SCRIPT="${2:-scripts/collect-incident-diagnostics.sh}"

fail() {
  echo "ERROR: $1"
  exit 1
}

require_text() {
  local file="$1"
  local expected="$2"

  if ! grep -Fq -- "$expected" "$file"; then
    fail "Missing incident-response requirement in $file: $expected"
  fi
}

[[ -f "$RUNBOOK" ]] || fail "Incident response runbook not found"
[[ -f "$DIAGNOSTIC_SCRIPT" ]] || fail "Incident diagnostics script not found"

require_text "$RUNBOOK" "Failed Standard Deployment"
require_text "$RUNBOOK" "Automatic Rollback Failure"
require_text "$RUNBOOK" "Blue-Green Deployment Failure"
require_text "$RUNBOOK" "Manual Blue-Green Traffic Rollback"
require_text "$RUNBOOK" "Nginx Failure"
require_text "$RUNBOOK" "systemd Failure"
require_text "$RUNBOOK" "Deployment Lock Incident"
require_text "$RUNBOOK" "Secret or Permission Incident"
require_text "$RUNBOOK" "Alert Response"
require_text "$RUNBOOK" "Recovery Verification"
require_text "$RUNBOOK" "Post-Incident Review"
require_text "$RUNBOOK" "Never attach or paste"

require_text "$DIAGNOSTIC_SCRIPT" 'journalctl -u "$APP_NAME"'
require_text "$DIAGNOSTIC_SCRIPT" 'nginx -t'
require_text "$DIAGNOSTIC_SCRIPT" 'ss -lntp'
require_text "$DIAGNOSTIC_SCRIPT" 'tail -n 50 "$AUDIT_LOG"'

if grep -Fq 'cat /etc/nuxt-app/nuxt-app.env' "$DIAGNOSTIC_SCRIPT"; then
  fail "Diagnostic script must never print the production secret environment file"
fi

if grep -Fq 'cat "$CONFIG_DIR' "$DIAGNOSTIC_SCRIPT"; then
  fail "Diagnostic script must not dump configuration secrets"
fi

echo "Incident response policy validated."