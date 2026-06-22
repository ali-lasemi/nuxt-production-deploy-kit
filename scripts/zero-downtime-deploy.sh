#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${APP_DIR:-/opt/nuxt-app}"
RELEASES_DIR="$APP_DIR/releases"
CURRENT_LINK="$APP_DIR/current"
SERVICE_NAME="${SERVICE_NAME:-nuxt-app}"
HEALTHCHECK_URL="${HEALTHCHECK_URL:-http://127.0.0.1:3000}"
BUILD_ARCHIVE="${1:-build.zip}"

TIMESTAMP="$(date +%Y%m%d%H%M%S)"
NEW_RELEASE="$RELEASES_DIR/$TIMESTAMP"

if [[ ! -f "$BUILD_ARCHIVE" ]]; then
  echo "Build archive not found: $BUILD_ARCHIVE"
  exit 1
fi

mkdir -p "$NEW_RELEASE"

echo "Extracting release..."
unzip -q "$BUILD_ARCHIVE" -d "$NEW_RELEASE"

echo "Switching current symlink..."
ln -sfn "$NEW_RELEASE" "$CURRENT_LINK"

echo "Restarting service..."
sudo systemctl restart "$SERVICE_NAME"

echo "Running healthcheck..."
curl -f "$HEALTHCHECK_URL"

echo "Zero-downtime deployment completed successfully."