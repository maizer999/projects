# Mazier Daily — daily-feeds

Auto-updating digest site with three pages (Bento design, light & dark mode, Arabic RTL):

| Page | Path | Sources |
|---|---|---|
| Home | `/` | Summary + latest 3 items from each section |
| Tech news — آخر أخبار التقنية | `/tech/` | AITNews, Tech-WD, Engadget, TechCrunch, The Verge |
| Recipes — طبخات | `/recipes/` | RecipeTin Eats, Budget Bytes, Pinch of Yum |
| Healthy food — أكلات صحية | `/healthy/` | Skinnytaste, Well Plated, Love & Lemons, Downshiftology |

`daily_feeds.py` (Python 3, standard library only) reads the RSS feeds, finds an image for each item
(falls back to the article's `og:image`), keeps the last 14 days (max 120 items per page), and writes static HTML.
Each page has source filter chips, search, a featured item, a latest-headlines timeline and a full grid.
A feed that fails is skipped; the run continues.

## Files

| File | Purpose |
|---|---|
| `install.sh` | One-shot installer. Contains `daily_feeds.py` embedded — this is the only file the server needs. |
| `daily_feeds.py` | Same script, standalone, for reading/editing. If you edit it, rebuild `install.sh` (or copy it to `/opt/daily-feeds/` on the server). |
| `README.md` | This file. |

## Target

- **Server:** OCI VM `mazier-vm` (Ubuntu 24.04, Ampere ARM), public IP `84.13.129.117`
- **Subdomain:** `daily.mazier.website`

## 1. DNS record (Namecheap)

Namecheap → Domain List → `mazier.website` → **Advanced DNS** → Add New Record:

| Type | Host | Value | TTL |
|---|---|---|---|
| A Record | `daily` | `84.13.129.117` | Automatic |

Wait until `dig +short daily.mazier.website` returns `84.13.129.117` (usually a few minutes).

Also make sure the OCI Security List allows TCP **80** and **443** from `0.0.0.0/0` (the installer opens them inside Ubuntu).

## 2. Install

From the Mac (SSH is blocked on the company network — do this from home):

```bash
cd ~/Documents/mazier-deploy/daily-feeds
scp install.sh ubuntu@84.13.129.117:
ssh ubuntu@84.13.129.117
sudo DOMAIN=daily.mazier.website EMAIL=you@example.com bash install.sh
```

Optional variables: `RUN_AT=06:00` (daily time, Asia/Amman). Safe to re-run (e.g. to issue SSL after DNS propagates, or to update the script).

What the installer does:
1. Installs `python3`, `nginx`, `certbot`, `python3-certbot-nginx`, `dnsutils`
2. Opens ports 80/443 in iptables (Oracle images block them by default)
3. Writes the script to `/opt/daily-feeds/daily_feeds.py` and an editable `/opt/daily-feeds/feeds.json`
4. Creates the Nginx site `/etc/nginx/sites-available/daily` → web root `/var/www/daily`
5. Creates the systemd service + timer `daily-feeds`
6. Runs the first update immediately
7. Issues a Let's Encrypt certificate with HTTP→HTTPS redirect — only if the DNS already points to this server

## 3. Daily update schedule

- **Every day at 06:00 Asia/Amman** via `daily-feeds.timer` (`OnCalendar=*-*-* 06:00:00 Asia/Amman`, up to 3 min random delay)
- `Persistent=true`: if the VM was off at 06:00, it runs as soon as it boots

## Useful commands (on the server)

```bash
sudo systemctl start daily-feeds              # update now
journalctl -u daily-feeds -n 50               # last run log
systemctl list-timers daily-feeds.timer       # next scheduled run
sudo nano /opt/daily-feeds/feeds.json         # add/remove sources (no code change needed)
sudo -u www-data python3 /opt/daily-feeds/daily_feeds.py --only tech   # one section only
```

## Paths on the server

| Path | Content |
|---|---|
| `/opt/daily-feeds/daily_feeds.py` | Script |
| `/opt/daily-feeds/feeds.json` | Sources and page titles (kept on re-install) |
| `/opt/daily-feeds/data/*.json` | 14-day history per section |
| `/var/www/daily/` | Generated site (`index.html`, `tech/`, `recipes/`, `healthy/`, each with `feed.json`) |
