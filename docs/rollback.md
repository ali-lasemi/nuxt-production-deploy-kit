# Rollback Strategy

This document describes a rollback strategy for failed Nuxt deployments.

---

## Goal

Restore the previous working release quickly when a deployment fails.

---

## Directory Layout

```txt
/opt/nuxt-app/
  releases/
    20260622120000/
    20260622123000/
  current -> /opt/nuxt-app/releases/20260622123000
```

---

## Rollback Flow

1. Detect failed deployment
2. Find previous release
3. Update `current` symlink
4. Restart application service
5. Run healthcheck
6. Confirm service recovery

---

## Script

The repository includes:

```txt
scripts/rollback.sh
```

Example:

```bash
APP_DIR=/opt/nuxt-app SERVICE_NAME=nuxt-app HEALTHCHECK_URL=http://127.0.0.1:3000 ./scripts/rollback.sh
```

---

## Production Notes

- Always keep at least one previous release
- Run healthchecks after rollback
- Monitor logs after recovery
- Document rollback events
- Investigate root cause after service recovery