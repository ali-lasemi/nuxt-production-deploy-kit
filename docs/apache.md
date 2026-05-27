# Apache Reverse Proxy

Production-oriented Apache reverse proxy example for Nuxt applications.

---

## Required Modules

```bash
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod headers
sudo a2enmod rewrite
```

---

## Install Config

Copy the virtual host config:

```bash
sudo cp examples/apache/nuxt-vhost.conf /etc/apache2/sites-available/nuxt-app.conf
```

Enable the site:

```bash
sudo a2ensite nuxt-app.conf
```

Test Apache config:

```bash
sudo apachectl configtest
```

Reload Apache:

```bash
sudo systemctl reload apache2
```

---

## Notes

Replace `example.com` with the real domain.

For HTTPS, use Certbot or your preferred certificate management tool.