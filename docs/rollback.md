# Rollback

## Overview

Rollback uses the same release-directory and `current` symlink model as deployment.

A rollback is not considered successful until the selected release is restarted and passes the deployment validation framework.

## Manual Rollback

Rollback to the most recent release that is not currently active:

```bash
./scripts/rollback.sh
```

Rollback to a specific release:

```bash
./scripts/rollback.sh 20260811110000
```

An absolute release path may also be supplied.

## Validation

Rollback validation uses the same configuration as deployment:

```text
APP_NAME
APP_PORT
HEALTH_PATH
PUBLIC_URL
EXPECTED_STATUS
TIMEOUT_SECONDS
HEALTH_RETRIES
HEALTH_RETRY_DELAY
```

Validation checks:

1. systemd service state
2. local application endpoint through `127.0.0.1`
3. optional public endpoint

## Failed Rollback Recovery

Before switching releases, the rollback script records the currently active release.

If the rollback target cannot restart or fails validation, the script attempts to restore the original release and restart the service.

This prevents an unvalidated rollback target from silently remaining active.

## Automatic Deployment Rollback

`scripts/deploy.sh` records the active release before switching the `current` symlink.

If the new release cannot restart or fails post-deployment validation:

1. the previous release is restored
2. the systemd service is restarted
3. the previous release is validated
4. deployment exits with failure even when recovery succeeds

A successful recovery therefore means the service was restored, not that the failed deployment is reported as successful.

If both deployment and recovery fail, the deployment script exits with a distinct critical failure status.

## Release Preservation

Failed releases are preserved by default for investigation.

Use the release cleanup tooling to enforce retention after diagnostics are complete.
