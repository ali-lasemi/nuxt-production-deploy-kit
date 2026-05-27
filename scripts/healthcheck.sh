#!/usr/bin/env bash
set -Eeuo pipefail

URL="${1:-http://127.0.0.1:3000}"
EXPECTED_STATUS="${EXPECTED_STATUS:-200}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-10}"

status_code="$(curl -sS -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT_SECONDS" "$URL")"

if [[ "$status_code" != "$EXPECTED_STATUS" ]]; then
  echo "Healthcheck failed. URL=$URL Expected=$EXPECTED_STATUS Got=$status_code"
  exit 1
fi

echo "Healthcheck passed. URL=$URL Status=$status_code"