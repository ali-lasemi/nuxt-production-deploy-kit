#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

APP_NAME="${APP_NAME:-nuxt-app}"
APP_PORT="${APP_PORT:-3000}"
HEALTH_PATH="${HEALTH_PATH:-/}"
PUBLIC_URL="${PUBLIC_URL:-}"

if [[ "$HEALTH_PATH" != /* ]]; then
  HEALTH_PATH="/$HEALTH_PATH"
fi

LOCAL_URL="http://127.0.0.1:${APP_PORT}${HEALTH_PATH}"

service_result="FAILED"
local_result="FAILED"
public_result="SKIPPED"

print_summary() {
  echo
  echo "========================================"
  echo " Deployment Validation Summary"
  echo "========================================"
  printf "%-20s %s\n" "Application:" "$APP_NAME"
  printf "%-20s %s\n" "Service:" "$service_result"
  printf "%-20s %s\n" "Local endpoint:" "$local_result"
  printf "%-20s %s\n" "Public endpoint:" "$public_result"
  printf "%-20s %s\n" "Local URL:" "$LOCAL_URL"

  if [[ -n "$PUBLIC_URL" ]]; then
    printf "%-20s %s\n" "Public URL:" "$PUBLIC_URL"
  fi

  echo "========================================"
}

fail() {
  echo "FAIL: $1"
  print_summary
  exit 1
}

echo "[1/3] Checking systemd service: $APP_NAME"

if ! systemctl is-active --quiet "$APP_NAME"; then
  systemctl --no-pager --full status "$APP_NAME" || true
  fail "systemd service '$APP_NAME' is not active."
fi

service_result="HEALTHY"
echo "PASS: Service is active."

echo
echo "[2/3] Checking local endpoint: $LOCAL_URL"

if ! "$SCRIPT_DIR/healthcheck.sh" "$LOCAL_URL"; then
  fail "Local endpoint validation failed."
fi

local_result="HEALTHY"

echo
echo "[3/3] Checking public endpoint"

if [[ -z "$PUBLIC_URL" ]]; then
  echo "SKIP: PUBLIC_URL is not configured."
else
  public_health_url="${PUBLIC_URL%/}${HEALTH_PATH}"

  if ! "$SCRIPT_DIR/healthcheck.sh" "$public_health_url"; then
    public_result="FAILED"
    fail "Public endpoint validation failed."
  fi

  public_result="HEALTHY"
fi

print_summary

echo
echo "Post-deployment validation completed successfully."
