#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${APP_DIR:-/opt/nuxt-app}"
RELEASES_DIR="$APP_DIR/releases"
CURRENT_LINK="$APP_DIR/current"
SERVICE_NAME="${SERVICE_NAME:-nuxt-app}"
HEALTHCHECK_URL="${HEALTHCHECK_URL:-http://127.0.0.1:3000}"

if [[ ! -d "$RELEASES_DIR" ]]; then
  echo "Releases directory not found: $RELEASES_DIR"
  exit 1
fi

CURRENT_RELEASE="$(readlink -f "$CURRENT_LINK" || true)"
PREVIOUS_RELEASE=""

mapfile -t releases < <(
  find "$RELEASES_DIR" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -printf '%T@ %p\n' |
    sort -rn |
    cut -d' ' -f2-
)

for release in "${releases[@]}"; do
  if [[ "$release" != "$CURRENT_RELEASE" ]]; then
    PREVIOUS_RELEASE="$release"
    break
  fi
done

if [[ -z "$PREVIOUS_RELEASE" ]]; then
  echo "No previous release found."
  exit 1
fi

echo "Current release: ${CURRENT_RELEASE:-unknown}"
echo "Rolling back to: $PREVIOUS_RELEASE"

ln -sfn "$PREVIOUS_RELEASE" "$CURRENT_LINK"

sudo systemctl restart "$SERVICE_NAME"

echo "Running rollback healthcheck..."
"$APP_DIR/current/../scripts/healthcheck.sh" "$HEALTHCHECK_URL" 2>/dev/null || curl -f "$HEALTHCHECK_URL"

echo "Rollback completed successfully."
