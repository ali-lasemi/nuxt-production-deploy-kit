# systemd Security Hardening

The production systemd example runs the Nuxt application with a dedicated unprivileged service account and a restricted execution environment.

## Runtime Identity

The service runs as:

User=deploy
Group=deploy

The application does not require root privileges.

The default file-creation mask is:

UMask=0027

This prevents newly created files from being globally readable or writable.

## Release Path

The service starts the application from:

/opt/nuxt-app/current

The `current` path is the release symlink controlled by the deployment and rollback workflows.

This keeps systemd aligned with the release-based deployment architecture.

## Network Exposure

The example sets:

HOST=127.0.0.1
PORT=3000

The Nuxt process therefore listens on loopback by default.

Nginx or Apache is expected to be the public traffic boundary.

## Restart Policy

The service uses:

Restart=on-failure

This avoids restarting the application after intentional clean shutdowns while still recovering from unexpected process failures.

## Privilege Restrictions

The unit enables:

NoNewPrivileges=yes
CapabilityBoundingSet=
AmbientCapabilities=

The application cannot gain additional privileges and receives no Linux capabilities.

## Filesystem Protection

The unit enables:

ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes

The service receives a read-only view of the system filesystem except for explicitly allowed writable paths.

The log directory remains writable through:

ReadWritePaths=/var/log/nuxt-app

## Kernel and Host Protection

The unit restricts access to sensitive host and kernel interfaces with:

ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectKernelLogs=yes
ProtectControlGroups=yes
ProtectClock=yes
ProtectHostname=yes

## Process Restrictions

The unit enables:

RestrictSUIDSGID=yes
RestrictRealtime=yes
LockPersonality=yes
RestrictNamespaces=yes
SystemCallArchitectures=native

These controls reduce unnecessary process capabilities available to the Node.js runtime.

## Network Families

The service is limited to:

AF_UNIX
AF_INET
AF_INET6

This allows ordinary local and IP networking without exposing unrelated socket families.

## Environment File

The service can optionally read:

/etc/nuxt-app/nuxt-app.env

through:

EnvironmentFile=-/etc/nuxt-app/nuxt-app.env

The leading minus means the service can still start when the file does not exist.

Sensitive values should not be committed to the repository.

## CI Validation

GitHub Actions validates the unit in two ways.

First:

systemd-analyze verify examples/systemd/nuxt-app.service

Second:

tests/config/systemd-hardening.sh

The hardening policy test ensures required security directives cannot be accidentally removed without failing CI.

## Compatibility

The hardening profile intentionally avoids MemoryDenyWriteExecute because Node.js and the V8 JavaScript engine may require executable memory for JIT compilation.

The profile focuses on restrictions that are useful for a typical production Nuxt runtime without pretending that every possible systemd sandboxing option is universally safe.