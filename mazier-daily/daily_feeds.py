#!/usr/bin/env python3
"""
Mazier Daily — يجمع آخر أخبار التقنية، الطبخات، والأكلات الصحية من RSS
ويبني صفحات HTML ثابتة بتصميم عصري.

Python 3 stdlib only (no pip needed).

Usage:
  python3 daily_feeds.py                 # all categories
  python3 daily_feeds.py --only tech     # one category (tech | recipes | healthy)
  python3 daily_feeds.py --out /var/www/daily --data /opt/daily-feeds/data
"""
import argparse
import concurrent.futures as cf
import datetime as dt
import email.utils
import html
import json
import os
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UA = ("Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36 MazierDaily/1.0")
TIMEOUT = 15
PER_FEED = 12          # items taken from each feed per run
OG_LOOKUPS = 8         # max article pages fetched per feed to find a missing image
KEEP_DAYS = 14         # history kept per category
MAX_ITEMS = 120        # max items shown per page

# ---------------------------------------------------------------- config
DEFAULT_CONFIG = {
    "site_title": "Mazier Daily",
    "categories": {
        "tech": {
            "title": "آخر أخبار التقنية",
            "short": "تقنية",
            "emoji": "💻",
            "desc": "أهم أخبار التقنية والذكاء الاصطناعي والأجهزة من مصادر عربية وعالمية",
            "accent": ["#6366f1", "#22d3ee"],
            "feeds": [
                {"name": "البوابة التقنية", "url": "https://aitnews.com/feed/"},
                {"name": "عالم التقنية", "url": "https://www.tech-wd.com/wd/feed/"},
                {"name": "Engadget", "url": "https://www.engadget.com/rss.xml"},
                {"name": "TechCrunch", "url": "https://techcrunch.com/feed/"},
                {"name": "The Verge", "url": "https://www.theverge.com/rss/index.xml"},
            ],
        },
        "recipes": {
            "title": "طبخات اليوم",
            "short": "طبخات",
            "emoji": "🍳",
            "desc": "وصفات جديدة كل يوم — أطباق رئيسية، مقبلات وحلويات",
            "accent": ["#f97316", "#ef4444"],
            "feeds": [
                {"name": "RecipeTin Eats", "url": "https://www.recipetineats.com/feed/"},
                {"name": "Budget Bytes", "url": "https://www.budgetbytes.com/feed/"},
                {"name": "Pinch of Yum", "url": "https://pinchofyum.com/feed"},
            ],
        },
        "healthy": {
            "title": "أكلات صحية",
            "short": "صحي",
            "emoji": "🥗",
            "desc": "وصفات صحية وخفيفة وخطط وجبات غنية بالبروتين",
            "accent": ["#22c55e", "#a3e635"],
            "feeds": [
                {"name": "Skinnytaste", "url": "https://www.skinnytaste.com/feed/"},
                {"name": "Well Plated", "url": "https://www.wellplated.com/feed/"},
                {"name": "Love & Lemons", "url": "https://www.loveandlemons.com/feed/"},
                {"name": "Downshiftology", "url": "https://downshiftology.com/feed/"},
            ],
        },
    },
}


def load_config():
    path = os.path.join(BASE_DIR, "feeds.json")
    if os.path.exists(path):
        try:
            with open(path, encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            log(f"!! feeds.json invalid ({e}); using built-in defaults")
    return DEFAULT_CONFIG


def log(msg):
    print(f"[{dt.datetime.now():%Y-%m-%d %H:%M:%S}] {msg}", flush=True)


# ---------------------------------------------------------------- fetching
def fetch(url, limit=3_000_000):
    req = urllib.request.Request(url, headers={
        "User-Agent": UA,
        "Accept": "application/rss+xml, application/atom+xml, application/xml, text/xml, text/html;q=0.8, */*;q=0.5",
        "Accept-Language": "ar,en;q=0.8",
    })
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        return r.read(limit)


NS = {
    "atom": "http://www.w3.org/2005/Atom",
    "media": "http://search.yahoo.com/mrss/",
    "content": "http://purl.org/rss/1.0/modules/content/",
    "dc": "http://purl.org/dc/elements/1.1/",
}
IMG_RE = re.compile(r"<img[^>]+?(?:data-lazy-src|data-src|src)=[\"']([^\"']+)[\"']", re.I)
OG_RE = re.compile(
    r"<meta[^>]+(?:property|name)=[\"'](?:og:image|twitter:image)(?::src)?[\"'][^>]*content=[\"']([^\"']+)[\"']"
    r"|<meta[^>]+content=[\"']([^\"']+)[\"'][^>]*(?:property|name)=[\"'](?:og:image|twitter:image)[\"']", re.I)
TAG_RE = re.compile(r"<[^>]+>")
WS_RE = re.compile(r"\s+")
APPEARED_RE = re.compile(r"The post .*? appeared first on .*?\.?$", re.I)


def clean_text(s, n=240):
    if not s:
        return ""
    s = html.unescape(TAG_RE.sub(" ", s))
    s = APPEARED_RE.sub("", WS_RE.sub(" ", s)).strip()
    s = s.replace("[…]", "…").replace("[...]", "…")
    return (s[: n - 1].rsplit(" ", 1)[0] + "…") if len(s) > n else s


def parse_date(s):
    if not s:
        return None
    s = s.strip()
    try:
        d = email.utils.parsedate_to_datetime(s)
    except Exception:
        d = None
    if d is None:
        try:
            d = dt.datetime.fromisoformat(s.replace("Z", "+00:00"))
        except Exception:
            return None
    if d.tzinfo is None:
        d = d.replace(tzinfo=dt.timezone.utc)
    return d.astimezone(dt.timezone.utc)


def good_img(u):
    if not u:
        return None
    u = html.unescape(u.strip())
    if u.startswith("//"):
        u = "https:" + u
    if not u.startswith("http"):
        return None
    low = u.lower()
    if any(x in low for x in ("gravatar", "pixel", "feeds.feedburner", "1x1", "emoji", "/smilies/")):
        return None
    return u


def find_image(el, *html_blobs):
    for m in el.findall("media:content", NS) + el.findall("media:group/media:content", NS):
        t = (m.get("type") or "") + (m.get("medium") or "")
        if ("image" in t or not t) and good_img(m.get("url")):
            return good_img(m.get("url"))
    for m in el.findall("media:thumbnail", NS) + el.findall("media:group/media:thumbnail", NS):
        if good_img(m.get("url")):
            return good_img(m.get("url"))
    for enc in el.findall("enclosure"):
        if "image" in (enc.get("type") or "") and good_img(enc.get("url")):
            return good_img(enc.get("url"))
    for blob in html_blobs:
        if blob:
            for m in IMG_RE.finditer(blob):
                if good_img(m.group(1)):
                    return good_img(m.group(1))
    return None


def txt(el, path):
    x = el.find(path, NS)
    return (x.text or "").strip() if x is not None and x.text else ""


def parse_feed(raw, source):
    root = ET.fromstring(raw)
    items = []
    if root.tag.endswith("rss") or root.find("channel") is not None:
        for it in root.iter("item"):
            content = txt(it, "content:encoded")
            desc = txt(it, "description")
            items.append({
                "title": clean_text(txt(it, "title"), 200),
                "link": txt(it, "link") or txt(it, "guid"),
                "summary": clean_text(desc or content),
                "image": find_image(it, content, desc),
                "date": parse_date(txt(it, "pubDate") or txt(it, "dc:date")),
            })
    else:  # Atom
        for en in root.findall("atom:entry", NS):
            link = ""
            for l in en.findall("atom:link", NS):
                if l.get("rel") in (None, "alternate"):
                    link = l.get("href", "")
                    break
            content = txt(en, "atom:content")
            summ = txt(en, "atom:summary")
            items.append({
                "title": clean_text(txt(en, "atom:title"), 200),
                "link": link,
                "summary": clean_text(summ or content),
                "image": find_image(en, content, summ),
                "date": parse_date(txt(en, "atom:published") or txt(en, "atom:updated")),
            })
    out = []
    for i in items[:PER_FEED]:
        if i["title"] and i["link"].startswith("http"):
            i["source"] = source
            out.append(i)
    return out


def og_image(url):
    try:
        page = fetch(url, limit=400_000).decode("utf-8", "ignore")
        m = OG_RE.search(page)
        if m:
            return good_img(m.group(1) or m.group(2))
    except Exception:
        pass
    return None


def fetch_feed(feed):
    name, url = feed["name"], feed["url"]
    try:
        items = parse_feed(fetch(url), name)
    except Exception as e:
        log(f"   ✗ {name}: {e}")
        return []
    missing = [i for i in items if not i["image"]][:OG_LOOKUPS]
    if missing:
        with cf.ThreadPoolExecutor(6) as ex:
            for i, img in zip(missing, ex.map(lambda x: og_image(x["link"]), missing)):
                i["image"] = img
    log(f"   ✓ {name}: {len(items)} items")
    return items


# ---------------------------------------------------------------- history
def merge(cat_key, fresh, data_dir):
    path = os.path.join(data_dir, f"{cat_key}.json")
    old = []
    if os.path.exists(path):
        try:
            with open(path, encoding="utf-8") as f:
                old = json.load(f)
        except Exception:
            old = []
    now = dt.datetime.now(dt.timezone.utc)
    by_link = {o["link"]: o for o in old}
    for i in fresh:
        prev = by_link.get(i["link"], {})
        date = i["date"] or (parse_date(prev.get("date")) if prev.get("date") else None) or now
        by_link[i["link"]] = {
            "title": i["title"],
            "link": i["link"],
            "summary": i["summary"],
            "image": i["image"] or prev.get("image"),
            "source": i["source"],
            "date": min(date, now).isoformat(),
            "seen": prev.get("seen") or now.isoformat(),
        }
    cutoff = now - dt.timedelta(days=KEEP_DAYS)
    items = [x for x in by_link.values() if parse_date(x["date"]) >= cutoff]
    items.sort(key=lambda x: x["date"], reverse=True)
    items = items[:MAX_ITEMS]
    write_atomic(path, json.dumps(items, ensure_ascii=False, indent=1))
    return items


def write_atomic(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
    os.replace(tmp, path)


# ---------------------------------------------------------------- rendering
def js_json(obj):
    return json.dumps(obj, ensure_ascii=False).replace("</", "<\\/")


def nav_html(cfg, active):
    links = [f'<a href="/" class="{"on" if active == "home" else ""}">🏠 <span>الرئيسية</span></a>']
    for k, c in cfg["categories"].items():
        on = "on" if k == active else ""
        links.append(f'<a href="/{k}/" class="{on}">{c["emoji"]} <span>{html.escape(c["short"])}</span></a>')
    return "\n".join(links)


def render_category(cfg, key, items, updated):
    c = cfg["categories"][key]
    sources = sorted({i["source"] for i in items})
    page = PAGE_TEMPLATE
    rep = {
        "__SITE__": html.escape(cfg.get("site_title", "Mazier Daily")),
        "__TITLE__": html.escape(c["title"]),
        "__DESC__": html.escape(c["desc"]),
        "__EMOJI__": c["emoji"],
        "__A1__": c["accent"][0],
        "__A2__": c["accent"][1],
        "__NAV__": nav_html(cfg, key),
        "__SHORT__": html.escape(c["short"]),
        "__ICON_SRC__": ICONS["src"],
        "__ICONS__": js_json({k: ICONS[k] for k in ("spark", "clock", "grid")}),
        "__DATA__": js_json({"items": items, "sources": sources, "updated": updated, "emoji": c["emoji"]}),
    }
    for k, v in rep.items():
        page = page.replace(k, v)
    return page


def render_home(cfg, all_items, updated):
    cards, stats = [], []
    for k, c in cfg["categories"].items():
        items = all_items.get(k, [])
        cover = next((i["image"] for i in items if i.get("image")), "")
        img = (f'<img src="{html.escape(cover, quote=True)}" alt="" loading="lazy" '
               f'referrerpolicy="no-referrer" onerror="this.remove()">') if cover else ""
        tl = "".join(
            f'<li><i></i><div><b dir="auto">{html.escape(i["title"])}</b>'
            f'<small>{html.escape(i["source"])}</small></div></li>' for i in items[:3])
        cards.append(f'''
<a class="card cat" href="/{k}/">
  <div class="lbl">{ICONS.get(k, ICONS["spark"])}<span>{html.escape(c["short"])}</span><em class="hint">{len(items)} عنصر</em></div>
  <div class="ph">{c["emoji"]}{img}</div>
  <h2>{html.escape(c["title"])}</h2>
  <p class="desc">{html.escape(c["desc"])}</p>
  <ul class="tl">{tl}</ul>
  <span class="btn-navy">تصفّح {html.escape(c["short"])} ←</span>
</a>''')
        stats.append(f'<li><i></i><div><b>{html.escape(c["title"])}</b>'
                     f'<small>{len(items)} عنصر · {sum(1 for i in items if _is_today(i))} جديد اليوم</small></div></li>')
    page = HOME_TEMPLATE
    for k, v in {
        "__SITE__": html.escape(cfg.get("site_title", "Mazier Daily")),
        "__NAV__": nav_html(cfg, "home"),
        "__CARDS__": "\n".join(cards),
        "__STATS__": "\n".join(stats),
        "__ICON_SPARK__": ICONS["spark"],
        "__ICON_CLOCK__": ICONS["clock"],
        "__UPDATED__": js_json(updated),
    }.items():
        page = page.replace(k, v)
    return page


def _is_today(i):
    try:
        return dt.datetime.now(dt.timezone.utc) - parse_date(i["date"]) < dt.timedelta(days=1)
    except Exception:
        return False


def load_saved(key, data_dir):
    p = os.path.join(data_dir, f"{key}.json")
    try:
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return []


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.environ.get("DAILY_OUT", "/var/www/daily"))
    ap.add_argument("--data", default=os.environ.get("DAILY_DATA", os.path.join(BASE_DIR, "data")))
    ap.add_argument("--only", choices=["tech", "recipes", "healthy"], help="update one category only")
    args = ap.parse_args()

    cfg = load_config()
    updated = dt.datetime.now(dt.timezone.utc).isoformat()
    all_items = {}
    for key, c in cfg["categories"].items():
        if args.only and key != args.only:
            all_items[key] = load_saved(key, args.data)
            continue
        log(f"▶ {c['title']} ({key})")
        fresh = []
        with cf.ThreadPoolExecutor(4) as ex:
            for res in ex.map(fetch_feed, c["feeds"]):
                fresh.extend(res)
        items = merge(key, fresh, args.data)
        all_items[key] = items
        write_atomic(os.path.join(args.out, key, "index.html"), render_category(cfg, key, items, updated))
        write_atomic(os.path.join(args.out, key, "feed.json"), js_json(items))
        log(f"  → {len(items)} items written to {args.out}/{key}/")
    write_atomic(os.path.join(args.out, "index.html"), render_home(cfg, all_items, updated))
    log("✔ done")
    return 0


# ---------------------------------------------------------------- templates
def _svg(p):
    return ('<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" '
            'stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' + p + '</svg>')


ICONS = {
    "tech": _svg('<rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/>'
                 '<path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/>'),
    "recipes": _svg('<path d="M6 13.87A4 4 0 0 1 7.41 6a5.11 5.11 0 0 1 1.05-1.54 5 5 0 0 1 7.08 0A5.11 5.11 0 0 1 16.59 6 '
                    '4 4 0 0 1 18 13.87V21H6Z"/><path d="M6 17h12"/>'),
    "healthy": _svg('<path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/>'
                    '<path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/>'),
    "spark": _svg('<path d="m12 3-1.9 5.8a2 2 0 0 1-1.3 1.3L3 12l5.8 1.9a2 2 0 0 1 1.3 1.3L12 21l1.9-5.8a2 2 0 0 1 '
                  '1.3-1.3L21 12l-5.8-1.9a2 2 0 0 1-1.3-1.3Z"/>'),
    "clock": _svg('<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>'),
    "grid": _svg('<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/>'
                 '<rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>'),
    "src": _svg('<path d="M4 11a9 9 0 0 1 9 9M4 4a16 16 0 0 1 16 16"/><circle cx="5" cy="19" r="1"/>'),
}

FONTS = ('<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'
         '<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,400;9..40,500;9..40,700;9..40,900'
         '&family=IBM+Plex+Sans+Arabic:wght@400;500;600;700&display=swap" rel="stylesheet">')

THEME_JS = r"""
<script>(function(){try{var t=localStorage.getItem('theme');if(t==='dark'||(!t&&matchMedia('(prefers-color-scheme: dark)').matches))document.documentElement.classList.add('dark')}catch(e){}})();
function toggleTheme(){var h=document.documentElement;h.classList.toggle('dark');try{localStorage.setItem('theme',h.classList.contains('dark')?'dark':'light')}catch(e){}}</script>
"""

BASE_CSS = r"""
:root{--bg:#f6f5f2;--card:rgba(255,255,255,.72);--cardB:rgba(255,255,255,.95);--line:#ececec;
--shadow:0 10px 40px -15px rgba(234,88,12,.16);--shadowH:0 22px 50px -18px rgba(234,88,12,.28);
--txt:#0a0a0a;--txt2:#171717;--mut:#737373;--mut2:#a3a3a3;--chip:#fafafa;--chipB:#e5e5e5;--chipT:#525252;
--acc:#ea580c;--accSoft:#fff1e8;--navy:#1e3a5f;--green:#10b981;--top:rgba(255,255,255,.85);--seg:#f4f4f4;--segOn:#fff;--ph:#f3eee9}
html.dark{--bg:#0a0a0a;--card:#141414;--cardB:#232323;--line:#222;
--shadow:0 10px 40px -15px rgba(0,0,0,.9);--shadowH:0 22px 50px -18px rgba(249,115,22,.22);
--txt:#fafafa;--txt2:#e5e5e5;--mut:#a3a3a3;--mut2:#6b6b6b;--chip:#1b1b1b;--chipB:#2a2a2a;--chipT:#d4d4d4;
--acc:#f97316;--accSoft:#2a1608;--navy:#1e4a7a;--top:rgba(12,12,12,.85);--seg:#181818;--segOn:#2a2a2a;--ph:#1c1917}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:"DM Sans","IBM Plex Sans Arabic",ui-sans-serif,system-ui,sans-serif;background:var(--bg);color:var(--txt2);
line-height:1.65;-webkit-font-smoothing:antialiased;transition:background .3s,color .3s}
a{color:inherit;text-decoration:none}
button{font:inherit;color:inherit}
/* top bar */
.top{position:sticky;top:0;z-index:30;background:var(--top);backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);border-bottom:1px solid var(--line)}
.top-in{display:flex;align-items:center;gap:16px;padding:12px 28px}
.brand{display:flex;align-items:center;gap:10px}
.mark{width:34px;height:34px;border-radius:10px;background:var(--navy);display:grid;place-items:center;color:#fff;font:900 16px "DM Sans";position:relative}
.mark:after{content:"";position:absolute;width:9px;height:9px;border-radius:50%;background:var(--acc);bottom:-2px;left:-2px;border:2px solid var(--bg)}
.brand b{font:900 18px "DM Sans";color:var(--txt);letter-spacing:-.4px;line-height:1}
.brand small{display:block;font:700 9px "DM Sans";letter-spacing:2px;color:var(--acc);margin-top:3px}
.mode{display:flex;align-items:center;gap:7px;font-size:12.5px;color:var(--mut);padding-inline-start:16px;border-inline-start:1px solid var(--line)}
.gdot{width:7px;height:7px;border-radius:50%;background:var(--green);box-shadow:0 0 0 3px rgba(16,185,129,.18)}
nav{margin:0 auto;display:flex;gap:2px;background:var(--seg);border:1px solid var(--line);border-radius:12px;padding:3px}
nav a{display:flex;align-items:center;gap:6px;font-size:13px;font-weight:600;color:var(--mut);padding:6px 14px;border-radius:9px;transition:.2s}
nav a:hover{color:var(--txt)}
nav a.on{background:var(--segOn);color:var(--txt);box-shadow:0 1px 3px rgba(0,0,0,.08)}
.acts{display:flex;align-items:center;gap:8px}
.theme{width:34px;height:34px;border-radius:50%;border:1px solid var(--chipB);background:var(--card);cursor:pointer;display:grid;place-items:center;color:var(--txt)}
.theme .sun{display:none}html.dark .theme .sun{display:block}html.dark .theme .moon{display:none}
.pill-green{display:flex;align-items:center;gap:6px;background:var(--green);color:#fff;font-size:12.5px;font-weight:700;padding:8px 14px;border-radius:10px}
@media(max-width:860px){.mode{display:none}.top-in{padding:10px 14px;gap:10px}.pill-green{display:none}nav a span{display:none}nav a{padding:6px 10px}.brand small{display:none}}
/* bento */
.wrap{max-width:1120px;margin:0 auto;padding:48px 20px 70px}
.bento{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:24px}
.s2{grid-column:span 2}.s3{grid-column:1/-1}
@media(max-width:900px){.bento{grid-template-columns:1fr}.s2,.s3{grid-column:auto}}
.card{background:var(--card);border:1px solid var(--cardB);border-radius:24px;padding:30px;box-shadow:var(--shadow);
backdrop-filter:blur(10px);transition:transform .3s cubic-bezier(.2,.8,.2,1),box-shadow .3s;min-width:0}
a.card:hover{transform:translateY(-4px);box-shadow:var(--shadowH)}
.lbl{display:flex;align-items:center;gap:9px;margin-bottom:18px;color:var(--acc)}
.lbl span{font:900 12px "DM Sans","IBM Plex Sans Arabic";letter-spacing:2.4px;text-transform:uppercase;color:var(--mut)}
.hint{margin-inline-start:auto;font-style:normal;font-size:11px;color:var(--mut2)}
.status{display:inline-flex;align-items:center;gap:7px;font-size:11.5px;font-weight:700;color:var(--chipT);background:var(--chip);
border:1px solid var(--chipB);border-radius:99px;padding:4px 12px}
.hero h1{font:900 clamp(34px,5vw,50px)/1.12 "DM Sans","IBM Plex Sans Arabic";letter-spacing:-1.2px;color:var(--txt);margin:18px 0 6px}
.role{color:var(--acc);font-weight:700;font-size:16px;letter-spacing:.3px}
.desc{color:var(--mut);font-size:15px;margin-top:12px;max-width:620px}
.metas{display:flex;flex-wrap:wrap;gap:8px;margin-top:22px;padding-top:20px;border-top:1px solid var(--line)}
.meta{display:flex;align-items:center;gap:6px;font-size:12px;color:var(--mut);background:var(--chip);border:1px solid var(--chipB);padding:5px 11px;border-radius:9px}
.meta b{color:var(--txt);font-family:"DM Sans"}
.chips{display:flex;flex-wrap:wrap;gap:8px}
.chip{font-size:12px;font-weight:500;color:var(--chipT);background:var(--chip);border:1px solid var(--chipB);border-radius:12px;padding:6px 12px;cursor:pointer;transition:.2s}
.chip:hover{border-color:var(--acc);color:var(--acc)}
.chip.on{background:var(--accSoft);border-color:var(--acc);color:var(--acc);font-weight:700}
.chip small{opacity:.6;margin-inline-start:5px}
.search{display:flex;align-items:center;gap:8px;margin-top:18px;background:var(--chip);border:1px solid var(--chipB);border-radius:14px;padding:0 14px;color:var(--mut2)}
.search:focus-within{border-color:var(--acc)}
.search input{flex:1;border:0;outline:0;background:none;color:var(--txt);font:inherit;font-size:14px;padding:11px 0}
/* timeline */
.tl{list-style:none;position:relative}
.tl li{position:relative;display:flex;gap:14px;padding-bottom:16px}
.tl li:before{content:"";position:absolute;top:14px;bottom:-2px;inset-inline-start:3.5px;width:1px;background:var(--chipB)}
.tl li:last-child{padding-bottom:0}.tl li:last-child:before{display:none}
.tl i{flex:none;width:8px;height:8px;border-radius:50%;background:var(--acc);margin-top:8px;box-shadow:0 0 0 3px var(--accSoft)}
.tl b{display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;font-size:14px;font-weight:700;color:var(--txt2);line-height:1.5}
.tl small{display:block;font-size:10.5px;font-weight:700;letter-spacing:.5px;color:var(--mut2);text-transform:uppercase;margin-top:2px}
.tl a:hover b{color:var(--acc)}
/* image */
.ph{position:relative;border-radius:16px;overflow:hidden;background:var(--ph);aspect-ratio:16/10;display:grid;place-items:center;font-size:44px;margin-bottom:16px}
.ph img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;transition:transform .7s}
a.card:hover .ph img{transform:scale(1.05)}
.btn-navy{display:inline-flex;align-items:center;gap:6px;background:var(--navy);color:#fff;font-size:13px;font-weight:700;padding:10px 18px;border-radius:11px;margin-top:20px}
footer{text-align:center;color:var(--mut2);font-size:12px;padding:10px 0 40px}
@keyframes up{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:none}}
.bento>*{animation:up .5s both}
"""

TOPBAR = """
<header class="top"><div class="top-in">
  <a class="brand" href="/"><span class="mark">M</span><span><b>__SITE__</b><small>DAILY DIGEST</small></span></a>
  <span class="mode"><span class="gdot"></span>يتحدّث يومياً</span>
  <nav>__NAV__</nav>
  <div class="acts">
    <button class="theme" onclick="toggleTheme()" title="لايت / دارك">
      <svg class="moon" viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/></svg>
      <svg class="sun" viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>
    </button>
    <span class="pill-green" id="newpill">✦ جديد اليوم</span>
  </div>
</div></header>
"""

HEAD = """<!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light dark">
"""

PAGE_TEMPLATE = HEAD + """<title>__TITLE__ · __SITE__</title>
<meta name="description" content="__DESC__">
<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>__EMOJI__</text></svg>">
""" + FONTS + THEME_JS + "<style>" + BASE_CSS + r"""
.feat{display:grid;grid-template-columns:1.15fr 1fr;gap:26px;align-items:center}
.feat .ph{margin:0;aspect-ratio:4/3}
.feat h2{font:900 26px/1.3 "DM Sans","IBM Plex Sans Arabic";letter-spacing:-.4px;color:var(--txt);margin:12px 0 8px}
.feat p{color:var(--mut);font-size:14.5px;display:-webkit-box;-webkit-line-clamp:5;-webkit-box-orient:vertical;overflow:hidden}
@media(max-width:640px){.feat{grid-template-columns:1fr}}
.src{display:inline-flex;align-items:center;gap:6px;font-size:11.5px;font-weight:700;color:var(--chipT);background:var(--chip);border:1px solid var(--chipB);border-radius:9px;padding:3px 10px}
.new{color:var(--acc);background:var(--accSoft);border-color:transparent}
.when{font-size:10.5px;font-weight:700;letter-spacing:.5px;color:var(--mut2);text-transform:uppercase}
.item{padding:14px 14px 20px;display:flex;flex-direction:column}
.item .ph{margin-bottom:14px}
.item .row{display:flex;align-items:center;gap:8px;padding:0 6px}
.item .row .when{margin-inline-start:auto}
.item h3{font-size:15.5px;font-weight:700;line-height:1.5;color:var(--txt2);padding:10px 6px 4px;display:-webkit-box;-webkit-line-clamp:3;-webkit-box-orient:vertical;overflow:hidden}
.item p{font-size:13.5px;color:var(--mut);padding:0 6px;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
.latest .tl{max-height:430px;overflow:auto;padding-inline-end:6px;scrollbar-width:thin}
.sec{grid-column:1/-1;display:flex;align-items:center;gap:9px;color:var(--acc);margin:14px 0 -6px}
.sec span{font:900 12px "DM Sans","IBM Plex Sans Arabic";letter-spacing:2.4px;color:var(--mut)}
.empty{grid-column:1/-1;text-align:center;color:var(--mut);padding:40px}
</style></head><body>
""" + TOPBAR + """
<main class="wrap"><div class="bento" id="bento">
  <section class="card hero s2">
    <span class="status"><span class="gdot"></span><span id="upd">يتحدّث يومياً</span></span>
    <h1>__TITLE__</h1>
    <div class="role">__EMOJI__ __SHORT__ · تحديث يومي الساعة ٦ صباحاً</div>
    <p class="desc">__DESC__</p>
    <div class="metas">
      <span class="meta">📰 <b id="s-total">0</b> عنصر</span>
      <span class="meta">✨ <b id="s-new">0</b> جديد اليوم</span>
      <span class="meta">🔗 <b id="s-src">0</b> مصادر</span>
    </div>
  </section>
  <section class="card">
    <div class="lbl">__ICON_SRC__<span>المصادر</span><em class="hint">اضغط للفلترة</em></div>
    <div class="chips" id="chips"></div>
    <label class="search">🔎<input id="q" type="search" placeholder="ابحث في العناوين…" autocomplete="off"></label>
  </section>
  <div id="dyn" style="display:contents"></div>
</div></main>
<footer>__SITE__ · تجميع تلقائي من مصادر RSS — الحقوق محفوظة لأصحابها</footer>
<script>
const D=__DATA__, ICON=__ICONS__;
const rtf=new Intl.RelativeTimeFormat('ar',{numeric:'auto'});
function ago(s){const d=(new Date(s)-Date.now())/1000,a=Math.abs(d);
 if(a<3600)return rtf.format(Math.round(d/60),'minute');if(a<86400)return rtf.format(Math.round(d/3600),'hour');return rtf.format(Math.round(d/86400),'day')}
function esc(s){return(s||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
const isNew=i=>Date.now()-new Date(i.date)<864e5;
const img=(i,eager)=>`<div class="ph">${D.emoji}${i.image?`<img src="${esc(i.image)}" alt="" loading="${eager?'eager':'lazy'}" referrerpolicy="no-referrer" onerror="this.remove()">`:''}</div>`;
const lnk=i=>`href="${esc(i.link)}" target="_blank" rel="noopener"`;
let src='all',q='';
const chips=document.getElementById('chips'),dyn=document.getElementById('dyn');
function chip(k,l,n){const b=document.createElement('button');b.className='chip'+(k===src?' on':'');b.innerHTML=esc(l)+'<small>'+n+'</small>';
 b.onclick=()=>{src=k;[...chips.children].forEach(c=>c.classList.remove('on'));b.classList.add('on');render()};chips.appendChild(b)}
chip('all','الكل',D.items.length);D.sources.forEach(s=>chip(s,s,D.items.filter(i=>i.source===s).length));
const nNew=D.items.filter(isNew).length;
document.getElementById('s-total').textContent=D.items.length;
document.getElementById('s-new').textContent=nNew;
document.getElementById('s-src').textContent=D.sources.length;
document.getElementById('newpill').textContent='✦ '+nNew+' جديد اليوم';
document.getElementById('upd').textContent='آخر تحديث '+ago(D.updated);
function render(){
 const L=D.items.filter(i=>(src==='all'||i.source===src)&&(!q||(i.title+' '+i.summary).toLowerCase().includes(q)));
 if(!L.length){dyn.innerHTML='<div class="card empty">لا توجد نتائج مطابقة</div>';return}
 const f=L[0],tl=L.slice(1,8),rest=L.slice(8);let h='';
 h+=`<a class="card feat s2" ${lnk(f)}>${img(f,true)}<div><div class="lbl" style="margin-bottom:6px">${ICON.spark}<span>الأبرز</span></div>
  <span class="src">${esc(f.source)}</span> ${isNew(f)?'<span class="src new">جديد</span>':''}
  <h2 dir="auto">${esc(f.title)}</h2><p dir="auto">${esc(f.summary)}</p>
  <span class="btn-navy">اقرأ المقال ←</span></div></a>`;
 h+=`<section class="card latest"><div class="lbl">${ICON.clock}<span>آخر العناوين</span></div><ul class="tl">`+
  (tl.length?tl.map(i=>`<li><i></i><a ${lnk(i)}><b dir="auto">${esc(i.title)}</b><small>${esc(i.source)} — ${ago(i.date)}</small></a></li>`).join(''):'<li><small>لا يوجد المزيد</small></li>')+`</ul></section>`;
 if(rest.length){h+=`<div class="sec">${ICON.grid}<span>كل المحتوى</span></div>`;
  h+=rest.map((i,n)=>`<a class="card item" ${lnk(i)} style="animation-delay:${Math.min(n,9)*40}ms">${img(i)}
   <div class="row"><span class="src${isNew(i)?' new':''}">${esc(i.source)}</span><span class="when">${ago(i.date)}</span></div>
   <h3 dir="auto">${esc(i.title)}</h3>${i.summary?`<p dir="auto">${esc(i.summary)}</p>`:''}</a>`).join('')}
 dyn.innerHTML=h}
document.getElementById('q').addEventListener('input',e=>{q=e.target.value.trim().toLowerCase();render()});
render();
</script></body></html>
"""

HOME_TEMPLATE = HEAD + """<title>__SITE__ — تقنية · طبخات · أكل صحي</title>
<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>✨</text></svg>">
""" + FONTS + THEME_JS + "<style>" + BASE_CSS + r"""
.cat{display:flex;flex-direction:column;padding:24px}
.cat h2{font:900 23px/1.3 "DM Sans","IBM Plex Sans Arabic";color:var(--txt);letter-spacing:-.4px}
.cat .desc{font-size:13.5px;margin:4px 0 18px}
.cat .tl{margin-bottom:auto}
.cat .btn-navy{align-self:flex-start}
.cat .lbl{margin-bottom:14px}
</style></head><body>
""" + TOPBAR + """
<main class="wrap"><div class="bento">
  <section class="card hero s2">
    <span class="status"><span class="gdot"></span><span id="upd">يتحدّث يومياً</span></span>
    <h1>جرعتك اليومية<br>من التقنية والأكل الطيّب</h1>
    <div class="role">Daily Digest · كل يوم الساعة ٦ صباحاً</div>
    <p class="desc">ثلاث صفحات تتحدّث تلقائياً: آخر أخبار التقنية، طبخات جديدة، وأكلات صحية — من أفضل المصادر العربية والعالمية.</p>
  </section>
  <section class="card">
    <div class="lbl">__ICON_CLOCK__<span>ملخّص اليوم</span></div>
    <ul class="tl">__STATS__</ul>
  </section>
  __CARDS__
</div></main>
<footer>__SITE__ · تجميع تلقائي من مصادر RSS — الحقوق محفوظة لأصحابها</footer>
<script>const U=__UPDATED__;const rtf=new Intl.RelativeTimeFormat('ar',{numeric:'auto'});
const m=Math.round((new Date(U)-Date.now())/6e4);document.getElementById('upd').textContent='آخر تحديث '+(Math.abs(m)<60?rtf.format(m,'minute'):Math.abs(m)<1440?rtf.format(Math.round(m/60),'hour'):rtf.format(Math.round(m/1440),'day'));
document.getElementById('newpill').textContent='✦ تحديث يومي';</script>
</body></html>
"""


if __name__ == "__main__":
    sys.exit(main())
