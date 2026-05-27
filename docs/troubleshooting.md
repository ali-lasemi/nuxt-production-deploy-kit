# Troubleshooting

Common production deployment issues and operational debugging steps.

---

# Port Already In Use

## Error

```txt
EADDRINUSE: address already in use
```

## Solution

Find the process:

```bash
sudo ss -tulnp | grep :3000
```

Kill the process if necessary:

```bash
sudo kill -9 <PID>
```

---

# Application Fails After Restart

Check logs:

```bash
journalctl -u nuxt-app -f
```

Validate environment variables and runtime paths.

---

# Reverse Proxy 502 Errors

Verify:

- Application is running
- Correct proxy port
- Firewall rules
- systemd service status

Example:

```bash
sudo systemctl status nuxt-app
```

---

# Permission Issues

Verify ownership:

```bash
sudo chown -R deploy:deploy /opt/nuxt-app
```

---

# SSL Problems

Validate reverse proxy configuration:

```bash
sudo nginx -t
```

or:

```bash
sudo apachectl configtest
```