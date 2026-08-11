# Deployment Audit Trail

Production deployment operations emit structured JSON Lines events.

Default audit file:

/var/log/nuxt-app/deployments.jsonl

Each line is an independent JSON object.

## Event Fields

schema_version
timestamp
operation
result
application
release
previous_release
slot
previous_slot
source_commit
actor
message

## Operations

Examples include:

deploy
rollback
automatic_rollback
blue_green_deploy
blue_green_rollback
blue_green_traffic_rollback

## Example Event

{"schema_version":1,"timestamp":"2026-08-11T10:00:00.000Z","operation":"deploy","result":"success","application":"nuxt-app","release":"20260811100000","previous_release":"20260811090000","slot":"","previous_slot":"","source_commit":"abc123","actor":"deploy","message":"Deployment completed successfully."}

## Viewing the Audit Trail

AUDIT_LOG=/var/log/nuxt-app/deployments.jsonl ./scripts/audit-releases.sh show

## Verifying the Audit Trail

AUDIT_LOG=/var/log/nuxt-app/deployments.jsonl ./scripts/audit-releases.sh verify

Verification confirms:

- every line contains valid JSON
- every event contains the required schema fields
- every event uses the supported schema version

## File Ownership

Recommended ownership:

deploy:deploy

Recommended mode:

0640

The host bootstrap process already manages /var/log/nuxt-app for the deployment identity.

## Source Commit

Deployment automation should provide:

SOURCE_COMMIT=<git-sha>

The value is included in deployment events and release metadata.

## Actor

Deployment automation may provide:

DEPLOYED_BY=<actor>

If not provided, the current user is recorded.

## Format

JSON Lines is used intentionally.

Benefits:

- append-only writes
- easy shell inspection
- easy ingestion by log collectors
- one event per line
- no need to rewrite an entire JSON document for every deployment

## External Shipping

The audit log can be collected by:

- journald forwarding
- Fluent Bit
- Vector
- Filebeat
- OpenTelemetry Collector
- Loki agents
- existing host log pipelines

This repository does not force a specific observability backend.

## Scope

The audit trail provides deployment-level operational history.

It is not intended to replace:

application logs
security audit systems
Git history
CI logs
release metadata

Those sources complement each other.