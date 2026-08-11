#!/usr/bin/env bash

emit_deployment_event() {
  local operation="$1"
  local result="$2"
  local release="${3:-}"
  local previous_release="${4:-}"
  local slot="${5:-}"
  local previous_slot="${6:-}"
  local message="${7:-}"

  local event_script
  local audit_log

  event_script="${SCRIPT_DIR}/deployment-event.mjs"
  audit_log="${AUDIT_LOG:-/var/log/nuxt-app/deployments.jsonl}"

  if [[ ! -f "$event_script" ]]; then
    return 0
  fi

  node "$event_script" append "$audit_log" \
    "operation=$operation" \
    "result=$result" \
    "application=${APP_NAME:-nuxt-app}" \
    "release=$release" \
    "previous_release=$previous_release" \
    "slot=$slot" \
    "previous_slot=$previous_slot" \
    "source_commit=${SOURCE_COMMIT:-unknown}" \
    "actor=${DEPLOYED_BY:-${USER:-unknown}}" \
    "message=$message"
}