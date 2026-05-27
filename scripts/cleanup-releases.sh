#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${APP_DIR:-/opt/nuxt-app}"
RELEASES_DIR="$APP_DIR/releases"
KEEP_RELEASES="${KEEP_RELEASES:-5}"

if [[ ! -d "$RELEASES_DIR" ]]; then
  echo "Releases directory not found: $RELEASES_DIR"
  exit 1
fi

echo "Keeping latest $KEEP_RELEASES releases..."

ls -dt "$RELEASES_DIR"/* 2>/dev/null | tail -n +"$((KEEP_RELEASES + 1))" | while read -r release; do
  echo "Removing old release: $release"
  rm -rf "$release"
done

echo "Release cleanup completed."