# Nuxt Production Deploy Kit

Production-grade deployment and operational tooling for Nuxt applications using release-based deployments, systemd, reverse proxies, validated rollback, blue-green traffic switching, hardened runtime examples, Docker, deployment observability, and CI integration testing.

## Overview

This repository demonstrates practical production deployment engineering for Nuxt applications with emphasis on:

- repeatable releases
- deployment safety
- post-deployment validation
- automatic recovery
- blue-green traffic switching
- operational visibility
- least-privilege runtime security
- reproducible CI validation
- incident readiness

The primary deployment model is a release-based systemd workflow.

A separate blue-green workflow provides parallel runtime slots and controlled Nginx traffic switching.

Docker is provided as an alternative deployment strategy.

## Production Capabilities

### Release Deployment

- timestamped release directories
- current symlink switching
- systemd service management
- shared deployment locking
- artifact SHA-256 tracking
- source commit metadata
- release lifecycle metadata
- release cleanup

### Validation

- systemd service-state validation
- retry-aware HTTP health checks
- local validation through 127.0.0.1
- optional PUBLIC_URL validation
- configurable HTTP status
- configurable timeout and retries
- deployment summary output

### Rollback

- previous-release selection
- explicit rollback targets
- rollback validation
- automatic rollback after failed deployment
- original-release restoration after failed rollback
- integration testing

### Blue-Green Deployment

- automatic active-slot detection
- blue and green systemd instances
- inactive-slot deployment
- independent runtime ports
- readiness validation before traffic switch
- Nginx upstream switching
- nginx -t validation
- graceful Nginx reload
- optional public validation
- automatic traffic restoration
- explicit traffic rollback
- integration testing

Default slots:

blue: 127.0.0.1:3001
green: 127.0.0.1:3002

### Runtime Security

The repository includes:

- non-root systemd runtime
- restricted sudo policy
- restrictive umask
- systemd sandboxing
- capability removal
- filesystem protection
- kernel protection
- secure release ownership
- secure configuration ownership
- secret-file permission validation

### Secret Management

Production secrets remain outside release directories.

Recommended secret file:

/etc/nuxt-app/nuxt-app.env

Recommended ownership:

root:deploy

Recommended mode:

0640

### Docker

The Docker example includes:

- multi-stage build
- non-root runtime
- read-only filesystem
- dropped capabilities
- no-new-privileges
- healthcheck
- loopback-only published port
- PID limit
- tmpfs
- real CI image build
- runtime user validation
- live container smoke test

### Deployment Audit

Deployment operations emit append-only JSON Lines events.

Default location:

/var/log/nuxt-app/deployments.jsonl

Events include:

- timestamp
- operation
- result
- release
- previous release
- slot
- previous slot
- source commit
- actor
- message

### Deployment Metrics

Deployment audit events can be exported as Prometheus textfile metrics.

Metrics include:

- deployment event counters
- latest success timestamp
- latest failure timestamp
- audit event count

### Alerting

The repository includes:

- Prometheus deployment alerts
- deployment failure alerts
- rollback alerts
- missing metrics alerts
- unresolved failure alerts
- Alertmanager routing example

### Incident Response

Operational support includes:

- incident-response runbook
- secret-safe diagnostic collection
- release inspection
- blue-green slot inspection
- systemd diagnostics
- Nginx validation
- health diagnostics
- deployment audit inspection
- rollback procedures
- recovery verification
- post-incident review guidance

## Repository Structure

.github/workflows/     CI validation
docs/                  Architecture and operational documentation
examples/              Runtime, proxy, Docker, and monitoring examples
scripts/               Deployment and operational tooling
tests/config/          Configuration policy tests
tests/integration/     Deployment integration tests
tests/fixtures/        Deterministic test fixtures

## Standard Deployment

Build artifact
    |
    v
Deployment lock
    |
    v
Timestamped release
    |
    v
Release metadata
    |
    v
current symlink
    |
    v
systemd restart
    |
    v
service validation
    |
    v
127.0.0.1 health validation
    |
    v
optional PUBLIC_URL validation
    |
    +--> success
    |
    +--> automatic rollback

Run:

./scripts/deploy.sh build.zip

Example:

APP_NAME=nuxt-app APP_PORT=3000 HEALTH_PATH=/ PUBLIC_URL=https://example.com ./scripts/deploy.sh build.zip

## Rollback

Automatic previous release:

./scripts/rollback.sh

Explicit release:

./scripts/rollback.sh <release-id>

## Blue-Green Deployment

Run:

./scripts/blue-green-deploy.sh build.zip

Traffic rollback:

./scripts/blue-green-rollback.sh

## Validation

Run:

APP_NAME=nuxt-app APP_PORT=3000 HEALTH_PATH=/ ./scripts/validate-deployment.sh

## Deployment Audit

Show:

./scripts/audit-releases.sh show

Verify:

./scripts/audit-releases.sh verify

## Deployment Metrics

./scripts/export-deployment-metrics.sh

## Incident Diagnostics

./scripts/collect-incident-diagnostics.sh

## CI Validation

GitHub Actions validates:

- Bash syntax
- ShellCheck
- runtime dependencies
- required files
- executable permissions
- release metadata tooling
- deployment event tooling
- deployment metrics tooling
- Nginx configuration
- blue-green Nginx configuration
- Apache configuration
- systemd units
- systemd hardening
- sudoers policy
- deployment permissions
- secret management
- deployment alerts
- Prometheus rules
- Alertmanager configuration
- incident-response policy
- Docker Compose
- Docker image build
- Docker runtime user
- Docker health smoke test
- deployment metrics integration
- deployment audit integration
- blue-green integration
- deployment and rollback integration

## Documentation

See:

docs/architecture.md
docs/deployment.md
docs/rollback.md
docs/deployment-locking.md
docs/release-metadata.md
docs/docker-deployment.md
docs/systemd-security.md
docs/deployment-user-security.md
docs/secret-management.md
docs/blue-green.md
docs/deployment-audit.md
docs/deployment-metrics.md
docs/deployment-alerting.md
docs/incident-response.md

## Roadmap

The production-hardening roadmap is complete.

Future improvements should be driven by real operational requirements rather than artificial feature growth.

## Engineering Principles

Production deployment tooling should be:

- simple
- explicit
- observable
- testable
- recoverable
- least-privileged
- honest about failure boundaries

## License

MIT