# Blue-Green Deployment

The blue-green workflow maintains two independently runnable Nuxt environments.

Blue:

127.0.0.1:3001

Green:

127.0.0.1:3002

Only one slot receives production traffic at a time.

## Runtime Layout

/opt/nuxt-app/blue/current
/opt/nuxt-app/blue/releases

/opt/nuxt-app/green/current
/opt/nuxt-app/green/releases

The two slots use systemd instance services:

nuxt-app@blue.service
nuxt-app@green.service

## Deployment Flow

The blue-green deployment script performs:

1. Acquire the shared deployment lock.
2. Detect the currently active Nginx slot.
3. Select the inactive slot.
4. Create a timestamped release in that slot.
5. Update the inactive slot current symlink.
6. Restart only the inactive slot.
7. Validate the inactive application through 127.0.0.1.
8. Write a new Nginx upstream configuration.
9. Validate Nginx with nginx -t.
10. Gracefully reload Nginx.
11. Optionally validate PUBLIC_URL.
12. Restore the previous upstream automatically if public validation fails.

The previously active application remains running during the switch.

## Deployment

Example:

APP_NAME=nuxt-app \
APP_DIR=/opt/nuxt-app \
PUBLIC_URL=https://example.com \
./scripts/blue-green-deploy.sh build.zip

## Traffic Rollback

Rollback does not rebuild or redeploy the application.

It validates the previous slot and switches Nginx traffic back:

./scripts/blue-green-rollback.sh

## Nginx

The server configuration uses:

proxy_pass http://nuxt_active

The active upstream is stored separately:

/etc/nginx/conf.d/nuxt-active-upstream.conf

The repository example is:

examples/blue-green/nuxt-active-upstream.conf

## systemd

Install the template:

/etc/systemd/system/nuxt-app@.service

Install slot environment files:

/etc/nuxt-app/blue.env
/etc/nuxt-app/green.env

Blue uses:

PORT=3001

Green uses:

PORT=3002

## Availability Model

The active slot is never stopped before the inactive slot passes readiness validation.

Nginx configuration is validated before reload.

Nginx reload is graceful, so existing worker connections can finish while new workers begin routing to the new upstream.

The previous slot remains running after a successful switch to provide a fast traffic rollback path.

## Failure Behavior

Inactive slot startup failure:

Production traffic remains on the active slot.

Inactive readiness failure:

Production traffic remains on the active slot.

Nginx configuration failure:

The traffic configuration is not activated.

Nginx reload failure:

The previous upstream configuration is restored.

Public validation failure:

Traffic is automatically switched back to the previous slot.

## Locking

Blue-green operations use the same host-level deployment lock as standard deployment and rollback operations.

This prevents simultaneous release mutations.

## Scope

This workflow provides zero-downtime-capable deployment on a single host using parallel application slots and graceful reverse-proxy switching.

It does not claim distributed blue-green orchestration across multiple hosts.