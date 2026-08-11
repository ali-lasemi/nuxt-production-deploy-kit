# Changelog

## Unreleased

No unreleased changes.

## v1.0.0 - 2026-08-11

### Added

- Release-based production deployment
- Timestamped release directories
- current symlink activation
- Retry-aware health validation
- systemd service validation
- Optional PUBLIC_URL validation
- Automatic deployment rollback
- Validated manual rollback
- Explicit rollback targets
- Deployment concurrency locking
- Release metadata
- Artifact SHA-256 tracking
- Source commit tracking
- Deployment lifecycle state
- Deployment and rollback integration tests
- Nginx configuration validation
- Apache configuration validation
- systemd unit validation
- systemd security hardening
- Dedicated deploy user
- Restricted sudo policy
- Host bootstrap tooling
- Filesystem permission hardening
- Secret management validation
- Hardened Docker deployment
- Docker build validation
- Docker runtime smoke test
- Blue-green deployment
- Active-slot detection
- Inactive-slot deployment
- Pre-switch readiness validation
- Nginx traffic switching
- Blue-green traffic rollback
- Blue-green integration tests
- Structured deployment audit events
- Release audit tooling
- Prometheus deployment metrics
- Deployment metrics integration tests
- Prometheus alert rules
- Alertmanager example
- Incident-response runbook
- Incident diagnostic tooling

### Changed

- Expanded CI from basic syntax checks to production configuration and integration validation
- Updated systemd runtime to use the active release path
- Bound application runtime to loopback by default
- Hardened Docker and systemd security defaults
- Added blue-green production architecture
- Updated repository documentation to match implemented capabilities

### Fixed

- Shell script BOM issues
- ShellCheck issues
- systemd CI runtime dependency
- Permission policy assertion handling
- Blue-green test active-slot initialization
- Deployment audit workflow YAML
- Deployment event script formatting
- Blue-green audit-log isolation
- Standard deployment audit-log isolation