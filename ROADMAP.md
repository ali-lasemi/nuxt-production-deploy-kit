# Roadmap

## Phase 1 — Production Deployment Foundation

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

## Phase 2 — Production Reliability

- [ ] Automatic rollback on failed deployment validation
- [ ] Release metadata and verified release state
- [ ] Deployment concurrency locking
- [ ] Rollback concurrency locking
- [ ] Deployment and rollback integration tests
- [ ] Nginx configuration validation in CI
- [ ] Apache configuration in CI
- [ ] systemd unit validation in CI
- [ ] Docker build validation in CI

## Phase 3 — Runtime Hardening

- [ ] Production Docker hardening
- [ ] systemd security hardening
- [ ] Deployment user and sudo policy documentation
- [ ] Secret-management guidance
- [ ] Filesystem and release permission hardening

## Phase 4 — Advanced Deployment Strategies

- [ ] Automated blue/green environment selection
- [ ] Inactive environment deployment
- [ ] Pre-switch readiness validation
- [ ] Atomic reverse-proxy traffic switch
- [ ] Traffic-switch rollback
- [ ] Verified zero-downtime deployment workflow

## Phase 5 — Operational Maturity

- [ ] Structured deployment event logging
- [ ] Deployment metrics examples
- [ ] Alert integration examples
- [ ] Release audit trail
- [ ] Incident response improvements
