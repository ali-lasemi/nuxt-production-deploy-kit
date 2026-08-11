#!/usr/bin/env bash
set -Eeuo pipefail

GITIGNORE_FILE="${1:-.gitignore}"
UNIT_FILE="${2:-examples/systemd/nuxt-app.service}"
ENV_EXAMPLE="${3:-examples/env/.env.production.example}"
SECRET_DOC="${4:-docs/secret-management.md}"

fail() {
  echo "ERROR: $1"
  exit 1
}

require_text() {
  local file="$1"
  local expected="$2"

  if ! grep -Fq -- "$expected" "$file"; then
    fail "Missing expected policy in $file: $expected"
  fi
}

require_text "$GITIGNORE_FILE" ".env"
require_text "$GITIGNORE_FILE" ".env.*"
require_text "$UNIT_FILE" "EnvironmentFile=-/etc/nuxt-app/nuxt-app.env"
require_text "$SECRET_DOC" "/etc/nuxt-app/nuxt-app.env"
require_text "$SECRET_DOC" "0640"
require_text "$SECRET_DOC" "root:deploy"

if grep -Eq '^[[:space:]]*(PASSWORD|TOKEN|SECRET|API_KEY|PRIVATE_KEY)=[^[:space:]]+' "$ENV_EXAMPLE"; then
  fail "Environment example must not contain real-looking secret values."
fi

if git ls-files | grep -E '(^|/)\.env($|\.)' | grep -v 'examples/env/.env.production.example' >/dev/null 2>&1; then
  fail "Tracked environment file detected outside the approved example."
fi

echo "Secret-management repository policy validated."