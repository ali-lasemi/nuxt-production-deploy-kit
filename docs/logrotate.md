# Log Rotation

Production systems should rotate application logs to prevent disk usage issues.

---

## Example Logrotate Config

Create a file:

```bash
sudo nano /etc/logrotate.d/nuxt-app
```

Example:

```conf
/var/log/nuxt-app/*.log {
    daily
    rotate 14
    compress
    missingok
    notifempty
    copytruncate
    create 0640 deploy deploy
}
```

---

## Force Test

```bash
sudo logrotate -f /etc/logrotate.d/nuxt-app
```

---

## Notes

Use log rotation for:

- Application stdout logs
- Application error logs
- Reverse proxy logs
- Deployment logs