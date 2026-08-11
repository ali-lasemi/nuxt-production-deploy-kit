#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

APP_NAME="${APP_NAME:-${SERVICE_NAME:-nuxt-app}}"
APP_DIR="${APP_DIR:-/opt/nuxt-app}"
APP_PORT="${APP_PORT:-3000}"
HEALTH_PATH="${HEALTH_PATH:-/}"
PUBLIC_URL="${PUBLIC_URL:-}"

RELEASES_DIR="$APP_DIR/releases"
CURRENT_LINK="$APP_DIR/current"

DEPLOY_LOCK_FILE="${DEPLOY_LOCK_FILE:-$APP_DIR/.deployment.lock}"
DEPLOY_LOCK_TIMEOUT="${DEPLOY_LOCK_TIMEOUT:-30}"

validate_runtime() {
  APP_NAME="$APP_NAME" \
  APP_PORT="$APP_PORT" \
  HEALTH_PATH="$HEALTH_PATH" \
  PUBLIC_URL="$PUBLIC_URL" \
  "$SCRIPT_DIR/validate-deployment.sh"
}

acquire_deployment_lock() {
  mkdir -p "$(dirname "$DEPLOY_LOCK_FILE")"

  exec {DEPLOY_LOCK_FD}>"$DEPLOY_LOCK_FILE"

  echo "Acquiring deployment lock: $DEPLOY_LOCK_FILE"

  if ! flock -w "$DEPLOY_LOCK_TIMEOUT" "$DEPLOY_LOCK_FD"; then
    echo "ERROR: Could not acquire deployment lock within ${DEPLOY_LOCK_TIMEOUT}s."
    echo "Another deployment or rollback operation may already be running."
    exit 3
  fi

  echo "Deployment lock acquired."
}

restore_original_release() {
  if [[ -z "$CURRENT_RELEASE" || ! -d "$CURRENT_RELEASE" ]]; then
    echo "ERROR: Original release cannot be restored."
    return 1
  fi

  echo "Restoring original release: $CURRENT_RELEASE"

  ln -sfn "$CURRENT_RELEASE" "$CURRENT_LINK"

  if ! sudo systemctl restart "$APP_NAME"; then
    echo "ERROR: Failed to restart service while restoring original release."
    return 1
  fi

  if ! validate_runtime; then
    echo "ERROR: Original release failed validation after restoration."
    return 1
  fi

  echo "Original release restored successfully."

  return 0
}

if [[ ! "$DEPLOY_LOCK_TIMEOUT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: DEPLOY_LOCK_TIMEOUT must be a non-negative integer."
  exit 2
fi

if ! command -v flock >/dev/null 2>&1; then
  echo "ERROR: flock is required but was not found."
  exit 2
fi

if [[ ! -d "$RELEASES_DIR" ]]; then
  echo "ERROR: Releases directory not found: $RELEASES_DIR"
  exit 1
fi

acquire_deployment_lock

CURRENT_RELEASE="$(readlink -f "$CURRENT_LINK" 2>/dev/null || true)"
ROLLBACK_TARGET="${1:-}"

if [[ -n "$ROLLBACK_TARGET" ]]; then
  if [[ "$ROLLBACK_TARGET" != /* ]]; then
    ROLLBACK_TARGET="$RELEASES_DIR/$ROLLBACK_TARGET"
  fi

  ROLLBACK_TARGET="$(readlink -f "$ROLLBACK_TARGET" 2>/dev/null || true)"

  if [[ -z "$ROLLBACK_TARGET" || ! -d "$ROLLBACK_TARGET" ]]; then
    echo "ERROR: Requested rollback target does not exist."
    exit 1
  fi

  if [[ "$ROLLBACK_TARGET" == "$CURRENT_RELEASE" ]]; then
    echo "ERROR: Requested rollback target is already active."
    exit 1
  fi
else
  mapfile -t releases < <(
    find "$RELEASES_DIR" \
      -mindepth 1 \
      -maxdepth 1 \
      -type d \
      -printf '%T@ %p\n' |
      sort -rn |
      cut -d' ' -f2-
  )

  ROLLBACK_TARGET=""

  for release in "${releases[@]}"; do
    if [[ "$release" != "$CURRENT_RELEASE" ]]; then
      ROLLBACK_TARGET="$release"
      break
    fi
  done
fi

if [[ -z "$ROLLBACK_TARGET" ]]; then
  echo "ERROR: No previous release found."
  exit 1
fi

echo "Current release: ${CURRENT_RELEASE:-unknown}"
echo "Rollback target: $ROLLBACK_TARGET"

ln -sfn "$ROLLBACK_TARGET" "$CURRENT_LINK"

echo "Restarting systemd service: $APP_NAME"

if ! sudo systemctl restart "$APP_NAME"; then
  echo "ERROR: Service restart failed during rollback."

  if ! restore_original_release; then
    echo "CRITICAL: Rollback failed and original release recovery also failed."
    exit 2
  fi

  exit 1
fi

echo "Validating rollback target..."

if ! validate_runtime; then
  echo "ERROR: Rollback target failed validation."

  if ! restore_original_release; then
    echo "CRITICAL: Rollback validation failed and original release recovery also failed."
    exit 2
  fi

  exit 1
fi

echo
echo "Rollback completed successfully."
echo "Active release: $ROLLBACK_TARGET"