#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="${APP_NAME:-nuxt-app}"
DEPLOY_USER="${DEPLOY_USER:-deploy}"
DEPLOY_GROUP="${DEPLOY_GROUP:-deploy}"
APP_DIR="${APP_DIR:-/opt/nuxt-app}"
LOG_DIR="${LOG_DIR:-/var/log/nuxt-app}"
CONFIG_DIR="${CONFIG_DIR:-/etc/nuxt-app}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "ERROR: bootstrap-host.sh must run as root."
  exit 1
fi

if ! getent group "$DEPLOY_GROUP" >/dev/null 2>&1; then
  groupadd --system "$DEPLOY_GROUP"
fi

if ! id "$DEPLOY_USER" >/dev/null 2>&1; then
  useradd \
    --system \
    --gid "$DEPLOY_GROUP" \
    --home-dir "$APP_DIR" \
    --shell /usr/sbin/nologin \
    "$DEPLOY_USER"
fi

install -d \
  -o "$DEPLOY_USER" \
  -g "$DEPLOY_GROUP" \
  -m 0750 \
  "$APP_DIR"

install -d \
  -o "$DEPLOY_USER" \
  -g "$DEPLOY_GROUP" \
  -m 0750 \
  "$APP_DIR/releases"

install -d \
  -o "$DEPLOY_USER" \
  -g "$DEPLOY_GROUP" \
  -m 0750 \
  "$LOG_DIR"

install -d \
  -o root \
  -g "$DEPLOY_GROUP" \
  -m 0750 \
  "$CONFIG_DIR"

if [[ ! -e "$APP_DIR/.deployment.lock" ]]; then
  install \
    -o "$DEPLOY_USER" \
    -g "$DEPLOY_GROUP" \
    -m 0640 \
    /dev/null \
    "$APP_DIR/.deployment.lock"
else
  chown "$DEPLOY_USER:$DEPLOY_GROUP" "$APP_DIR/.deployment.lock"
  chmod 0640 "$APP_DIR/.deployment.lock"
fi

find "$APP_DIR/releases" \
  -mindepth 1 \
  -type d \
  -exec chmod 0750 {} +

find "$APP_DIR/releases" \
  -mindepth 1 \
  -type f \
  -exec chmod 0640 {} +

chown -R "$DEPLOY_USER:$DEPLOY_GROUP" "$APP_DIR/releases"
chown -R "$DEPLOY_USER:$DEPLOY_GROUP" "$LOG_DIR"

echo "Host deployment permissions configured."
echo "Application: $APP_NAME"
echo "Deployment user: $DEPLOY_USER"
echo "Deployment group: $DEPLOY_GROUP"
echo "Application directory: $APP_DIR"
echo "Log directory: $LOG_DIR"
echo "Configuration directory: $CONFIG_DIR"