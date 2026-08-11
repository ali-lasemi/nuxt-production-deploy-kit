#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"
AUDIT_LOG="$TEST_ROOT/deployments.jsonl"

cleanup() {
  rm -rf -- "$TEST_ROOT"
}

trap cleanup EXIT

node "$ROOT_DIR/scripts/deployment-event.mjs" append "$AUDIT_LOG" \
  "operation=deploy" \
  "result=started" \
  "application=nuxt-app" \
  "release=20260811120000" \
  "previous_release=20260811110000" \
  "source_commit=abc123" \
  "actor=integration-test" \
  "message=Deployment started."

node "$ROOT_DIR/scripts/deployment-event.mjs" append "$AUDIT_LOG" \
  "operation=deploy" \
  "result=success" \
  "application=nuxt-app" \
  "release=20260811120000" \
  "previous_release=20260811110000" \
  "source_commit=abc123" \
  "actor=integration-test" \
  "message=Deployment completed."

node "$ROOT_DIR/scripts/deployment-event.mjs" verify "$AUDIT_LOG"

event_count="$(wc -l <"$AUDIT_LOG" | tr -d ' ')"

if [[ "$event_count" != "2" ]]; then
  echo "ERROR: Expected 2 audit events, found $event_count"
  exit 1
fi

first_operation="$(
  node -e '
    const fs = require("fs");
    const file = process.argv[1];
    const first = JSON.parse(fs.readFileSync(file, "utf8").trim().split("\n")[0]);
    process.stdout.write(first.operation);
  ' "$AUDIT_LOG"
)"

if [[ "$first_operation" != "deploy" ]]; then
  echo "ERROR: Unexpected first audit operation: $first_operation"
  exit 1
fi

AUDIT_LOG="$AUDIT_LOG" "$ROOT_DIR/scripts/audit-releases.sh" show >/dev/null
AUDIT_LOG="$AUDIT_LOG" "$ROOT_DIR/scripts/audit-releases.sh" verify >/dev/null

echo "Deployment audit integration test passed."