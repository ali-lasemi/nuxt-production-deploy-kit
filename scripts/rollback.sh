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

if [[ ! -d "$RELEASES_DIR" ]]; then
  echo "ERROR: Releases directory not found: $RELEASES_DIR"
  exit 1
fi

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

  if [[ -n "$CURRENT_RELEASE" && -d "$CURRENT_RELEASE" ]]; then
    echo "Restoring original release..."
    ln -sfn "$CURRENT_RELEASE" "$CURRENT_LINK"
    sudo systemctl restart "$APP_NAME" || true
  fi

  exit 1
fi

echo "Validating rollback target..."

if ! APP_NAME="$APP_NAME" \
  APP_PORT="$APP_PORT" \
  HEALTH_PATH="$HEALTH_PATH" \
  PUBLIC_URL="$PUBLIC_URL" \
  "$SCRIPT_DIR/validate-deployment.sh"; then

  echo "ERROR: Rollback target failed validation."

  if [[ -n "$CURRENT_RELEASE" && -d "$CURRENT_RELEASE" ]]; then
    echo "Restoring original release..."
    ln -sfn "$CURRENT_RELEASE" "$CURRENT_LINK"

    if sudo systemctl restart "$APP_NAME"; then
      APP_NAME="$APP_NAME" \
      APP_PORT="$APP_PORT" \
      HEALTH_PATH="$HEALTH_PATH" \
      PUBLIC_URL="$PUBLIC_URL" \
      "$SCRIPT_DIR/validate-deployment.sh" || true
    fi
  fi

  exit 1
fi

echo
echo "Rollback completed successfully."
echo "Active release: $ROLLBACK_TARGET"
