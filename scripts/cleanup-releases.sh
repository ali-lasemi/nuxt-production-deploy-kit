#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${APP_DIR:-/opt/nuxt-app}"
RELEASES_DIR="$APP_DIR/releases"
KEEP_RELEASES="${KEEP_RELEASES:-5}"

if [[ ! -d "$RELEASES_DIR" ]]; then
  echo "Releases directory not found: $RELEASES_DIR"
  exit 0
fi

mapfile -t releases < <(
  find "$RELEASES_DIR" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -printf '%T@ %p\n' |
    sort -rn |
    cut -d' ' -f2-
)

release_count="${#releases[@]}"

if (( release_count <= KEEP_RELEASES )); then
  echo "No cleanup required. Releases=$release_count Keep=$KEEP_RELEASES"
  exit 0
fi

echo "Cleaning old releases..."

for ((i=KEEP_RELEASES; i<release_count; i++)); do
  release="${releases[$i]}"
  echo "Removing: $release"
  rm -rf -- "$release"
done

echo "Release cleanup completed."
