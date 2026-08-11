#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf -- "$TEST_ROOT"
}

trap cleanup EXIT

AUDIT_LOG="$TEST_ROOT/deployments.jsonl"
METRICS_FILE="$TEST_ROOT/nuxt-deployment.prom"

cat >"$AUDIT_LOG" <<'EOF'
{"schema_version":1,"timestamp":"2026-08-11T10:00:00.000Z","operation":"deploy","result":"started","application":"nuxt-app","release":"r1","previous_release":"","slot":"","previous_slot":"","source_commit":"a","actor":"test","message":"started"}
{"schema_version":1,"timestamp":"2026-08-11T10:00:10.000Z","operation":"deploy","result":"success","application":"nuxt-app","release":"r1","previous_release":"","slot":"","previous_slot":"","source_commit":"a","actor":"test","message":"success"}
{"schema_version":1,"timestamp":"2026-08-11T11:00:00.000Z","operation":"deploy","result":"critical_failure","application":"nuxt-app","release":"r2","previous_release":"r1","slot":"","previous_slot":"","source_commit":"b","actor":"test","message":"failed"}
{"schema_version":1,"timestamp":"2026-08-11T11:00:10.000Z","operation":"automatic_rollback","result":"success","application":"nuxt-app","release":"r1","previous_release":"r2","slot":"","previous_slot":"","source_commit":"b","actor":"test","message":"rollback"}
EOF

node "$ROOT_DIR/scripts/deployment-metrics.mjs" \
  "$AUDIT_LOG" \
  "$METRICS_FILE"

grep -Fq 'nuxt_deployment_events_total{operation="deploy",result="started"} 1' "$METRICS_FILE"
grep -Fq 'nuxt_deployment_events_total{operation="deploy",result="success"} 1' "$METRICS_FILE"
grep -Fq 'nuxt_deployment_events_total{operation="deploy",result="critical_failure"} 1' "$METRICS_FILE"
grep -Fq 'nuxt_deployment_events_total{operation="automatic_rollback",result="success"} 1' "$METRICS_FILE"

grep -Fq 'nuxt_deployment_last_success_timestamp_seconds{operation="deploy"}' "$METRICS_FILE"
grep -Fq 'nuxt_deployment_last_failure_timestamp_seconds{operation="deploy"}' "$METRICS_FILE"

grep -Fq 'nuxt_deployment_audit_events 4' "$METRICS_FILE"

echo "Deployment metrics integration test passed."