# Secret Management

Production secrets must not be stored in the repository or inside release directories.

The systemd deployment model uses a host-managed environment file.

## Secret File Location

Recommended path:

/etc/nuxt-app/nuxt-app.env

The systemd unit references this file with:

EnvironmentFile=-/etc/nuxt-app/nuxt-app.env

## Ownership

Recommended ownership:

root:deploy

The deployment and application user can read the file through group membership but cannot replace or modify it.

## Permissions

Recommended mode:

0640

Apply with:

sudo chown root:deploy /etc/nuxt-app/nuxt-app.env
sudo chmod 0640 /etc/nuxt-app/nuxt-app.env

The parent directory should remain:

root:deploy
0750

## Example

The repository may contain configuration examples, but examples must never contain working credentials.

Safe:

DATABASE_URL=
API_TOKEN=
SESSION_SECRET=

Unsafe:

DATABASE_URL=postgres://production-user:real-password@database
API_TOKEN=live-production-token
SESSION_SECRET=real-secret-value

## Deployment Separation

Release archives must contain application code and non-sensitive runtime assets only.

Secrets are not copied into:

/opt/nuxt-app/releases

This keeps credentials independent from:

release creation
release cleanup
rollback
artifact storage
release metadata

## Rotation

To rotate a secret:

1. Update /etc/nuxt-app/nuxt-app.env securely.
2. Preserve root:deploy ownership.
3. Preserve mode 0640.
4. Validate the file permissions.
5. Restart the application service.
6. Run post-deployment validation.

Example:

sudo ./scripts/validate-secret-file.sh /etc/nuxt-app/nuxt-app.env
sudo systemctl restart nuxt-app
APP_NAME=nuxt-app APP_PORT=3000 HEALTH_PATH=/ ./scripts/validate-deployment.sh

## Validation

The repository includes:

scripts/validate-secret-file.sh

Default policy:

owner = root
group = deploy
mode = 0640

Example:

sudo ./scripts/validate-secret-file.sh /etc/nuxt-app/nuxt-app.env

## CI Protection

CI validates that:

- .env files are ignored
- only the approved environment example is tracked
- the systemd unit references the host secret file
- documentation defines secure ownership and permissions
- example configuration does not contain secret-looking values

## External Secret Managers

For larger environments, replace the host environment file with a secret delivery mechanism appropriate to the platform.

Examples include:

- HashiCorp Vault
- AWS Secrets Manager
- Azure Key Vault
- Google Secret Manager
- SOPS with an external key provider

This repository does not pretend to implement those external systems.

The security requirement remains the same:

Secrets must be injected at runtime and must not be committed to Git.