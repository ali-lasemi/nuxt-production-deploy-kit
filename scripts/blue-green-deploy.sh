#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=deployment-events.sh
source "$SCRIPT_DIR/deployment-events.sh"

APP_NAME="${APP_NAME:-nuxt-app}"
APP_DIR="${APP_DIR:-/opt/nuxt-app}"

BLUE_PORT="${BLUE_PORT:-3001}"
GREEN_PORT="${GREEN_PORT:-3002}"

HEALTH_PATH="${HEALTH_PATH:-/}"
PUBLIC_URL="${PUBLIC_URL:-}"

NGINX_ACTIVE_UPSTREAM="${NGINX_ACTIVE_UPSTREAM:-/etc/nginx/conf.d/nuxt-active-upstream.conf}"
NGINX_BIN="${NGINX_BIN:-nginx}"
SYSTEMCTL_BIN="${SYSTEMCTL_BIN:-systemctl}"

DEPLOY_LOCK_FILE="${DEPLOY_LOCK_FILE:-$APP_DIR/.deployment.lock}"
DEPLOY_LOCK_TIMEOUT="${DEPLOY_LOCK_TIMEOUT:-30}"

BUILD_ARCHIVE="${1:-build.zip}"
TIMESTAMP="$(date -u +%Y%m%d%H%M%S)"

acquire_lock() {
  mkdir -p "$(dirname "$DEPLOY_LOCK_FILE")"

  exec {DEPLOY_LOCK_FD}>"$DEPLOY_LOCK_FILE"

  if ! flock -w "$DEPLOY_LOCK_TIMEOUT" "$DEPLOY_LOCK_FD"; then
    echo "ERROR: Could not acquire deployment lock."
    exit 3
  fi
}

detect_active_slot() {
  if [[ ! -f "$NGINX_ACTIVE_UPSTREAM" ]]; then
    echo "blue"
    return
  fi

  if grep -Fq "127.0.0.1:${BLUE_PORT}" "$NGINX_ACTIVE_UPSTREAM"; then
    echo "blue"
    return
  fi

  if grep -Fq "127.0.0.1:${GREEN_PORT}" "$NGINX_ACTIVE_UPSTREAM"; then
    echo "green"
    return
  fi

  echo "ERROR: Unable to determine active blue-green slot." >&2
  exit 1
}

slot_port() {
  case "$1" in
    blue)
      echo "$BLUE_PORT"
      ;;
    green)
      echo "$GREEN_PORT"
      ;;
    *)
      echo "ERROR: Invalid slot: $1" >&2
      exit 1
      ;;
  esac
}

write_upstream_file() {
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

validate_slot() {
  local port="$1"

  "$SCRIPT_DIR/healthcheck.sh" "http://127.0.0.1:${port}${HEALTH_PATH}"
}

restore_upstream() {
  local backup="$1"

  if [[ -f "$backup" ]]; then
    sudo cp "$backup" "$NGINX_ACTIVE_UPSTREAM"
  else
    sudo rm -f "$NGINX_ACTIVE_UPSTREAM"
  fi

  sudo "$NGINX_BIN" -t
  sudo "$NGINX_BIN" -s reload
}

if [[ ! "$DEPLOY_LOCK_TIMEOUT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: DEPLOY_LOCK_TIMEOUT must be a non-negative integer."
  exit 2
fi

for required_command in flock unzip grep mktemp; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: $required_command"
    exit 2
  fi
done

if [[ ! -f "$BUILD_ARCHIVE" ]]; then
  echo "ERROR: Build archive not found: $BUILD_ARCHIVE"
  exit 1
fi

acquire_lock

ACTIVE_SLOT="$(detect_active_slot)"

if [[ "$ACTIVE_SLOT" == "blue" ]]; then
  TARGET_SLOT="green"
else
  TARGET_SLOT="blue"
fi

ACTIVE_PORT="$(slot_port "$ACTIVE_SLOT")"
TARGET_PORT="$(slot_port "$TARGET_SLOT")"

TARGET_ROOT="$APP_DIR/$TARGET_SLOT"
TARGET_RELEASES="$TARGET_ROOT/releases"
TARGET_RELEASE="$TARGET_RELEASES/$TIMESTAMP"
TARGET_CURRENT="$TARGET_ROOT/current"

mkdir -p "$TARGET_RELEASES"

emit_deployment_event "blue_green_deploy" "started" "$TARGET_RELEASE" "" "$TARGET_SLOT" "$ACTIVE_SLOT" "Blue-green deployment started."`n`necho "Active slot: $ACTIVE_SLOT"
echo "Active port: $ACTIVE_PORT"
echo "Target slot: $TARGET_SLOT"
echo "Target port: $TARGET_PORT"
echo "Target release: $TARGET_RELEASE"

mkdir -p "$TARGET_RELEASE"

if ! unzip -q "$BUILD_ARCHIVE" -d "$TARGET_RELEASE"; then
  echo "ERROR: Failed to extract deployment artifact."
  rm -rf -- "$TARGET_RELEASE"
  exit 1
fi

ln -sfn "$TARGET_RELEASE" "$TARGET_CURRENT"

echo "Restarting inactive slot: ${APP_NAME}@${TARGET_SLOT}.service"

if ! sudo "$SYSTEMCTL_BIN" restart "${APP_NAME}@${TARGET_SLOT}.service"; then
  echo "ERROR: Failed to start inactive slot."
  exit 1
fi

echo "Validating inactive slot through 127.0.0.1..."

if ! validate_slot "$TARGET_PORT"; then
  echo "ERROR: Inactive slot failed readiness validation."
  exit 1
fi

UPSTREAM_TMP="$(mktemp)"
UPSTREAM_BACKUP="$(mktemp)"

trap 'rm -f "$UPSTREAM_TMP" "$UPSTREAM_BACKUP"' EXIT

if [[ -f "$NGINX_ACTIVE_UPSTREAM" ]]; then
  cp "$NGINX_ACTIVE_UPSTREAM" "$UPSTREAM_BACKUP"
else
  rm -f "$UPSTREAM_BACKUP"
fi

write_upstream_file "$TARGET_SLOT" "$TARGET_PORT" "$UPSTREAM_TMP"

sudo cp "$UPSTREAM_TMP" "$NGINX_ACTIVE_UPSTREAM"

echo "Validating Nginx configuration..."

if ! sudo "$NGINX_BIN" -t; then
  echo "ERROR: Nginx validation failed. Restoring previous upstream."

  if [[ -f "$UPSTREAM_BACKUP" ]]; then
    sudo cp "$UPSTREAM_BACKUP" "$NGINX_ACTIVE_UPSTREAM"
  else
    sudo rm -f "$NGINX_ACTIVE_UPSTREAM"
  fi

  exit 1
fi

echo "Switching production traffic to $TARGET_SLOT..."

if ! sudo "$NGINX_BIN" -s reload; then
  echo "ERROR: Nginx reload failed. Restoring previous upstream."
  restore_upstream "$UPSTREAM_BACKUP"
  exit 1
fi

if [[ -n "$PUBLIC_URL" ]]; then
  echo "Validating public endpoint: $PUBLIC_URL"

  if ! "$SCRIPT_DIR/healthcheck.sh" "$PUBLIC_URL"; then
    echo "ERROR: Public validation failed. Rolling traffic back to $ACTIVE_SLOT."

    restore_upstream "$UPSTREAM_BACKUP"

    emit_deployment_event "blue_green_traffic_rollback" "success" "" "" "$ACTIVE_SLOT" "$TARGET_SLOT" "Traffic restored after public validation failure."`n    echo "Traffic rollback completed."
    exit 1
  fi
fi

echo
emit_deployment_event "blue_green_deploy" "success" "$TARGET_RELEASE" "" "$TARGET_SLOT" "$ACTIVE_SLOT" "Traffic switched successfully."`n`necho "Blue-green deployment completed successfully."
echo "Previous slot: $ACTIVE_SLOT"
echo "Active slot: $TARGET_SLOT"
echo "Active port: $TARGET_PORT"
echo "Release: $TARGET_RELEASE"