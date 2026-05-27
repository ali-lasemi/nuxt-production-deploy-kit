# systemd Configuration

Production-oriented systemd service example for managing Nuxt applications.

---

## Features

- Automatic restart policies
- Environment variable support
- Production logging
- High file descriptor limits
- Dedicated service user

---

## Common Commands

Reload systemd:

```bash
sudo systemctl daemon-reload
```

Start service:

```bash
sudo systemctl start nuxt-app
```

Enable service:

```bash
sudo systemctl enable nuxt-app
```

View logs:

```bash
journalctl -u nuxt-app -f
```

---

## Notes

Production environments should use dedicated users, log rotation, healthchecks and rollback strategies.