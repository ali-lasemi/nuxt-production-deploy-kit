# Deployment Workflow

This document describes a production-oriented deployment workflow for Nuxt applications.

---

## Deployment Steps

1. Build the Nuxt application
2. Package the `.output` directory
3. Upload the artifact to the server
4. Extract the artifact into the release directory
5. Update the current symlink
6. Restart the systemd service
7. Run a healthcheck
8. Roll back if the healthcheck fails

---

## Healthcheck

Example:

```bash
./scripts/healthcheck.sh http://127.0.0.1:3000
```

You can customize the expected status:

```bash
EXPECTED_STATUS=200 ./scripts/healthcheck.sh http://127.0.0.1:3000
```

---

## Environment Configuration

Example production environment file:

```bash
cp examples/env/.env.production.example .env.production
```

Common variables:

```env
NODE_ENV=production
PORT=3000
APP_URL=https://example.com
LOG_DIR=/var/log/nuxt-app
RELEASE_DIR=/opt/nuxt-app
```

## Production Notes

- Always validate the application after deployment
- Keep previous releases for rollback
- Use dedicated service users
- Avoid deploying directly into the active runtime directory
- Monitor logs after restart