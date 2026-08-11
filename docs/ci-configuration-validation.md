# Production Configuration Validation

GitHub Actions validates the production configuration examples with the native tools that would parse them on a Linux host.

## Nginx

The Nginx example is installed into a temporary CI configuration and validated with:

nginx -t

Validated file:

examples/nginx/nuxt.conf

A syntax or configuration error fails CI.

## Apache

The Apache virtual host is installed into the CI Apache configuration.

Required modules are enabled:

proxy
proxy_http
headers

The configuration is validated with:

apache2ctl configtest

Validated file:

examples/apache/nuxt-vhost.conf

A syntax or module-related configuration error fails CI.

## systemd

The systemd service example is validated with:

systemd-analyze verify

Validated file:

examples/systemd/nuxt-app.service

The validation confirms that systemd can parse the unit and its directives.

## Scope

These checks validate configuration syntax and parser compatibility.

They do not claim to perform a live production deployment, external network test, TLS validation, or real process startup.

Runtime deployment behavior is covered separately by the deployment and rollback integration tests.