# Baytoti API — deploy runbook

Target: Oracle Always-Free ARM VM, Ubuntu 24.04, no CloudPanel.
Flow: SSH in, install packages, drop in files, point DNS, get SSL.

Everything runs as `ubuntu` with `sudo`. Replace `<PUBLIC_IP>` with your VM's
public IP from the Oracle Console.

---

## 0 · DNS + Oracle Security List (do these first)

**Namecheap → mazier.website → Advanced DNS.** Add:

| Type | Host | Value           | TTL       |
|------|------|-----------------|-----------|
| A    | api  | `<PUBLIC_IP>`   | Automatic |

(Keep `@` and `www` as they are.)

**Oracle Console → Networking → VCN → Security List → Ingress Rules.**
Make sure these are present (source `0.0.0.0/0`, TCP):

- 22   (SSH)
- 80   (HTTP — needed for Let's Encrypt HTTP-01 challenge)
- 443  (HTTPS)

---

## 1 · Confirm you're on the right VM

```bash
ssh -i ~/Downloads/ssh-key-2026-11-11.key ubuntu@<PUBLIC_IP>

# Sanity: does this box match the DNS record?
curl -s ifconfig.me ; echo
dig +short api.mazier.website

# These two should print the same IP after DNS propagates (5–30 min).
```

If they differ, fix the A record first — SSL will fail otherwise.

---

## 2 · Install packages

```bash
sudo apt update
sudo apt install -y nginx mariadb-server \
    php8.3-fpm php8.3-mysql php8.3-mbstring \
    certbot python3-certbot-nginx

sudo systemctl enable --now nginx php8.3-fpm mariadb
```

Lock down MariaDB:

```bash
sudo mysql_secure_installation
# Use unix_socket auth for root: Yes
# Remove anonymous users: Yes
# Disallow remote root: Yes
# Remove test DB: Yes
# Reload: Yes
```

---

## 3 · Create DB + app user

```bash
sudo mariadb <<'SQL'
CREATE DATABASE IF NOT EXISTS baytoti
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'baytoti_app'@'localhost'
  IDENTIFIED BY 'REPLACE_WITH_STRONG_PASSWORD';

GRANT SELECT, INSERT, UPDATE, DELETE
  ON baytoti.* TO 'baytoti_app'@'localhost';

FLUSH PRIVILEGES;
SQL
```

Load the schema (upload `schema.sql` from this folder first — see step 4):

```bash
sudo mariadb baytoti < /var/www/baytoti-api/schema.sql
```

---

## 4 · Deploy the API files

From your Mac, in this repo:

```bash
scp -i ~/Downloads/ssh-key-2026-11-11.key \
  "projects/baytoti-flutter/backend/index.php" \
  "projects/baytoti-flutter/backend/config.example.php" \
  "projects/baytoti-flutter/backend/schema.sql" \
  ubuntu@<PUBLIC_IP>:/tmp/
```

On the VM:

```bash
sudo mkdir -p /var/www/baytoti-api
sudo mv /tmp/index.php /tmp/schema.sql /var/www/baytoti-api/
sudo mv /tmp/config.example.php /var/www/baytoti-api/config.php

# Set the DB password you just created in step 3:
sudo nano /var/www/baytoti-api/config.php

sudo chown -R www-data:www-data /var/www/baytoti-api
sudo chmod 640 /var/www/baytoti-api/config.php

# Now load the schema (step 3 above referenced this file).
sudo mariadb baytoti < /var/www/baytoti-api/schema.sql
```

---

## 5 · Nginx vhost

Upload the vhost from your Mac:

```bash
scp -i ~/Downloads/ssh-key-2026-11-11.key \
  "projects/baytoti-flutter/backend/nginx.api.mazier.website.conf" \
  ubuntu@<PUBLIC_IP>:/tmp/
```

On the VM:

```bash
sudo mv /tmp/nginx.api.mazier.website.conf \
        /etc/nginx/sites-available/api.mazier.website
sudo ln -sf /etc/nginx/sites-available/api.mazier.website \
            /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

**Smoke test (HTTP only, pre-SSL):**

```bash
curl -s http://api.mazier.website/health
# → {"ok":true,"time":"..."}
```

If that works, SSL is next. If not, check:
- `sudo tail -n 50 /var/log/nginx/api.mazier.website.error.log`
- DNS: `dig +short api.mazier.website` should equal your VM's IP.

---

## 6 · SSL via Let's Encrypt

```bash
sudo certbot --nginx -d api.mazier.website
# Pick redirect HTTP → HTTPS when asked.
```

Verify:

```bash
curl -s https://api.mazier.website/health
```

---

## 7 · End-to-end smoke test

```bash
# Create a list
curl -s -X POST https://api.mazier.website/lists \
  -H 'Content-Type: application/json' \
  -d '{"name":"بيت العائلة","ownerName":"محمد"}'
# → {"id":"...", "inviteCode":"...", ...}

LIST_ID=aB3xK9pL4q  # paste the id from above
CODE=7HJ4KM         # paste the inviteCode

# Join from "another device"
curl -s -X POST "https://api.mazier.website/lists/$LIST_ID/join" \
  -H 'Content-Type: application/json' \
  -d '{"name":"نجوى"}'

# Add a purchase
curl -s -X POST "https://api.mazier.website/lists/$LIST_ID/purchases" \
  -H 'Content-Type: application/json' \
  -d '{"itemName":"خبز","price":1.5,"category":"food","addedByName":"محمد","date":"2026-11-19T18:00:00Z"}'

# List purchases
curl -s "https://api.mazier.website/lists/$LIST_ID/purchases" | jq
```

If all four return clean JSON, the backend is done.

---

## 8 · Where logs live

```bash
sudo tail -f /var/log/nginx/api.mazier.website.access.log
sudo tail -f /var/log/nginx/api.mazier.website.error.log
sudo journalctl -u php8.3-fpm -f    # PHP fatals end up here
```

---

## Clean-up (if you want to remove the half-done Node attempt from screenshots)

```bash
sudo systemctl disable --now mazier-api.service 2>/dev/null
sudo rm -f /etc/systemd/system/mazier-api.service
sudo rm -f /etc/nginx/sites-enabled/default
# only remove 'default' if nothing else is using it — check with:
ls -la /etc/nginx/sites-enabled/
```
