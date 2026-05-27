#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/opt/nuxt-app"
RELEASES_DIR="$APP_DIR/releases"
CURRENT_LINK="$APP_DIR/current"

PREVIOUS_RELEASE="$(ls -dt $RELEASES_DIR/* | sed -n '2p')"

if [[ -z "$PREVIOUS_RELEASE" ]]; then
  echo "No previous release found."
  exit 1
fi

echo "Rolling back to: $PREVIOUS_RELEASE"

ln -sfn "$PREVIOUS_RELEASE" "$CURRENT_LINK"

sudo systemctl restart nuxt-app

echo "Rollback completed."