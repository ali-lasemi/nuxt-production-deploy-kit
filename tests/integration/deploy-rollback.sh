#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf -- "$TEST_ROOT"
}

trap cleanup EXIT

APP_DIR="$TEST_ROOT/app"
FAKE_BIN="$TEST_ROOT/bin"
FIXTURES_DIR="$TEST_ROOT/fixtures"
SYSTEMCTL_LOG="$TEST_ROOT/systemctl.log"
FAIL_HEALTH_ONCE_FLAG="$TEST_ROOT/fail-health-once"
LOCK_FILE="$APP_DIR/.deployment.lock"

mkdir -p "$APP_DIR/releases" "$FAKE_BIN" "$FIXTURES_DIR"

export APP_DIR
export APP_NAME="nuxt-app"
export APP_PORT="3000"
export HEALTH_PATH="/"
export PUBLIC_URL=""
export EXPECTED_STATUS="200"
export TIMEOUT_SECONDS="1"
export HEALTH_RETRIES="1"
export HEALTH_RETRY_DELAY="0"
export DEPLOY_LOCK_FILE="$LOCK_FILE"
export DEPLOY_LOCK_TIMEOUT="1"
export SYSTEMCTL_LOG
export FAIL_HEALTH_ONCE_FLAG

fail() {
  echo "TEST FAILED: $1"
  exit 1
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$expected" != "$actual" ]]; then
    echo "Expected: $expected"
    echo "Actual:   $actual"
    fail "$message"
  fi
}

assert_file_exists() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    fail "Expected file does not exist: $file"
  fi
}

assert_json_value() {
  local file="$1"
  local field="$2"
  local expected="$3"
  local actual

  actual="$(
    node -e '
      const fs = require("fs");
      const [file, field] = process.argv.slice(1);
      const data = JSON.parse(fs.readFileSync(file, "utf8"));
      process.stdout.write(String(data[field] ?? ""));
    ' "$file" "$field"
  )"

  assert_equals "$expected" "$actual" "Unexpected metadata value for '$field' in $file"
}

create_build() {
  local version="$1"
  local archive="$2"
  local build_dir="$TEST_ROOT/build-$version"

  rm -rf -- "$build_dir"
  mkdir -p "$build_dir/.output/server"

  printf '%s\n' "$version" >"$build_dir/.output/server/version.txt"

  (
    cd "$build_dir"
    zip -qr "$archive" .output
  )
}

latest_release() {
  find "$APP_DIR/releases" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -printf '%T@ %p\n' |
    sort -rn |
    head -n 1 |
    cut -d' ' -f2-
}

cat >"$FAKE_BIN/sudo" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
exec "$@"
EOF

cat >"$FAKE_BIN/systemctl" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

printf '%s\n' "$*" >>"$SYSTEMCTL_LOG"

case "${1:-}" in
  is-active)
    exit 0
    ;;
  restart)
    exit 0
    ;;
  status)
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF

cat >"$FAKE_BIN/curl" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -f "$FAIL_HEALTH_ONCE_FLAG" ]]; then
  rm -f -- "$FAIL_HEALTH_ONCE_FLAG"
  printf '500'
  exit 0
fi

printf '200'
EOF

chmod +x "$FAKE_BIN/sudo"
chmod +x "$FAKE_BIN/systemctl"
chmod +x "$FAKE_BIN/curl"

export PATH="$FAKE_BIN:$PATH"

echo "TEST: successful first deployment"

BUILD_ONE="$FIXTURES_DIR/build-one.zip"
create_build "release-one" "$BUILD_ONE"

SOURCE_COMMIT="commit-one" \
DEPLOYED_BY="integration-test" \
"$ROOT_DIR/scripts/deploy.sh" "$BUILD_ONE"

RELEASE_ONE="$(readlink -f "$APP_DIR/current")"

[[ -d "$RELEASE_ONE" ]] || fail "First release was not activated"

METADATA_ONE="$RELEASE_ONE/release-metadata.json"

assert_file_exists "$METADATA_ONE"
assert_json_value "$METADATA_ONE" "source_commit" "commit-one"
assert_json_value "$METADATA_ONE" "status" "active"
assert_json_value "$METADATA_ONE" "validation" "passed"
assert_json_value "$METADATA_ONE" "rollback" "not_required"

node "$ROOT_DIR/scripts/release-metadata.mjs" verify "$METADATA_ONE"

sleep 1

echo "TEST: successful second deployment"

BUILD_TWO="$FIXTURES_DIR/build-two.zip"
create_build "release-two" "$BUILD_TWO"

SOURCE_COMMIT="commit-two" \
DEPLOYED_BY="integration-test" \
"$ROOT_DIR/scripts/deploy.sh" "$BUILD_TWO"

RELEASE_TWO="$(readlink -f "$APP_DIR/current")"

[[ "$RELEASE_TWO" != "$RELEASE_ONE" ]] || fail "Second deployment did not create a new active release"

METADATA_TWO="$RELEASE_TWO/release-metadata.json"

assert_file_exists "$METADATA_TWO"
assert_json_value "$METADATA_TWO" "source_commit" "commit-two"
assert_json_value "$METADATA_TWO" "status" "active"
assert_json_value "$METADATA_TWO" "validation" "passed"

echo "TEST: manual rollback"

"$ROOT_DIR/scripts/rollback.sh"

ACTIVE_AFTER_ROLLBACK="$(readlink -f "$APP_DIR/current")"

assert_equals "$RELEASE_ONE" "$ACTIVE_AFTER_ROLLBACK" "Manual rollback did not restore the first release"

assert_json_value "$METADATA_ONE" "status" "active"
assert_json_value "$METADATA_ONE" "validation" "passed"
assert_json_value "$METADATA_ONE" "rollback" "activated"
assert_json_value "$METADATA_TWO" "status" "inactive"

sleep 1

echo "TEST: automatic rollback after failed deployment validation"

BUILD_THREE="$FIXTURES_DIR/build-three.zip"
create_build "release-three" "$BUILD_THREE"

touch "$FAIL_HEALTH_ONCE_FLAG"

set +e

SOURCE_COMMIT="commit-three" \
DEPLOYED_BY="integration-test" \
"$ROOT_DIR/scripts/deploy.sh" "$BUILD_THREE"

deploy_exit_code=$?

set -e

assert_equals "1" "$deploy_exit_code" "Failed deployment should exit with code 1 after successful automatic recovery"

ACTIVE_AFTER_AUTOMATIC_ROLLBACK="$(readlink -f "$APP_DIR/current")"

assert_equals "$RELEASE_ONE" "$ACTIVE_AFTER_AUTOMATIC_ROLLBACK" "Automatic rollback did not restore the previous active release"

FAILED_RELEASE="$(latest_release)"

[[ "$FAILED_RELEASE" != "$RELEASE_ONE" ]] || fail "Failed release could not be identified"

FAILED_METADATA="$FAILED_RELEASE/release-metadata.json"

assert_file_exists "$FAILED_METADATA"
assert_json_value "$FAILED_METADATA" "source_commit" "commit-three"
assert_json_value "$FAILED_METADATA" "status" "failed"
assert_json_value "$FAILED_METADATA" "validation" "failed"
assert_json_value "$FAILED_METADATA" "rollback" "successful"

echo "TEST: deployment lock contention"

(
  exec 9>"$LOCK_FILE"
  flock -x 9
  sleep 3
) &

lock_holder_pid=$!

sleep 1

set +e

DEPLOY_LOCK_TIMEOUT="0" \
"$ROOT_DIR/scripts/deploy.sh" "$BUILD_THREE" >/dev/null 2>&1

deploy_lock_exit_code=$?

set -e

wait "$lock_holder_pid"

assert_equals "3" "$deploy_lock_exit_code" "Concurrent deployment should be rejected with exit code 3"

echo "TEST: rollback lock contention"

(
  exec 9>"$LOCK_FILE"
  flock -x 9
  sleep 3
) &

lock_holder_pid=$!

sleep 1

set +e

DEPLOY_LOCK_TIMEOUT="0" \
"$ROOT_DIR/scripts/rollback.sh" >/dev/null 2>&1

rollback_lock_exit_code=$?

set -e

wait "$lock_holder_pid"

assert_equals "3" "$rollback_lock_exit_code" "Concurrent rollback should be rejected with exit code 3"

echo
echo "All deployment and rollback integration tests passed."