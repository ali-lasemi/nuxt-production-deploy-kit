# Architecture

## Overview

This repository implements a release-based deployment model for Nuxt applications running as Node.js processes behind a reverse proxy and managed by systemd.

The primary production path is:

```text
Source Repository
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
systemd Service
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

## CI Validation

GitHub Actions validates repository integrity before changes are considered healthy.

Current checks include:

- Bash syntax validation
- ShellCheck static analysis
- required-file validation
- executable-bit validation

CI validates deployment tooling and repository structure. It does not claim to perform a live production deployment.

## Release Layout

Deployments use timestamped release directories:

```text
/opt/nuxt-app/
├── current -> /opt/nuxt-app/releases/<active-release>
└── releases/
    ├── <release-a>/
    ├── <release-b>/
    └── <release-c>/
```

A new build is extracted into a new release directory before the active symlink is updated.

This preserves previous releases for rollback and separates release artifacts from the active runtime path.

## Deployment Flow

```text
build.zip
   |
   v
Create timestamped release
   |
   v
Extract artifact
   |
   v
Update current symlink
   |
   v
Restart systemd service
   |
   v
Validate service state
   |
   v
Validate 127.0.0.1 endpoint
   |
   v
Optionally validate public endpoint
   |
   v
Deployment result
```

## Runtime Model

The Nuxt application runs as a Node.js process managed by systemd.

systemd is responsible for:

- process lifecycle
- restart policy
- service identity
- environment configuration
- application startup

The application port defaults to `3000`.

## Reverse Proxy

Nginx and Apache examples are included.

The reverse proxy is responsible for:

- accepting client traffic
- forwarding requests to the Nuxt runtime
- forwarding client and protocol headers
- supporting WebSocket upgrades
- acting as the external traffic boundary

Local deployment validation bypasses the reverse proxy and always uses `127.0.0.1`.

This isolates application-process health from DNS, TLS, and external network dependencies.

## Post-Deployment Validation

Validation is performed in layers.

### Service validation

The configured systemd service must be active.

### Local application validation

The application is checked through:

```text
http://127.0.0.1:<APP_PORT><HEALTH_PATH>
```

The HTTP check supports:

- expected status
- timeout
- retries
- retry delay

### Public validation

When `PUBLIC_URL` is configured, the external endpoint is validated after local validation succeeds.

Public validation is optional.

## Rollback Model

Previous release directories remain available.

Rollback performs:

```text
Identify previous release
        |
        v
Switch current symlink
        |
        v
Restart service
        |
        v
Validate runtime
```

Stronger release-state tracking and automatic rollback are separate reliability improvements.

## Release Retention

Old timestamped releases can be removed with the release cleanup script.

Retention remains configurable so recent releases are preserved for rollback while preventing uncontrolled disk growth.

## Docker

The repository includes a Docker deployment example as an alternative runtime strategy.

Docker is separate from the primary systemd release workflow.

## Blue/Green Status

The repository currently includes:

- a blue/green strategy document
- an Nginx blue/green configuration example

End-to-end automated blue/green deployment is not yet implemented.

Production-grade blue/green requires:

- active environment detection
- inactive environment deployment
- readiness validation
- traffic switching
- switch verification
- rollback traffic switching

## Zero-Downtime Status

A single systemd service restart does not guarantee zero downtime.

True zero-downtime deployment requires parallel runtime targets and controlled reverse-proxy traffic switching.

Until that workflow is implemented end-to-end, the repository does not claim guaranteed zero-downtime deployment.

## Failure Boundaries

### Artifact failure

Detected before service restart when the deployment artifact is unavailable.

### Service failure

Detected through systemd state validation.

### Application failure

Detected through local `127.0.0.1` health validation.

### External-path failure

Detected through optional `PUBLIC_URL` validation.

### Recovery

Previous release recovery is handled through rollback tooling.

## Design Principles

- simple deployment paths over unnecessary orchestration
- explicit failure handling
- previous-release preservation
- local validation before public validation
- reusable operational tooling
- documentation that matches implementation
- no production capability claims without executable support
