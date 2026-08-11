#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf -- "$TEST_ROOT"
}

trap cleanup EXIT

APP_DIR="$TEST_ROOT/app"
BIN_DIR="$TEST_ROOT/bin"
NGINX_ACTIVE_UPSTREAM="$TEST_ROOT/nuxt-active-upstream.conf"
LOCK_FILE="$APP_DIR/.deployment.lock"
BUILD_DIR="$TEST_ROOT/build"
BUILD_ARCHIVE="$TEST_ROOT/build.zip"
SYSTEMCTL_LOG="$TEST_ROOT/systemctl.log"
NGINX_LOG="$TEST_ROOT/nginx.log"
AUDIT_LOG="$TEST_ROOT/deployments.jsonl"

mkdir -p "$APP_DIR/blue/releases"
mkdir -p "$APP_DIR/green/releases"
mkdir -p "$BIN_DIR"
mkdir -p "$BUILD_DIR/.output/server"

INITIAL_BLUE_RELEASE="$APP_DIR/blue/releases/initial"
mkdir -p "$INITIAL_BLUE_RELEASE/.output/server"
printf 'initial-blue\n' >"$INITIAL_BLUE_RELEASE/.output/server/index.mjs"
ln -sfn "$INITIAL_BLUE_RELEASE" "$APP_DIR/blue/current"

printf 'fixture\n' >"$BUILD_DIR/.output/server/index.mjs"

(
  cd "$BUILD_DIR"
  zip -qr "$BUILD_ARCHIVE" .output
)

cat >"$NGINX_ACTIVE_UPSTREAM" <<'EOF'
upstream nuxt_active {
    server 127.0.0.1:3001;
    keepalive 32;
}
# slot=blue
EOF

cat >"$BIN_DIR/sudo" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
exec "$@"
EOF

cat >"$BIN_DIR/systemctl" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '%s\n' "$*" >>"$SYSTEMCTL_LOG"
exit 0
EOF

cat >"$BIN_DIR/nginx" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '%s\n' "$*" >>"$NGINX_LOG"
exit 0
EOF

cat >"$BIN_DIR/curl" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '200'
EOF

chmod +x "$BIN_DIR/sudo"
chmod +x "$BIN_DIR/systemctl"
chmod +x "$BIN_DIR/nginx"
chmod +x "$BIN_DIR/curl"

export PATH="$BIN_DIR:$PATH"
export APP_DIR
export APP_NAME="nuxt-app"
export BLUE_PORT="3001"
export GREEN_PORT="3002"
export HEALTH_PATH="/"
export PUBLIC_URL=""
export NGINX_ACTIVE_UPSTREAM
export NGINX_BIN="nginx"
export SYSTEMCTL_BIN="systemctl"
export DEPLOY_LOCK_FILE="$LOCK_FILE"
export DEPLOY_LOCK_TIMEOUT="1"
export HEALTH_RETRIES="1"
export HEALTH_RETRY_DELAY="0"
export TIMEOUT_SECONDS="1"
export SYSTEMCTL_LOG
export NGINX_LOG
export AUDIT_LOG

"$ROOT_DIR/scripts/blue-green-deploy.sh" "$BUILD_ARCHIVE"

grep -Fq "127.0.0.1:3002" "$NGINX_ACTIVE_UPSTREAM"
grep -Fq "restart nuxt-app@green.service" "$SYSTEMCTL_LOG"
grep -Fq -- "-t" "$NGINX_LOG"
grep -Fq -- "-s reload" "$NGINX_LOG"

[[ -L "$APP_DIR/green/current" ]]

"$ROOT_DIR/scripts/blue-green-rollback.sh"

grep -Fq "127.0.0.1:3001" "$NGINX_ACTIVE_UPSTREAM"

echo "Blue-green integration test passed."