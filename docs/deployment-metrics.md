# Deployment Metrics

Deployment metrics are generated from the structured deployment audit trail.

The default source is:

/var/log/nuxt-app/deployments.jsonl

The exporter produces Prometheus text format suitable for the Node Exporter textfile collector.

## Default Metrics File

/var/lib/node_exporter/textfile_collector/nuxt-deployment.prom

## Export

Run:

AUDIT_LOG=/var/log/nuxt-app/deployments.jsonl \
METRICS_FILE=/var/lib/node_exporter/textfile_collector/nuxt-deployment.prom \
./scripts/export-deployment-metrics.sh

## Metrics

### Deployment Events

nuxt_deployment_events_total

Labels:

operation
result

Example:

nuxt_deployment_events_total{operation="deploy",result="success"} 12

### Last Successful Operation

nuxt_deployment_last_success_timestamp_seconds

Example:

nuxt_deployment_last_success_timestamp_seconds{operation="deploy"} 1786442410

### Last Failed Operation

nuxt_deployment_last_failure_timestamp_seconds

Example:

nuxt_deployment_last_failure_timestamp_seconds{operation="deploy"} 1786446010

### Audit Event Count

nuxt_deployment_audit_events

This reports the number of structured events currently present in the deployment audit log.

## Supported Operations

Metrics are derived dynamically from audit events.

Typical operations include:

deploy
rollback
automatic_rollback
blue_green_deploy
blue_green_rollback
blue_green_traffic_rollback

## Node Exporter

Node Exporter can expose files from its textfile collector directory.

A common configuration is:

--collector.textfile.directory=/var/lib/node_exporter/textfile_collector

The exporter writes metrics atomically by creating a temporary file and renaming it into place.

This prevents Prometheus from observing a partially written metrics file.

## Scheduling

The exporter can run:

after each deployment
from a systemd timer
from cron
from existing host automation

A deployment-triggered export gives the freshest result.

Periodic export provides resilience if deployment automation cannot update the metrics file.

## Scope

These metrics describe deployment operations.

They do not replace application-level metrics such as:

HTTP request rate
latency
error rate
CPU
memory
event-loop health
business metrics

Those should come from the application and infrastructure monitoring stack.