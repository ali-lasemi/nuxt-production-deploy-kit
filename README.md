# Nuxt Production Deploy Kit

Production-oriented deployment tooling and operational patterns for Nuxt applications using release directories, systemd, reverse proxies, health validation, rollback, Docker examples, and CI validation.

## Overview

This repository demonstrates practical deployment engineering for Nuxt applications with emphasis on:

- reliability
- repeatable releases
- post-deployment validation
- rollback readiness
- operational clarity
- maintainable infrastructure examples

The primary deployment model is a release-based systemd workflow.

## Current Capabilities

- Nuxt production artifact deployment
- timestamped release directories
- `current` symlink switching
- systemd service management
- retry-aware HTTP healthchecks
- post-deployment service validation
- local validation through `127.0.0.1`
- optional public endpoint validation
- rollback tooling
- release retention cleanup
- Nginx reverse proxy example
- Apache reverse proxy example
- Docker deployment example
- log rotation tooling
- deployment runbook
- troubleshooting documentation
- GitHub Actions validation
- ShellCheck validation

## Repository Structure

```text
.github/workflows/     Repository validation
docs/                  Architecture and operational documentation
examples/              Runtime and reverse-proxy examples
scripts/               Deployment and operational tooling
```

## Architecture

```text
Git Repository
     |
     v
CI Validation
     |
     v
Build Artifact
     |
     v
Timestamped Release
     |
     v
current Symlink
     |
     v
systemd
     |
     v
Nuxt Runtime
     |
     v
Reverse Proxy
     |
     v
Users
```

See `docs/architecture.md`.

## Deployment

Standard release flow:

```text
Build artifact
   |
   v
Create release directory
   |
   v
Extract artifact
   |
   v
Switch current symlink
   |
   v
Restart application service
   |
   v
Validate systemd state
   |
   v
Validate local endpoint
   |
   v
Optionally validate public endpoint
```

Example:

```bash
./scripts/deploy.sh build.zip
```

Configuration:

```bash
APP_NAME=nuxt-app APP_PORT=3000 HEALTH_PATH=/ ./scripts/deploy.sh build.zip
```

Optional public validation:

```bash
PUBLIC_URL=https://example.com ./scripts/deploy.sh build.zip
```

See `docs/deployment.md`.

## Validation

Deployment validation checks:

1. configured systemd service is active
2. application responds through `127.0.0.1`
3. optional public endpoint responds successfully

Healthchecks support retries, timeout configuration, and expected HTTP status configuration.

## Rollback

Rollback tooling preserves the release-based deployment model and switches the active symlink back to a previous release.

See:

```text
docs/rollback.md
scripts/rollback.sh
```

## Reverse Proxy

Examples are available for:

- Nginx
- Apache

## Docker

A Docker deployment example is included as an alternative deployment pattern.

Docker is separate from the primary systemd release workflow.

## Blue/Green Status

The repository contains:

- a blue/green strategy document
- an Nginx blue/green configuration example

End-to-end automated blue/green traffic switching is still a roadmap item.

## Zero-Downtime Status

A single systemd service restart is not considered sufficient evidence of guaranteed zero downtime.

True zero-downtime deployment remains a roadmap item and requires parallel runtime targets plus controlled reverse-proxy traffic switching.

## CI

GitHub Actions currently validates:

- Bash syntax
- ShellCheck
- required repository files
- executable script permissions

Additional integration tests and configuration validation are planned.

## Operations

Operational documentation includes:

- architecture
- deployment
- rollback
- troubleshooting
- systemd
- Nginx
- Apache
- log rotation
- Docker deployment
- deployment runbook

## Roadmap

Next production-grade improvements focus on:

- automatic rollback safety
- release metadata
- deployment locking
- integration tests
- configuration validation
- security hardening
- true blue/green traffic switching
- observability
- release auditability

## Philosophy

Production tooling should be simple, observable, recoverable, testable, and honest about its guarantees.

## License

MIT
