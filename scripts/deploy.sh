#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/opt/nuxt-app"
RELEASES_DIR="$APP_DIR/releases"
CURRENT_LINK="$APP_DIR/current"

TIMESTAMP="$(date +%Y%m%d%H%M%S)"
NEW_RELEASE="$RELEASES_DIR/$TIMESTAMP"

BUILD_ARCHIVE="${1:-build.zip}"

if [[ ! -f "$BUILD_ARCHIVE" ]]; then
  echo "Build archive not found: $BUILD_ARCHIVE"
  exit 1
fi

echo "Creating release directory..."
mkdir -p "$NEW_RELEASE"

echo "Extracting build..."
unzip -q "$BUILD_ARCHIVE" -d "$NEW_RELEASE"

echo "Updating current symlink..."
ln -sfn "$NEW_RELEASE" "$CURRENT_LINK"

echo "Restarting application..."
sudo systemctl restart nuxt-app

echo "Running healthcheck..."
./scripts/healthcheck.sh http://127.0.0.1:3000

echo "Deployment completed successfully."