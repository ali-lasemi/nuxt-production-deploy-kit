#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=deployment-events.sh
source "$SCRIPT_DIR/deployment-events.sh"

APP_NAME="${APP_NAME:-nuxt-app}"
APP_DIR="${APP_DIR:-/opt/nuxt-app}"
APP_PORT="${APP_PORT:-3000}"
HEALTH_PATH="${HEALTH_PATH:-/}"
PUBLIC_URL="${PUBLIC_URL:-}"

RELEASES_DIR="$APP_DIR/releases"
CURRENT_LINK="$APP_DIR/current"

DEPLOY_LOCK_FILE="${DEPLOY_LOCK_FILE:-$APP_DIR/.deployment.lock}"
DEPLOY_LOCK_TIMEOUT="${DEPLOY_LOCK_TIMEOUT:-30}"

TIMESTAMP="$(date -u +%Y%m%d%H%M%S)"
NEW_RELEASE="$RELEASES_DIR/$TIMESTAMP"
BUILD_ARCHIVE="${1:-build.zip}"
METADATA_FILE="$NEW_RELEASE/release-metadata.json"

PREVIOUS_RELEASE="$(readlink -f "$CURRENT_LINK" 2>/dev/null || true)"
SOURCE_COMMIT="${SOURCE_COMMIT:-unknown}"
DEPLOYED_BY="${DEPLOYED_BY:-$(id -un 2>/dev/null || printf 'unknown')}"

validate_runtime() {
  APP_NAME="$APP_NAME" \
  APP_PORT="$APP_PORT" \
  HEALTH_PATH="$HEALTH_PATH" \
  PUBLIC_URL="$PUBLIC_URL" \
  "$SCRIPT_DIR/validate-deployment.sh"
}

metadata_create() {
  node "$SCRIPT_DIR/release-metadata.mjs" create "$METADATA_FILE" \
    "release_id=$TIMESTAMP" \
    "application=$APP_NAME" \
    "source_commit=$SOURCE_COMMIT" \
    "artifact=$(basename -- "$BUILD_ARCHIVE")" \
    "artifact_sha256=$ARTIFACT_SHA256" \
    "deployed_by=$DEPLOYED_BY" \
    "previous_release=$PREVIOUS_RELEASE_NAME" \
    "status=preparing" \
    "validation=pending" \
    "rollback=not_required"
}

metadata_update() {
  node "$SCRIPT_DIR/release-metadata.mjs" update "$METADATA_FILE" "$@"
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

rollback_failed_deployment() {
  echo
  echo "Deployment failed. Starting automatic rollback."

  if [[ -z "$PREVIOUS_RELEASE" || ! -d "$PREVIOUS_RELEASE" ]]; then
    echo "ERROR: No valid previous release is available for automatic rollback."
    metadata_update "status=failed" "validation=failed" "rollback=unavailable"
    return 1
  fi

  echo "Failed release: $NEW_RELEASE"
  echo "Rollback target: $PREVIOUS_RELEASE"

  metadata_update "status=failed" "rollback=pending"

  ln -sfn "$PREVIOUS_RELEASE" "$CURRENT_LINK"

  if ! sudo systemctl restart "$APP_NAME"; then
    echo "ERROR: Failed to restart '$APP_NAME' during automatic rollback."
    metadata_update "rollback=failed"
    return 1
  fi

  echo "Validating rollback target..."

  if ! validate_runtime; then
    echo "ERROR: Automatic rollback target failed validation."
    metadata_update "rollback=failed"
    return 1
  fi

  metadata_update "rollback=successful"

  echo
  emit_deployment_event "automatic_rollback" "success" "$PREVIOUS_RELEASE" "$NEW_RELEASE" "" "" "Previous release restored after failed deployment."`n  echo "Automatic rollback completed successfully."
  echo "Active release: $PREVIOUS_RELEASE"

  return 0
}

if [[ ! "$DEPLOY_LOCK_TIMEOUT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: DEPLOY_LOCK_TIMEOUT must be a non-negative integer."
  exit 2
fi

for required_command in flock sha256sum unzip node; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: $required_command"
    exit 2
  fi
done

if [[ ! -f "$BUILD_ARCHIVE" ]]; then
  echo "ERROR: Build archive not found: $BUILD_ARCHIVE"
  exit 1
fi

mkdir -p "$RELEASES_DIR"

acquire_deployment_lock

ARTIFACT_SHA256="$(sha256sum "$BUILD_ARCHIVE" | awk '{print $1}')"

PREVIOUS_RELEASE_NAME=""

if [[ -n "$PREVIOUS_RELEASE" ]]; then
  PREVIOUS_RELEASE_NAME="$(basename -- "$PREVIOUS_RELEASE")"
fi

emit_deployment_event "deploy" "started" "$NEW_RELEASE" "$PREVIOUS_RELEASE" "" "" "Deployment started."`n`necho "Creating release directory: $NEW_RELEASE"
mkdir -p "$NEW_RELEASE"

metadata_create

echo "Extracting build archive..."

if ! unzip -q "$BUILD_ARCHIVE" -d "$NEW_RELEASE"; then
  echo "ERROR: Failed to extract build archive."
  metadata_update "status=failed" "validation=not_started"
  exit 1
fi

metadata_update "status=prepared"

echo "Switching current release..."
ln -sfn "$NEW_RELEASE" "$CURRENT_LINK"

metadata_update "status=activating"

echo "Restarting systemd service: $APP_NAME"

if ! sudo systemctl restart "$APP_NAME"; then
  echo "ERROR: Service restart failed."

  metadata_update "status=failed" "validation=not_started"

  if rollback_failed_deployment; then
    exit 1
  fi

  emit_deployment_event "deploy" "critical_failure" "$NEW_RELEASE" "$PREVIOUS_RELEASE" "" "" "Deployment and automatic rollback failed."`n  echo "CRITICAL: Deployment failed and automatic rollback did not recover the service."
  exit 2
fi

echo "Running post-deployment validation..."

if ! validate_runtime; then
  metadata_update "status=failed" "validation=failed"

  if rollback_failed_deployment; then
    exit 1
  fi

  emit_deployment_event "deploy" "critical_failure" "$NEW_RELEASE" "$PREVIOUS_RELEASE" "" "" "Deployment and automatic rollback failed."`n  echo "CRITICAL: Deployment failed and automatic rollback did not recover the service."
  exit 2
fi

metadata_update "status=active" "validation=passed" "rollback=not_required"

node "$SCRIPT_DIR/release-metadata.mjs" verify "$METADATA_FILE"

echo
emit_deployment_event "deploy" "success" "$NEW_RELEASE" "$PREVIOUS_RELEASE" "" "" "Deployment completed successfully."`n`necho "Deployment completed successfully."
echo "Release: $NEW_RELEASE"
echo "Metadata: $METADATA_FILE"