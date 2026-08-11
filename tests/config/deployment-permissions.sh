#!/usr/bin/env bash
set -Eeuo pipefail

SUDOERS_FILE="${1:-examples/sudoers/nuxt-app-deploy}"
BOOTSTRAP_FILE="${2:-scripts/bootstrap-host.sh}"
UNIT_FILE="${3:-examples/systemd/nuxt-app.service}"

fail() {
  echo "ERROR: $1"
  exit 1
}

require_text() {
  local file="$1"
  local expected="$2"

  if ! grep -Fq "$expected" "$file"; then
    fail "Missing expected policy in $file: $expected"
  fi
}

[[ -f "$SUDOERS_FILE" ]] || fail "Missing sudoers example"
[[ -f "$BOOTSTRAP_FILE" ]] || fail "Missing host bootstrap script"
[[ -f "$UNIT_FILE" ]] || fail "Missing systemd service example"

require_text "$SUDOERS_FILE" "deploy ALL=(root) NOPASSWD: NUXT_APP_SERVICE"
require_text "$SUDOERS_FILE" "/usr/bin/systemctl restart nuxt-app.service"
require_text "$SUDOERS_FILE" "/usr/bin/systemctl restart nuxt-app"

if grep -Eq 'NOPASSWD:[[:space:]]*ALL' "$SUDOERS_FILE"; then
  fail "sudoers policy must never grant NOPASSWD: ALL"
fi

if grep -Eq '/bin/(ba)?sh|/usr/bin/(ba)?sh' "$SUDOERS_FILE"; then
  fail "sudoers policy must not grant a shell"
fi

require_text "$BOOTSTRAP_FILE" 'DEPLOY_USER="${DEPLOY_USER:-deploy}"'
require_text "$BOOTSTRAP_FILE" 'DEPLOY_GROUP="${DEPLOY_GROUP:-deploy}"'
require_text "$BOOTSTRAP_FILE" 'chmod 0640 "$APP_DIR/.deployment.lock"'
require_text "$BOOTSTRAP_FILE" '-m 0750'
require_text "$BOOTSTRAP_FILE" '-exec chmod 0750 {} +'
require_text "$BOOTSTRAP_FILE" '-exec chmod 0640 {} +'

require_text "$UNIT_FILE" "User=deploy"
require_text "$UNIT_FILE" "Group=deploy"
require_text "$UNIT_FILE" "UMask=0027"

echo "Deployment identity and filesystem policy validated."