# Deployment User and Filesystem Security

The deployment model uses a dedicated unprivileged account.

## Identity

Default identity:

deploy:deploy

The account is intended for deployment automation and application runtime ownership.

It should not be used as a general administrator account.

The bootstrap script creates the account as a system user with:

/usr/sbin/nologin

This prevents ordinary interactive shell login by default.

## Host Bootstrap

Run as root:

sudo ./scripts/bootstrap-host.sh

The script creates and normalizes:

/opt/nuxt-app
/opt/nuxt-app/releases
/var/log/nuxt-app
/etc/nuxt-app
/opt/nuxt-app/.deployment.lock

## Ownership

Application and release data:

deploy:deploy

Application logs:

deploy:deploy

Configuration directory:

root:deploy

The configuration directory is intentionally root-owned so the application identity cannot replace host-level configuration.

## Directory Modes

Application directory:

0750

Release directory:

0750

Log directory:

0750

Configuration directory:

0750

Release subdirectories:

0750

These modes prevent access by unrelated local users.

## File Modes

Release files:

0640

Deployment lock:

0640

The systemd service also uses:

UMask=0027

This keeps runtime-created files private to the owning user and group unless explicitly configured otherwise.

## sudo Policy

The deployment workflow needs privileged access only for restarting the application service.

Example policy:

examples/sudoers/nuxt-app-deploy

The deployment user receives passwordless permission only for:

systemctl restart nuxt-app.service
systemctl restart nuxt-app

The policy does not grant:

NOPASSWD: ALL
shell access
package management
arbitrary systemctl commands
filesystem administration

## sudoers Installation

Always validate first:

sudo visudo -cf examples/sudoers/nuxt-app-deploy

Then install:

sudo install -o root -g root -m 0440 examples/sudoers/nuxt-app-deploy /etc/sudoers.d/nuxt-app-deploy

Validate the installed policy:

sudo visudo -cf /etc/sudoers.d/nuxt-app-deploy

## Deployment Automation

Deployment automation should execute deploy.sh as the deploy user.

The deploy user owns the application release tree and therefore does not require sudo for:

creating release directories
extracting build artifacts
updating the current symlink
writing release metadata
using the deployment lock

sudo is used only when restarting the protected systemd service.

## Secrets

Secrets should not be stored inside release directories.

The recommended host-level environment location is:

/etc/nuxt-app/nuxt-app.env

The systemd unit reads that path with EnvironmentFile.

Secret-management policy is documented separately from filesystem ownership.

## CI Validation

CI validates:

sudoers syntax with visudo
absence of NOPASSWD: ALL
absence of shell grants
deployment-user policy
filesystem mode policy
systemd identity alignment

This ensures future repository changes cannot silently broaden deployment privileges.