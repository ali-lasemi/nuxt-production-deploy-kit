# Incident Response Runbook

This runbook covers incidents related to production deployment, rollback, blue-green traffic switching, service startup, reverse-proxy routing, and deployment observability.

## Priorities

During an incident:

1. Protect availability.
2. Stop additional deployment changes.
3. Determine the currently active release or traffic slot.
4. Validate application health locally.
5. Restore the last known-good release or slot when necessary.
6. Preserve deployment evidence.
7. Investigate root cause after service stability is restored.

## First Response

Do not immediately redeploy repeatedly.

Check repository automation or deployment tooling for another active operation.

Confirm service state:

systemctl status nuxt-app

For blue-green:

systemctl status nuxt-app@blue.service
systemctl status nuxt-app@green.service

Validate local health:

curl -i http://127.0.0.1:3000/

Blue:

curl -i http://127.0.0.1:3001/

Green:

curl -i http://127.0.0.1:3002/

## Collect Diagnostics

Run:

./scripts/collect-incident-diagnostics.sh

Optional public endpoint:

PUBLIC_URL=https://example.com ./scripts/collect-incident-diagnostics.sh

The diagnostic script intentionally does not read:

/etc/nuxt-app/nuxt-app.env

or other secret files.

Review diagnostic output before sharing it outside the operations team.

## Failed Standard Deployment

If deployment fails but automatic rollback succeeds:

1. Confirm the previous release is active.
2. Run post-deployment validation.
3. Inspect the failed release metadata.
4. Inspect the deployment audit trail.
5. Do not delete the failed release until the incident is understood.

Current release:

readlink -f /opt/nuxt-app/current

Audit trail:

./scripts/audit-releases.sh show

## Automatic Rollback Failure

If deployment and automatic rollback both fail:

1. Stop further deployment attempts.
2. Identify known-good releases under /opt/nuxt-app/releases.
3. Select an explicit rollback target.
4. Run rollback.
5. Validate the restored service.

Example:

./scripts/rollback.sh <release-id>

Then:

APP_NAME=nuxt-app \
APP_PORT=3000 \
HEALTH_PATH=/ \
./scripts/validate-deployment.sh

## Blue-Green Deployment Failure

If the inactive slot fails before traffic switching:

Production traffic should remain on the previous active slot.

Check:

systemctl status nuxt-app@blue.service
systemctl status nuxt-app@green.service

Validate both ports.

Do not switch traffic manually until the inactive slot is healthy.

## Blue-Green Public Validation Failure

If public validation fails after the Nginx switch, the deployment workflow attempts automatic traffic restoration.

Confirm the active upstream:

cat /etc/nginx/conf.d/nuxt-active-upstream.conf

Validate Nginx:

nginx -t

Validate public availability.

## Manual Blue-Green Traffic Rollback

Use:

./scripts/blue-green-rollback.sh

The rollback target must pass readiness validation before traffic is switched.

After rollback:

1. Verify the active upstream.
2. Verify local health.
3. Verify public health.
4. Inspect deployment audit events.

## Nginx Failure

Validate configuration:

sudo nginx -t

Inspect active upstream:

cat /etc/nginx/conf.d/nuxt-active-upstream.conf

Check Nginx process state:

systemctl status nginx

Check logs according to the host logging policy.

Do not reload Nginx repeatedly when configuration validation is failing.

## systemd Failure

Inspect:

systemctl status nuxt-app

Recent journal:

journalctl -u nuxt-app -n 100 --no-pager

Blue-green:

journalctl -u nuxt-app@blue.service -n 100 --no-pager
journalctl -u nuxt-app@green.service -n 100 --no-pager

Common areas to verify:

release symlink
working directory
Node.js runtime availability
environment file permissions
log directory permissions
service user ownership
port conflicts

## Deployment Lock Incident

A deployment or rollback may exit with code 3 when the shared lock cannot be acquired.

Do not delete the lock file as the first response.

Determine whether another deployment process is running.

Inspect processes and deployment automation.

A lock file can exist without being actively locked.

The lock is advisory and process-owned.

## Secret or Permission Incident

Do not print the production environment file.

Validate metadata only:

sudo ./scripts/validate-secret-file.sh /etc/nuxt-app/nuxt-app.env

Expected:

owner=root
group=deploy
mode=0640

Review deployment-user and sudo policy documentation before changing permissions.

## Alert Response

### NuxtDeploymentFailure

Treat as a failed production change.

Confirm whether rollback succeeded.

Check:

deployment audit trail
release metadata
application health
service state
reverse-proxy state

### NuxtAutomaticRollbackTriggered

Availability may already be restored.

Investigate why the attempted deployment failed before retrying.

### NuxtDeploymentMetricsMissing

Check:

deployment audit log
metrics exporter
textfile collector directory
Node Exporter
Prometheus scrape status

### NuxtDeploymentFailureNewerThanSuccess

The latest observed result for an operation remains failed.

Determine whether recovery occurred without generating a successful event.

## Deployment Audit Evidence

Show events:

AUDIT_LOG=/var/log/nuxt-app/deployments.jsonl ./scripts/audit-releases.sh show

Verify structure:

AUDIT_LOG=/var/log/nuxt-app/deployments.jsonl ./scripts/audit-releases.sh verify

Preserve relevant events during incident investigation.

## Recovery Verification

An incident is not considered recovered only because a process is running.

Verify:

1. Correct release or slot is active.
2. systemd reports the service active.
3. Local health endpoint succeeds.
4. Reverse proxy configuration validates.
5. Public health succeeds when configured.
6. Deployment audit trail reflects recovery.
7. Deployment alerts clear.

## Post-Incident Review

Record:

incident start and end time
affected deployment or release
source commit
user impact
failure mode
rollback or recovery action
monitoring signals
root cause
corrective action
follow-up owner

Prefer concrete repository improvements over procedural complexity.

Examples:

new integration test
stronger validation
better alert
safer rollback condition
improved documentation
permission correction

## Security

Never attach or paste:

secret environment files
API keys
tokens
passwords
private keys
database credentials

Sanitize logs before sharing them externally.

## Escalation

Escalate when:

both current and previous releases fail
both blue and green slots are unhealthy
Nginx cannot load a valid configuration
deployment rollback cannot restore service
data integrity may be affected
credentials may be exposed
the incident exceeds the operator's authorization boundary