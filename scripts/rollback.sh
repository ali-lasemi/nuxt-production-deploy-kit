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

PREVIOUS_RELEASE="$(ls -dt "$RELEASES_DIR"/* 2>/dev/null | grep -v "$CURRENT_RELEASE" | head -n 1 || true)"

if [[ -z "$PREVIOUS_RELEASE" ]]; then
  echo "No previous release found."
  exit 1
fi

echo "Current release: $CURRENT_RELEASE"
echo "Rolling back to: $PREVIOUS_RELEASE"

ln -sfn "$PREVIOUS_RELEASE" "$CURRENT_LINK"

sudo systemctl restart "$SERVICE_NAME"

echo "Running rollback healthcheck..."
curl -f "$HEALTHCHECK_URL"

echo "Rollback completed successfully."