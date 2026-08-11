# Deployment Concurrency Locking

Deployment and rollback operations use the same host-level advisory lock.

This prevents concurrent operations from changing the active release or restarting the application service at the same time.

## Default Lock File

/opt/nuxt-app/.deployment.lock

## Configuration

DEPLOY_LOCK_FILE
DEPLOY_LOCK_TIMEOUT

Default values:

DEPLOY_LOCK_FILE=<APP_DIR>/.deployment.lock
DEPLOY_LOCK_TIMEOUT=30

The timeout is expressed in seconds.

## Behavior

Before changing release state, both deployment and rollback:

1. Open the shared lock file.
2. Attempt to acquire an exclusive lock with flock.
3. Wait up to the configured timeout.
4. Continue only after acquiring the lock.

If the lock cannot be acquired, the operation exits before modifying the active release.

## Exit Code

Lock acquisition failure exits with code 3.

This distinguishes concurrency rejection from deployment or validation failure.

## Runtime Dependency

The deployment host must provide flock.

On common Linux distributions, flock is provided by util-linux.

## Scope

This lock protects deployment operations performed by this toolkit on a single host.

It is not a distributed lock across multiple deployment hosts.