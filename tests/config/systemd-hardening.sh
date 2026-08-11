#!/usr/bin/env bash
set -Eeuo pipefail

UNIT_FILE="${1:-examples/systemd/nuxt-app.service}"

fail() {
  echo "ERROR: $1"
  exit 1
}

require_directive() {
  local directive="$1"

  if ! grep -Fqx "$directive" "$UNIT_FILE"; then
    fail "Required systemd hardening directive missing: $directive"
  fi
}

[[ -f "$UNIT_FILE" ]] || fail "Unit file not found: $UNIT_FILE"

require_directive "User=deploy"
require_directive "Group=deploy"
require_directive "UMask=0027"
require_directive "WorkingDirectory=/opt/nuxt-app/current"
require_directive "Environment=HOST=127.0.0.1"
require_directive "Restart=on-failure"
require_directive "NoNewPrivileges=yes"
require_directive "PrivateTmp=yes"
require_directive "PrivateDevices=yes"
require_directive "ProtectSystem=strict"
require_directive "ProtectHome=yes"
require_directive "ProtectKernelTunables=yes"
require_directive "ProtectKernelModules=yes"
require_directive "ProtectKernelLogs=yes"
require_directive "ProtectControlGroups=yes"
require_directive "ProtectClock=yes"
require_directive "ProtectHostname=yes"
require_directive "RestrictSUIDSGID=yes"
require_directive "RestrictRealtime=yes"
require_directive "LockPersonality=yes"
require_directive "RestrictNamespaces=yes"
require_directive "RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6"
require_directive "SystemCallArchitectures=native"
require_directive "CapabilityBoundingSet="
require_directive "AmbientCapabilities="
require_directive "ReadWritePaths=/var/log/nuxt-app"

if grep -Fqx "Restart=always" "$UNIT_FILE"; then
  fail "Restart=always is not allowed in the hardened unit"
fi

echo "systemd hardening policy validated."