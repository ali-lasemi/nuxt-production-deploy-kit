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

if [[ ! -f "$BUILD_ARCHIVE" ]]; then
  echo "ERROR: Build archive not found: $BUILD_ARCHIVE"
  exit 1
fi

echo "Creating release directory: $NEW_RELEASE"
mkdir -p "$NEW_RELEASE"

echo "Extracting build archive..."
unzip -q "$BUILD_ARCHIVE" -d "$NEW_RELEASE"

echo "Switching current release..."
ln -sfn "$NEW_RELEASE" "$CURRENT_LINK"

echo "Restarting systemd service: $APP_NAME"
sudo systemctl restart "$APP_NAME"

echo "Running post-deployment validation..."

APP_NAME="$APP_NAME" \
APP_PORT="$APP_PORT" \
HEALTH_PATH="$HEALTH_PATH" \
PUBLIC_URL="$PUBLIC_URL" \
"$SCRIPT_DIR/validate-deployment.sh"

echo
echo "Deployment completed successfully."
echo "Release: $NEW_RELEASE"
