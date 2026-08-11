# Architecture

## Overview

This repository provides three production deployment models:

1. release-based systemd deployment
2. blue-green systemd deployment with Nginx traffic switching
3. hardened Docker deployment

The release-based systemd workflow is the primary deployment model.

The blue-green workflow provides parallel runtime targets.

Docker is an alternative runtime strategy.

## Standard Release Layout

/opt/nuxt-app/
├── .deployment.lock
├── current
└── releases/
    ├── <release-a>/
    ├── <release-b>/
    └── <release-c>/

Each release contains release metadata.

## Standard Deployment Flow

Artifact
  |
  v
Acquire lock
  |
  v
Calculate checksum
  |
  v
Create release
  |
  v
Extract artifact
  |
  v
Write metadata
  |
  v
Switch current symlink
  |
  v
Restart systemd
  |
  v
Validate service
  |
  v
Validate 127.0.0.1
  |
  v
Optional PUBLIC_URL validation
  |
  +--> success
  |
  +--> automatic rollback

## Automatic Rollback

Before deployment, the current release is recorded.

If restart or validation fails:

1. the failed release remains recorded
2. current is restored to the previous release
3. systemd is restarted
4. the restored release is validated
5. rollback state is recorded

## Manual Rollback

Manual rollback supports:

- automatic previous-release selection
- explicit rollback target
- target validation
- restoration of the original release if rollback fails

## Deployment Locking

Deployment and rollback operations use a shared flock lock.

Default:

/opt/nuxt-app/.deployment.lock

This prevents simultaneous state mutations.

## Blue-Green Architecture

Nginx
  |
  v
nuxt_active upstream
   /          \
  /            \
blue          green
3001          3002
 |             |
nuxt-app@blue nuxt-app@green
 |             |
blue/current  green/current

## Blue-Green Layout

/opt/nuxt-app/
├── blue/
│   ├── current
│   └── releases/
├── green/
│   ├── current
│   └── releases/
└── .deployment.lock

## Blue-Green Deployment Flow

Detect active slot
  |
  v
Select inactive slot
  |
  v
Deploy release
  |
  v
Restart inactive instance
  |
  v
Validate inactive slot
  |
  v
Generate Nginx upstream
  |
  v
nginx -t
  |
  v
Graceful reload
  |
  v
Optional PUBLIC_URL validation
  |
  +--> success
  |
  +--> restore previous traffic

## Runtime Security

The systemd runtime uses:

User=deploy
Group=deploy
UMask=0027

Hardening includes:

- NoNewPrivileges
- PrivateTmp
- PrivateDevices
- ProtectSystem=strict
- ProtectHome
- ProtectKernelTunables
- ProtectKernelModules
- ProtectKernelLogs
- ProtectControlGroups
- ProtectClock
- ProtectHostname
- RestrictSUIDSGID
- RestrictRealtime
- LockPersonality
- RestrictNamespaces
- restricted address families
- no Linux capabilities

## Secrets

Secrets remain outside release directories.

Recommended file:

/etc/nuxt-app/nuxt-app.env

Ownership:

root:deploy

Mode:

0640

## Reverse Proxy

Nginx and Apache examples are included.

Local deployment health validation uses 127.0.0.1.

PUBLIC_URL validation is optional.

## Docker

The Docker runtime uses:

- multi-stage build
- non-root node user
- read-only filesystem
- tmpfs
- dropped capabilities
- no-new-privileges
- loopback-only published port
- healthcheck

## Deployment Audit

Deployment operations emit structured JSON Lines events.

Default file:

/var/log/nuxt-app/deployments.jsonl

Operations include:

- deploy
- rollback
- automatic_rollback
- blue_green_deploy
- blue_green_rollback
- blue_green_traffic_rollback

## Metrics

Deployment events are converted into Prometheus textfile metrics.

Flow:

Deployment audit
  |
  v
deployment-metrics.mjs
  |
  v
Prometheus textfile
  |
  v
Node Exporter
  |
  v
Prometheus

## Alerting

Prometheus rules cover:

- deployment failure
- automatic rollback
- missing deployment metrics
- failure newer than success

Alertmanager routing is included as an example.

## Incident Response

Operational recovery includes:

- incident-response runbook
- diagnostic collection
- release metadata
- deployment audit
- rollback
- blue-green traffic rollback
- health validation
- deployment alerts

## CI Validation

CI validates:

- Bash
- ShellCheck
- Nginx
- Apache
- systemd
- systemd hardening
- sudoers
- permissions
- secret policy
- Prometheus rules
- Alertmanager
- Docker Compose
- Docker build
- Docker runtime
- deployment metrics
- deployment audit
- standard deploy and rollback
- blue-green deployment

## Failure Boundaries

Artifact failure:
Detected before activation.

Service failure:
Detected during restart and service validation.

Runtime failure:
Detected through local health validation.

Public routing failure:
Detected through optional PUBLIC_URL validation.

Nginx failure:
Detected with nginx -t.

Blue-green readiness failure:
Detected before traffic switching.

Rollback failure:
Detected through recovery validation.

Concurrent deployment:
Rejected through the shared lock.

## Engineering Principles

- local validation before public validation
- inactive preparation before traffic switching
- executable rollback
- explicit failure handling
- least privilege
- reproducible CI
- previous-state preservation
- structured operational evidence
- no unsupported production claims