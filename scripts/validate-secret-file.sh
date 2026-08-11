#!/usr/bin/env bash
set -Eeuo pipefail

SECRET_FILE="${1:-/etc/nuxt-app/nuxt-app.env}"
EXPECTED_OWNER="${EXPECTED_OWNER:-root}"
EXPECTED_GROUP="${EXPECTED_GROUP:-deploy}"
EXPECTED_MODE="${EXPECTED_MODE:-640}"

fail() {
  echo "ERROR: $1"
  exit 1
}

if [[ ! -f "$SECRET_FILE" ]]; then
  fail "Secret environment file not found: $SECRET_FILE"
fi

actual_owner="$(stat -c '%U' "$SECRET_FILE")"
actual_group="$(stat -c '%G' "$SECRET_FILE")"
actual_mode="$(stat -c '%a' "$SECRET_FILE")"

if [[ "$actual_owner" != "$EXPECTED_OWNER" ]]; then
  fail "Unexpected owner for $SECRET_FILE: $actual_owner"
fi

if [[ "$actual_group" != "$EXPECTED_GROUP" ]]; then
  fail "Unexpected group for $SECRET_FILE: $actual_group"
fi

if [[ "$actual_mode" != "$EXPECTED_MODE" ]]; then
  fail "Unexpected mode for $SECRET_FILE: $actual_mode"
fi

if grep -Eq '^[[:space:]]*(export[[:space:]]+)?[^#[:space:]][^=]*=[[:space:]]*$' "$SECRET_FILE"; then
  echo "WARN: Secret file contains one or more empty values."
fi

if grep -Eq '^[[:space:]]*(export[[:space:]]+)?(PASSWORD|TOKEN|SECRET|API_KEY|PRIVATE_KEY)=[[:space:]]*(changeme|example|password|secret|token)[[:space:]]*$' "$SECRET_FILE"; then
  fail "Secret file contains an obvious placeholder secret."
fi

echo "Secret file policy validated."
echo "File: $SECRET_FILE"
echo "Owner: $actual_owner"
echo "Group: $actual_group"
echo "Mode: $actual_mode"