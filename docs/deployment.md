# Deployment Workflow

This repository uses release-based deployments for Nuxt applications.

## Deployment Flow

1. Build the Nuxt application.
2. Package the production artifact.
3. Transfer the build archive to the server.
4. Extract the archive into a timestamped release directory.
5. Update the `current` symlink.
6. Restart the systemd application service.
7. Validate the systemd service state.
8. Validate the application through `127.0.0.1`.
9. Optionally validate the public endpoint.

## Release Layout

```text
/opt/nuxt-app/
├── current -> /opt/nuxt-app/releases/<release>
└── releases/
    ├── 20260811090000/
    ├── 20260811100000/
    └── 20260811110000/
```

## Deployment

```bash
./scripts/deploy.sh build.zip
```

## Configuration

```bash
APP_NAME=nuxt-app \
APP_PORT=3000 \
HEALTH_PATH=/ \
./scripts/deploy.sh build.zip
```

## Optional Public Validation

```bash
APP_NAME=nuxt-app \
APP_PORT=3000 \
HEALTH_PATH=/ \
PUBLIC_URL=https://example.com \
./scripts/deploy.sh build.zip
```

## Validation Variables

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

## Defaults

```text
APP_NAME=nuxt-app
APP_PORT=3000
HEALTH_PATH=/
EXPECTED_STATUS=200
TIMEOUT_SECONDS=10
HEALTH_RETRIES=5
HEALTH_RETRY_DELAY=2
```

## Manual Validation

```bash
APP_NAME=nuxt-app \
APP_PORT=3000 \
HEALTH_PATH=/ \
./scripts/validate-deployment.sh
```

## Production Rules

- Keep previous releases available for rollback.
- Use a dedicated deployment user.
- Do not deploy directly into the active runtime directory.
- Validate the local application before validating the public path.
- Treat validation failure as deployment failure.
- Automatic rollback is handled separately.
