# Zero-Downtime Deployment Workflow

This document describes a release-directory based deployment workflow for Nuxt applications.

---

## Goal

Reduce service interruption during deployments by preparing releases before switching the active runtime.

---

## Directory Layout

Example:

```txt
/opt/nuxt-app/
  releases/
    20260622120000/
    20260622123000/
  current -> /opt/nuxt-app/releases/20260622123000
```

---

## Workflow

1. Upload build artifact
2. Extract into a new release directory
3. Update `current` symlink
4. Restart application service
5. Run healthcheck
6. Roll back if validation fails

---

## Script

The repository includes:

```txt
scripts/zero-downtime-deploy.sh
```

Example:

```bash
APP_DIR=/opt/nuxt-app SERVICE_NAME=nuxt-app HEALTHCHECK_URL=http://127.0.0.1:3000 ./scripts/zero-downtime-deploy.sh build.zip
```

---

## Production Notes

- Build artifacts should be created before deployment
- Avoid modifying the active runtime directory directly
- Keep previous releases available
- Run healthchecks after switching
- Monitor logs after deployment