# Docker Production Deployment

The Docker example provides an alternative runtime model to the primary systemd deployment workflow.

## Runtime Security

The production image:

- uses a multi-stage build
- copies only the Nuxt output into the runtime image
- runs with NODE_ENV=production
- runs as the built-in non-root node user
- exposes only the application port
- includes a container-native healthcheck

## Compose Hardening

The Compose example applies:

- loopback-only host port binding
- read-only root filesystem
- temporary writable /tmp filesystem
- no-new-privileges
- all Linux capabilities dropped
- PID limit
- init process
- explicit stop grace period
- application healthcheck

The default port mapping is:

127.0.0.1:3000:3000

This is intended for deployments where Nginx or Apache on the host acts as the public traffic boundary.

## Build

From a Nuxt application directory:

docker build -f Dockerfile -t nuxt-app:local .

## Compose

Validate configuration:

docker compose config

Start:

docker compose up -d

Inspect health:

docker compose ps

Stop:

docker compose down

## CI Build Validation

The repository contains a deterministic fixture under:

tests/fixtures/docker-app

GitHub Actions builds the production Dockerfile against this fixture.

The fixture does not pretend to be a real Nuxt project. Its purpose is to verify that the Dockerfile:

- parses successfully
- completes both build stages
- produces a runnable Node.js runtime image
- respects the production runtime structure expected by the Dockerfile

CI also validates the Compose file with:

docker compose config

## Scope

Docker is an alternative deployment strategy in this repository.

It is not combined with the release-directory and systemd workflow.