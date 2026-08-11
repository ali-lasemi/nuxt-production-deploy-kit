#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="${APP_NAME:-nuxt-app}"
APP_PORT="${APP_PORT:-3000}"
APP_DIR="${APP_DIR:-/opt/nuxt-app}"
HEALTH_PATH="${HEALTH_PATH:-/}"
PUBLIC_URL="${PUBLIC_URL:-}"
AUDIT_LOG="${AUDIT_LOG:-/var/log/nuxt-app/deployments.jsonl}"
JOURNAL_LINES="${JOURNAL_LINES:-100}"

section() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

run_safe() {
  "$@" 2>&1 || true
}

section "Incident Diagnostics"

echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "hostname=$(hostname)"
echo "application=$APP_NAME"
echo "application_port=$APP_PORT"
echo "application_directory=$APP_DIR"

section "Active Release"

if [[ -L "$APP_DIR/current" ]]; then
  run_safe readlink -f "$APP_DIR/current"
else
  echo "No standard current release symlink found."
fi

section "Blue-Green Slots"

for slot in blue green; do
  if [[ -L "$APP_DIR/$slot/current" ]]; then
    printf '%s=' "$slot"
    run_safe readlink -f "$APP_DIR/$slot/current"
  else
    echo "$slot=not-configured"
  fi
done

section "systemd Service"

run_safe systemctl status "$APP_NAME" --no-pager

section "systemd Blue-Green Services"

run_safe systemctl status "${APP_NAME}@blue.service" --no-pager
run_safe systemctl status "${APP_NAME}@green.service" --no-pager

section "Recent Application Journal"

run_safe journalctl -u "$APP_NAME" -n "$JOURNAL_LINES" --no-pager

section "Recent Blue Journal"

run_safe journalctl -u "${APP_NAME}@blue.service" -n "$JOURNAL_LINES" --no-pager

section "Recent Green Journal"

run_safe journalctl -u "${APP_NAME}@green.service" -n "$JOURNAL_LINES" --no-pager

section "Local Health"

run_safe curl \
  --silent \
  --show-error \
  --max-time 5 \
  --write-out $'\nHTTP %{http_code}\n' \
  "http://127.0.0.1:${APP_PORT}${HEALTH_PATH}"

section "Blue Health"

run_safe curl \
  --silent \
  --show-error \
  --max-time 5 \
  --write-out $'\nHTTP %{http_code}\n' \
  "http://127.0.0.1:3001${HEALTH_PATH}"

section "Green Health"

run_safe curl \
  --silent \
  --show-error \
  --max-time 5 \
  --write-out $'\nHTTP %{http_code}\n' \
  "http://127.0.0.1:3002${HEALTH_PATH}"

if [[ -n "$PUBLIC_URL" ]]; then
  section "Public Health"

  run_safe curl \
    --silent \
    --show-error \
    --max-time 10 \
    --write-out $'\nHTTP %{http_code}\n' \
    "$PUBLIC_URL"
fi

section "Nginx Validation"

run_safe nginx -t

section "Nginx Processes"

run_safe ps -ef
run_safe sh -c 'ps -ef | grep "[n]ginx"'

section "Listening Ports"

run_safe ss -lntp

section "Disk Usage"

run_safe df -h "$APP_DIR"

section "Release Inventory"

if [[ -d "$APP_DIR/releases" ]]; then
  run_safe find "$APP_DIR/releases" -mindepth 1 -maxdepth 1 -type d -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n'
fi

for slot in blue green; do
  if [[ -d "$APP_DIR/$slot/releases" ]]; then
    echo
    echo "[$slot]"
    run_safe find "$APP_DIR/$slot/releases" -mindepth 1 -maxdepth 1 -type d -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n'
  fi
done

section "Deployment Audit"

if [[ -f "$AUDIT_LOG" ]]; then
  run_safe tail -n 50 "$AUDIT_LOG"
else
  echo "Audit log not found: $AUDIT_LOG"
fi

section "Diagnostic Collection Complete"

echo "Review output before sharing externally."
echo "Do not include secret environment files, tokens, credentials, or private keys."