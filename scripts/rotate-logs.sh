#!/usr/bin/env bash
set -Eeuo pipefail

LOGROTATE_CONFIG="/etc/logrotate.d/nuxt-app"

if [[ ! -f "$LOGROTATE_CONFIG" ]]; then
  echo "Logrotate config not found: $LOGROTATE_CONFIG"
  exit 1
fi

sudo logrotate -f "$LOGROTATE_CONFIG"
echo "Log rotation completed."