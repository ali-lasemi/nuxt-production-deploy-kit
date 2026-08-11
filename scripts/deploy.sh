#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

APP_NAME="${APP_NAME:-nuxt-app}"
APP_DIR="${APP_DIR:-/opt/nuxt-app}"
APP_PORT="${APP_PORT:-3000}"
HEALTH_PATH="${HEALTH_PATH:-/}"
PUBLIC_URL="${PUBLIC_URL:-}"

RELEASES_DIR="$APP_DIR/releases"
CURRENT_LINK="$APP_DIR/current"

TIMESTAMP="$(date +%Y%m%d%H%M%S)"
NEW_RELEASE="$RELEASES_DIR/$TIMESTAMP"
BUILD_ARCHIVE="${1:-build.zip}"

PREVIOUS_RELEASE="$(readlink -f "$CURRENT_LINK" 2>/dev/null || true)"

validate_runtime() {
  APP_NAME="$APP_NAME" \
  APP_PORT="$APP_PORT" \
  HEALTH_PATH="$HEALTH_PATH" \
  PUBLIC_URL="$PUBLIC_URL" \
  "$SCRIPT_DIR/validate-deployment.sh"
}

rollback_failed_deployment() {
  echo
  echo "Deployment validation failed."

  if [[ -z "$PREVIOUS_RELEASE" || ! -d "$PREVIOUS_RELEASE" ]]; then
    echo "ERROR: No valid previous release is available for automatic rollback."
    return 1
  fi

  echo "Starting automatic rollback..."
  echo "Failed release: $NEW_RELEASE"
  echo "Rollback target: $PREVIOUS_RELEASE"

  ln -sfn "$PREVIOUS_RELEASE" "$CURRENT_LINK"

  if ! sudo systemctl restart "$APP_NAME"; then
    echo "ERROR: Failed to restart '$APP_NAME' during rollback."
    return 1
  fi

  echo "Validating rollback target..."

  if ! validate_runtime; then
    echo "ERROR: Rollback target failed validation."
    return 1
  fi

  echo
  echo "Automatic rollback completed successfully."
  echo "Active release: $PREVIOUS_RELEASE"
  return 0
}

if [[ ! -f "$BUILD_ARCHIVE" ]]; then
  echo "ERROR: Build archive not found: $BUILD_ARCHIVE"
  exit 1
fi

mkdir -p "$RELEASES_DIR"

echo "Creating release directory: $NEW_RELEASE"
mkdir -p "$NEW_RELEASE"

echo "Extracting build archive..."
if ! unzip -q "$BUILD_ARCHIVE" -d "$NEW_RELEASE"; then
  echo "ERROR: Failed to extract build archive."
  rm -rf -- "$NEW_RELEASE"
  exit 1
fi

echo "Switching current release..."
ln -sfn "$NEW_RELEASE" "$CURRENT_LINK"

echo "Restarting systemd service: $APP_NAME"
if ! sudo systemctl restart "$APP_NAME"; then
  echo "ERROR: Service restart failed."

  if rollback_failed_deployment; then
    exit 1
  fi

  echo "CRITICAL: Deployment failed and automatic rollback did not recover the service."
  exit 2
fi

echo "Running post-deployment validation..."

if ! validate_runtime; then
  if rollback_failed_deployment; then
    exit 1
  fi

  echo "CRITICAL: Deployment failed and automatic rollback did not recover the service."
  exit 2
fi

echo
echo "Deployment completed successfully."
echo "Release: $NEW_RELEASE"
