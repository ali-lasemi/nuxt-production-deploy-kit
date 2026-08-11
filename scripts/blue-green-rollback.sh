#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=deployment-events.sh
source "$SCRIPT_DIR/deployment-events.sh"

APP_DIR="${APP_DIR:-/opt/nuxt-app}"

BLUE_PORT="${BLUE_PORT:-3001}"
GREEN_PORT="${GREEN_PORT:-3002}"

HEALTH_PATH="${HEALTH_PATH:-/}"

NGINX_ACTIVE_UPSTREAM="${NGINX_ACTIVE_UPSTREAM:-/etc/nginx/conf.d/nuxt-active-upstream.conf}"
NGINX_BIN="${NGINX_BIN:-nginx}"

DEPLOY_LOCK_FILE="${DEPLOY_LOCK_FILE:-$APP_DIR/.deployment.lock}"
DEPLOY_LOCK_TIMEOUT="${DEPLOY_LOCK_TIMEOUT:-30}"

acquire_lock() {
  mkdir -p "$(dirname "$DEPLOY_LOCK_FILE")"

  exec {DEPLOY_LOCK_FD}>"$DEPLOY_LOCK_FILE"

  if ! flock -w "$DEPLOY_LOCK_TIMEOUT" "$DEPLOY_LOCK_FD"; then
    echo "ERROR: Could not acquire deployment lock."
    exit 3
  fi
}

detect_active_slot() {
  if grep -Fq "127.0.0.1:${BLUE_PORT}" "$NGINX_ACTIVE_UPSTREAM"; then
    echo "blue"
    return
  fi

  if grep -Fq "127.0.0.1:${GREEN_PORT}" "$NGINX_ACTIVE_UPSTREAM"; then
    echo "green"
    return
  fi

  echo "ERROR: Unable to determine active slot." >&2
  exit 1
}

write_upstream() {
  local slot="$1"
  local port="$2"
  local output="$3"

  cat >"$output" <<EOF
upstream nuxt_active {
    server 127.0.0.1:${port};
    keepalive 32;
}
EOF

  echo "slot=${slot}" >>"$output"
}

if [[ ! -f "$NGINX_ACTIVE_UPSTREAM" ]]; then
  echo "ERROR: Active upstream file not found."
  exit 1
fi

acquire_lock

ACTIVE_SLOT="$(detect_active_slot)"

if [[ "$ACTIVE_SLOT" == "blue" ]]; then
  TARGET_SLOT="green"
  TARGET_PORT="$GREEN_PORT"
else
  TARGET_SLOT="blue"
  TARGET_PORT="$BLUE_PORT"
fi

TARGET_CURRENT="$APP_DIR/$TARGET_SLOT/current"

if [[ ! -e "$TARGET_CURRENT" ]]; then
  echo "ERROR: Rollback slot has no active release: $TARGET_SLOT"
  exit 1
fi

emit_deployment_event "blue_green_rollback" "started" "" "" "$TARGET_SLOT" "$ACTIVE_SLOT" "Traffic rollback started."`n`necho "Current traffic slot: $ACTIVE_SLOT"
echo "Rollback traffic slot: $TARGET_SLOT"

if ! "$SCRIPT_DIR/healthcheck.sh" "http://127.0.0.1:${TARGET_PORT}${HEALTH_PATH}"; then
  echo "ERROR: Rollback target is not healthy."
  exit 1
fi

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

write_upstream "$TARGET_SLOT" "$TARGET_PORT" "$TMP_FILE"

sudo cp "$TMP_FILE" "$NGINX_ACTIVE_UPSTREAM"

if ! sudo "$NGINX_BIN" -t; then
  echo "ERROR: Nginx configuration validation failed."
  exit 1
fi

sudo "$NGINX_BIN" -s reload

echo
emit_deployment_event "blue_green_rollback" "success" "" "" "$TARGET_SLOT" "$ACTIVE_SLOT" "Traffic rollback completed successfully."`n`necho "Traffic rollback completed successfully."
echo "Active slot: $TARGET_SLOT"
echo "Active port: $TARGET_PORT"