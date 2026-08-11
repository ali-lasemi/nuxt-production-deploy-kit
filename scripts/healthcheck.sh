#!/usr/bin/env bash
set -Eeuo pipefail

URL="${1:-http://127.0.0.1:3000/}"
EXPECTED_STATUS="${EXPECTED_STATUS:-200}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-10}"
HEALTH_RETRIES="${HEALTH_RETRIES:-5}"
HEALTH_RETRY_DELAY="${HEALTH_RETRY_DELAY:-2}"

if (( HEALTH_RETRIES < 1 )); then
  echo "ERROR: HEALTH_RETRIES must be at least 1."
  exit 2
fi

for ((attempt=1; attempt<=HEALTH_RETRIES; attempt++)); do
  status_code="$(
    curl \
      --silent \
      --show-error \
      --output /dev/null \
      --write-out "%{http_code}" \
      --max-time "$TIMEOUT_SECONDS" \
      "$URL" 2>/dev/null || true
  )"

  if [[ "$status_code" == "$EXPECTED_STATUS" ]]; then
    echo "PASS: $URL returned HTTP $status_code ($attempt/$HEALTH_RETRIES)"
    exit 0
  fi

  echo "WARN: $URL expected HTTP $EXPECTED_STATUS, got ${status_code:-connection-error} ($attempt/$HEALTH_RETRIES)"

  if (( attempt < HEALTH_RETRIES )); then
    sleep "$HEALTH_RETRY_DELAY"
  fi
done

echo "FAIL: Healthcheck failed after $HEALTH_RETRIES attempts: $URL"
exit 1
