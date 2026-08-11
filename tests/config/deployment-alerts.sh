#!/usr/bin/env bash
set -Eeuo pipefail

RULE_FILE="${1:-examples/monitoring/deployment-alerts.yml}"
ALERTMANAGER_FILE="${2:-examples/monitoring/alertmanager.yml}"

fail() {
  echo "ERROR: $1"
  exit 1
}

require_text() {
  local file="$1"
  local text="$2"

  if ! grep -Fq -- "$text" "$file"; then
    fail "Missing expected alert policy in $file: $text"
  fi
}

[[ -f "$RULE_FILE" ]] || fail "Prometheus rule file not found"
[[ -f "$ALERTMANAGER_FILE" ]] || fail "Alertmanager example not found"

require_text "$RULE_FILE" "alert: NuxtDeploymentFailure"
require_text "$RULE_FILE" "alert: NuxtAutomaticRollbackTriggered"
require_text "$RULE_FILE" "alert: NuxtDeploymentMetricsMissing"
require_text "$RULE_FILE" "alert: NuxtDeploymentFailureNewerThanSuccess"

require_text "$RULE_FILE" 'nuxt_deployment_events_total'
require_text "$RULE_FILE" 'nuxt_deployment_audit_events'
require_text "$RULE_FILE" 'nuxt_deployment_last_failure_timestamp_seconds'
require_text "$RULE_FILE" 'nuxt_deployment_last_success_timestamp_seconds'

require_text "$RULE_FILE" "severity: critical"
require_text "$RULE_FILE" "severity: warning"
require_text "$RULE_FILE" "runbook: docs/incident-response.md"

require_text "$ALERTMANAGER_FILE" "receiver: operations"
require_text "$ALERTMANAGER_FILE" "send_resolved: true"

if grep -Eiq '(api[_-]?key|token|password|secret):[[:space:]]*[^[:space:]]+' "$ALERTMANAGER_FILE"; then
  fail "Alertmanager example must not contain credentials"
fi

echo "Deployment alert policy validated."