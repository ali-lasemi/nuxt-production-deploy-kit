# Deployment Runbook

Operational runbook for Nuxt production deployments.

---

## Purpose

This runbook provides repeatable steps for deploying, validating and recovering Nuxt applications in production environments.

---

## Pre-Deployment Checklist

Before deploying:

- Confirm build artifact exists
- Confirm server SSH access
- Confirm systemd service exists
- Confirm reverse proxy configuration is valid
- Confirm previous release is available
- Confirm healthcheck URL is working

---

## Standard Deployment

Run:

```bash
APP_DIR=/opt/nuxt-app SERVICE_NAME=nuxt-app HEALTHCHECK_URL=http://127.0.0.1:3000 ./scripts/zero-downtime-deploy.sh build.zip
```

---

## Healthcheck Validation

Run:

```bash
./scripts/healthcheck.sh http://127.0.0.1:3000
```

Expected result:

```txt
Healthcheck passed
```

---

## Rollback Procedure

If deployment fails:

```bash
APP_DIR=/opt/nuxt-app SERVICE_NAME=nuxt-app HEALTHCHECK_URL=http://127.0.0.1:3000 ./scripts/rollback.sh
```

---

## Reverse Proxy Validation

For Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

For Apache:

```bash
sudo apachectl configtest
sudo systemctl reload apache2
```

---

## Common Failure Scenarios

### Build Artifact Missing

Check:

```bash
ls -lah build.zip
```

### Application Does Not Start

Check:

```bash
sudo systemctl status nuxt-app
journalctl -u nuxt-app -f
```

### Reverse Proxy Returns 502

Check:

```bash
curl http://127.0.0.1:3000
sudo nginx -t
```

### Healthcheck Fails

Check logs:

```bash
journalctl -u nuxt-app -n 100
```

Then roll back if needed.

---

## Post-Deployment Checklist

After deployment:

- Confirm application health
- Confirm reverse proxy response
- Check application logs
- Monitor CPU and memory
- Keep previous release available
- Document deployment result

---

## Incident Notes

For failed deployments, document:

- Deployment time
- Failed release
- Error symptoms
- Rollback result
- Root cause
- Prevention actions