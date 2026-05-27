# Nginx Reverse Proxy

Production-oriented Nginx reverse proxy example for Nuxt applications.

---

## Features

- Reverse proxy to local Nuxt runtime
- Forwarded headers
- WebSocket upgrade support
- Static asset caching
- Separate access and error logs
- Timeout configuration

---

## Example

```nginx
proxy_pass http://127.0.0.1:3000;
```

---

## Install Config

Copy the config:

```bash
sudo cp examples/nginx/nuxt.conf /etc/nginx/sites-available/nuxt-app
```

Enable it:

```bash
sudo ln -s /etc/nginx/sites-available/nuxt-app /etc/nginx/sites-enabled/
```

Test config:

```bash
sudo nginx -t
```

Reload Nginx:

```bash
sudo systemctl reload nginx
```

---

## Notes

Replace `example.com` with the real domain.

For HTTPS, use Certbot or your preferred certificate management tool.