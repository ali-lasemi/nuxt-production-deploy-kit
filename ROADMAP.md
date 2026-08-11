# Roadmap

## Phase 1 - Production Deployment Foundation

- [x] Repository structure
- [x] systemd service example
- [x] Nginx reverse proxy example
- [x] Apache reverse proxy example
- [x] Log rotation documentation
- [x] Retry-aware healthcheck
- [x] Deployment script
- [x] Rollback script
- [x] Release retention cleanup
- [x] Environment configuration example
- [x] Post-deployment validation framework
- [x] Deployment runbook
- [x] Architecture documentation
- [x] ShellCheck CI validation

## Phase 2 - Production Reliability

- [x] Automatic rollback on failed deployment validation
- [x] Release metadata and verified release state
- [x] Deployment concurrency locking
- [x] Rollback concurrency locking
- [x] Deployment and rollback integration tests
- [x] Nginx configuration validation in CI
- [x] Apache configuration validation in CI
- [x] systemd unit validation in CI
- [x] Docker build validation in CI

## Phase 3 - Runtime Hardening

- [x] Production Docker hardening
- [x] systemd security hardening
- [x] Deployment user and sudo policy documentation
- [x] Secret-management guidance
- [x] Filesystem and release permission hardening

## Phase 4 - Advanced Deployment Strategies

- [ ] Automated blue/green environment selection
- [ ] Inactive environment deployment
- [ ] Pre-switch readiness validation
- [ ] Atomic reverse-proxy traffic switch
- [ ] Traffic-switch rollback
- [ ] Verified zero-downtime deployment workflow

## Phase 5 - Operational Maturity

- [ ] Structured deployment event logging
- [ ] Deployment metrics examples
- [ ] Alert integration examples
- [ ] Release audit trail
- [ ] Incident response improvements