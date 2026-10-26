#!/usr/bin/env python3
"""
mednet_extract.py — استخراج قوائم دليل ميدنت من صور الدفتر.

يقرأ صور الصفحات (HEIC / JPG / PNG)، يرسل كل صورة لـ Claude،
ويطلع ملفات: doctors.json + doctors.csv + تقرير بالصفوف اللي بدها مراجعة.

الاستخدام:
    export ANTHROPIC_API_KEY="sk-ant-..."
    python3 mednet_extract.py ~/Desktop/photos
    python3 mednet_extract.py ~/Desktop/photos --rotate 90 --workers 4
    python3 mednet_extract.py ~/Desktop/photos --merge doctors.csv   # يضيف على ملف موجود

ملاحظات:
    * كل صورة بتنحفظ نتيجتها بمجلد .cache — إعادة التشغيل ما بتعيد الاستدعاء
      (وما بتدفع مرتين). امسح المجلد إذا بدك تعيد التحليل من الصفر.
    * الصور المائلة: استعمل --rotate 90 أو 270 إذا الدفتر مصوّر بالعرض،
      أو --rotate auto ليجرب لحاله (بيكلف استدعاءات زيادة).
"""

from __future__ import annotations

import argparse
import base64
import csv
import hashlib
import io
import json
import os
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

try:
    import anthropic
except ImportError:
    sys.exit("ناقص المكتبة: pip install anthropic pillow pillow-heif")

from PIL import Image

try:
    from pillow_heif import register_heif_opener

    register_heif_opener()
except ImportError:
    pass  # بس ما رح تشتغل صور HEIC

IMAGE_EXTS = {".heic", ".heif", ".jpg", ".jpeg", ".png", ".webp"}
MAX_EDGE = 1600          # الحافة الأطول بعد التصغير
JPEG_QUALITY = 85
MAX_RETRIES = 3

FIELDS = [
    "name", "doctor", "type", "specialty", "city", "area",
    "address", "phone", "source_page", "notes", "source_image",
]

SYSTEM_PROMPT = """\
أنت مساعد متخصص باستخراج البيانات من صور دليل شبكة طبية (MedNet) باللغة العربية.

الصفحة عبارة عن جدول من ثلاثة أعمدة (من اليمين لليسار):
إسم مقدم الخدمة | العنوان | رقم الهاتف
وفوق الجدول عنوان القسم، وهو اختصاص القائمة. الدليل فيه أقسام كثيرة، منها مثلاً:
الطب العام، مركز طوارئ 24 ساعة، الجراحة العامة، الأسنان، النسائية والتوليد، الأطفال،
الباطنية، العظام، الجلدية، العيون، الأنف والأذن والحنجرة، القلب، الأعصاب، المسالك البولية،
الأشعة، المختبرات، العلاج الطبيعي، الصيدليات، المستشفيات، البصريات، التغذية.
انسخ عنوان القسم كما هو مكتوب بالصفحة حرفياً ولا تستبدله بواحد من هذه الأمثلة.
وأسفل الصفحة رقم الصفحة.

قواعد إلزامية:
1. الصفحة مصوّرة بزاوية مائلة، فالأعمدة بتبان مزاحة عن بعضها عمودياً.
   لا تربط الصف بالمحاذاة البصرية. اقرأ كل عمود كقائمة مستقلة من فوق لتحت،
   وبعدين اربط العنصر رقم 1 بالعنصر رقم 1، ورقم 2 برقم 2، وهكذا.
2. عدد الأسماء لازم يساوي عدد العناوين ويساوي عدد الأرقام. إذا ما تساووا،
   رجّع needs_review = true واشرح السبب في review_reason.
3. الأرقام الأرضية 7 خانات والخلوي 10 خانات وبيبدأ بـ 07. انسخ الرقم كما هو
   مطبوع بدون إضافة مفتاح. إذا في خانة مغطاة بلمعة أو غير مقروءة،
   ضع X مكان كل خانة مفقودة (مثال: 079075892X) واذكرها في notes.
4. لا تخمّن ولا تكمّل من معرفتك. اللي مش مقروء = "" مع ذكره في notes.
5. إذا كان الاسم فيه فاصل مثل "عيادات النخيل - د. إياد الشافعي"،
   حط الجزء الأول في name والدكتور في doctor.
6. type = "عيادة/مركز" إذا الاسم فيه عيادة/عيادات/مركز/مجمع، وإلا "طبيب".
7. العنوان الفرعي إذا وجد (مثل "الزرقاء - وادي الحجر") انسخه كامل في address،
   وحط المنطقة الرئيسية في area.
8. city = المحافظة (عمّان، الزرقاء، البلقاء، إربد، المفرق، جرش، عجلون، مادبا،
   الكرك، الطفيلة، معان، العقبة). استنتجها من المنطقة، وإذا ما قدرت خليها "".

إذا كان عنوان القسم مقصوص أو غير ظاهر بالصورة، خلّي specialty = "" ولا تخمّنه.

إذا الصورة إعلان أو غلاف أو صفحة بدون جدول، رجّع rows = [] و is_listing = false.

أرجع JSON فقط، بدون أي نص قبله أو بعده، بهذا الشكل:
{
  "is_listing": true,
  "page_number": 38,
  "specialty": "الطب العام",
  "needs_review": false,
  "review_reason": "",
  "rows": [
    {"name":"...","doctor":"","type":"طبيب","city":"عمّان","area":"طبربور",
     "address":"طبربور","phone":"5059270","notes":""}
  ]
}
"""


# ---------- تجهيز الصور ----------

def load_image(path: Path, rotate: int) -> Image.Image:
    im = Image.open(path)
    im = im.convert("RGB")
    if rotate:
        im = im.rotate(rotate, expand=True)
    if max(im.size) > MAX_EDGE:
        scale = MAX_EDGE / max(im.size)
        im = im.resize((int(im.width * scale), int(im.height * scale)), Image.LANCZOS)
    return im


def to_b64(im: Image.Image) -> str:
    buf = io.BytesIO()
    im.save(buf, format="JPEG", quality=JPEG_QUALITY, optimize=True)
    return base64.b64encode(buf.getvalue()).decode()


# ---------- الاستدعاء ----------

def ask_claude(client: anthropic.Anthropic, model: str, b64: str) -> dict:
    last_err = None
    for attempt in range(MAX_RETRIES):
        try:
            msg = client.messages.create(
                model=model,
                max_tokens=8000,
                temperature=0,
                system=SYSTEM_PROMPT,
                messages=[{
                    "role": "user",
                    "content": [
                        {"type": "image", "source": {
                            "type": "base64", "media_type": "image/jpeg", "data": b64}},
                        {"type": "text", "text": "استخرج الجدول من هذه الصفحة."},
                    ],
                }],
            )
            text = "".join(b.text for b in msg.content if b.type == "text").strip()
            text = re.sub(r"^```(?:json)?|```$", "", text, flags=re.MULTILINE).strip()
            return json.loads(text)
        except Exception as e:                      # شبكة، rate limit، أو JSON مكسور
            last_err = e
            time.sleep(2 ** attempt)
    raise RuntimeError(f"فشل الاستدعاء بعد {MAX_RETRIES} محاولات: {last_err}")


def process_image(path: Path, client, model: str, rotate: str, cache_dir: Path) -> dict:
    key = hashlib.md5(f"{path.name}|{path.stat().st_size}|{rotate}|{model}".encode()).hexdigest()[:16]
    cache_file = cache_dir / f"{path.stem}.{key}.json"
    if cache_file.exists():
        data = json.loads(cache_file.read_text(encoding="utf-8"))
        data["_cached"] = True
        return data

    tries = [0, 90, 270, 180] if rotate == "auto" else [int(rotate)]
    result = {"is_listing": False, "rows": []}
    for r in tries:
        result = ask_claude(client, model, to_b64(load_image(path, r)))
        result["rotation"] = r
        if result.get("is_listing") and result.get("rows"):
            break

    result["source_image"] = path.name
    cache_file.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    return result


# ---------- التحقق ----------

def check_row(row: dict) -> list[str]:
    problems = []
    phone = re.sub(r"[^\dX]", "", row.get("phone", ""))
    if "X" in phone:
        problems.append("رقم ناقص خانات")
    elif len(phone) == 10 and not phone.startswith("07"):
        problems.append("رقم خلوي ما بيبدأ بـ 07")
    elif len(phone) not in (7, 10):
        problems.append(f"طول الرقم {len(phone)} خانة")
    if not row.get("name"):
        problems.append("بدون اسم")
    if not row.get("area"):
        problems.append("بدون منطقة")
    return problems


def normalize(row: dict, page: int, specialty: str, image: str) -> dict:
    out = {f: "" for f in FIELDS}
    out.update({k: (row.get(k) or "").strip() for k in
                ("name", "doctor", "type", "city", "area", "address", "phone", "notes")})
    out["specialty"] = canon(row.get("specialty") or specialty)
    out["address"] = out["address"] or out["area"]
    out["source_page"] = page
    out["source_image"] = image
    problems = check_row(out)
    if problems:
        out["notes"] = " | ".join(filter(None, [out["notes"], "⚠ " + "، ".join(problems)]))
    return out


# ---------- الاختصاصات ----------

CANONICAL = {
    "طب عام": "الطب العام", "الطب العام": "الطب العام", "طبيب عام": "الطب العام",
    "اسنان": "الأسنان", "أسنان": "الأسنان", "الاسنان": "الأسنان", "طب الأسنان": "الأسنان",
    "نسائية": "النسائية والتوليد", "النسائية": "النسائية والتوليد",
    "نسائية وتوليد": "النسائية والتوليد", "النسائية والتوليد": "النسائية والتوليد",
    "اطفال": "الأطفال", "أطفال": "الأطفال", "الاطفال": "الأطفال", "الأطفال": "الأطفال",
    "باطنية": "الباطنية", "الباطنية": "الباطنية",
    "عظام": "العظام", "العظام": "العظام", "جراحة العظام": "العظام",
    "جلدية": "الجلدية", "الجلدية": "الجلدية",
    "عيون": "العيون", "العيون": "العيون",
    "انف واذن وحنجرة": "الأنف والأذن والحنجرة",
    "الأنف والأذن والحنجرة": "الأنف والأذن والحنجرة",
    "قلب": "القلب", "القلب": "القلب", "قلبية": "القلب",
    "جراحة عامة": "الجراحة العامة", "الجراحة العامة": "الجراحة العامة",
    "مختبرات": "المختبرات", "المختبرات": "المختبرات",
    "اشعة": "الأشعة", "أشعة": "الأشعة", "الأشعة": "الأشعة",
    "صيدليات": "الصيدليات", "الصيدليات": "الصيدليات",
    "مستشفيات": "المستشفيات", "المستشفيات": "المستشفيات",
    "علاج طبيعي": "العلاج الطبيعي", "العلاج الطبيعي": "العلاج الطبيعي",
    "بصريات": "البصريات", "البصريات": "البصريات",
    "مركز طوارئ 24 ساعة": "مراكز طوارئ 24 ساعة",
    "مراكز طوارئ 24 ساعة": "مراكز طوارئ 24 ساعة",
}


def canon(name: str) -> str:
    name = re.sub(r"\s+", " ", (name or "").strip()).strip("-–—: ")
    return CANONICAL.get(name, name)


def fill_specialties(results: list[dict]) -> None:
    """الاختصاص عنوان قسم بيمتد على عدة صفحات. الصفحة اللي عنوانها مقصوص
    بتاخد اختصاص أقرب صفحة قبلها بالترتيب."""
    listings = [r for r in results if r.get("is_listing")]
    listings.sort(key=lambda r: (r.get("page_number") or 10**6, r.get("source_image", "")))
    last = ""
    for r in listings:
        sp = canon(r.get("specialty", ""))
        if sp:
            last = sp
        else:
            r["inherited_specialty"] = True
        r["specialty"] = sp or last


# ---------- التشغيل ----------

def main() -> None:
    ap = argparse.ArgumentParser(description="استخراج قوائم دليل ميدنت من الصور")
    ap.add_argument("folder", help="مجلد الصور")
    ap.add_argument("--out", default="doctors", help="اسم ملفات الإخراج بدون امتداد")
    ap.add_argument("--model", default="claude-sonnet-5")
    ap.add_argument("--rotate", default="0", help="0 | 90 | 180 | 270 | auto")
    ap.add_argument("--workers", type=int, default=4, help="عدد الصور بالتوازي")
    ap.add_argument("--merge", help="ملف CSV موجود يتم الدمج معه")
    args = ap.parse_args()

    if not os.environ.get("ANTHROPIC_API_KEY"):
        sys.exit("حط المفتاح أولاً:  export ANTHROPIC_API_KEY=\"sk-ant-...\"")

    folder = Path(args.folder).expanduser()
    images = sorted(p for p in folder.iterdir() if p.suffix.lower() in IMAGE_EXTS)
    if not images:
        sys.exit(f"ما في صور في {folder}")

    cache_dir = folder / ".cache"
    cache_dir.mkdir(exist_ok=True)
    client = anthropic.Anthropic()

    print(f"عدد الصور: {len(images)}  |  الموديل: {args.model}  |  التدوير: {args.rotate}\n")

    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {pool.submit(process_image, p, client, args.model, args.rotate, cache_dir): p
                   for p in images}
        for i, fut in enumerate(as_completed(futures), 1):
            path = futures[fut]
            try:
                res = fut.result()
                results.append(res)
                tag = "cache" if res.get("_cached") else "جديد"
                if res.get("is_listing"):
                    print(f"[{i}/{len(images)}] {path.name}: صفحة {res.get('page_number','?')} — "
                          f"{len(res.get('rows',[]))} صف ({tag})")
                else:
                    print(f"[{i}/{len(images)}] {path.name}: إعلان/بدون جدول ({tag})")
            except Exception as e:
                failures.append((path.name, str(e)))
                print(f"[{i}/{len(images)}] {path.name}: فشل — {e}")

    fill_specialties(results)

    # تجميع الصفوف
    rows = []
    for res in results:
        if not res.get("is_listing"):
            continue
        page = res.get("page_number") or 0
        for r in res.get("rows", []):
            rows.append(normalize(r, page, res.get("specialty", ""), res.get("source_image", "")))

    # الدمج مع ملف قديم
    if args.merge and Path(args.merge).exists():
        with open(args.merge, encoding="utf-8-sig") as f:
            rows = [{**{k: "" for k in FIELDS}, **r} for r in csv.DictReader(f)] + rows

    # إزالة المكرر (نفس الاسم + نفس الرقم + نفس العنوان)
    seen, unique = set(), []
    for r in rows:
        key = (r["name"], re.sub(r"\D", "", r["phone"]), r["address"])
        if key in seen:
            continue
        seen.add(key)
        unique.append(r)

    unique.sort(key=lambda r: (str(r["source_page"]).zfill(4), r["area"], r["name"]))

    json_path, csv_path = Path(f"{args.out}.json"), Path(f"{args.out}.csv")
    json_path.write_text(json.dumps(
        {"count": len(unique),
         "specialties": sorted({r["specialty"] for r in unique if r["specialty"]}),
         "cities": sorted({r["city"] for r in unique if r["city"]}),
         "providers": unique}, ensure_ascii=False, indent=2), encoding="utf-8")

    with open(csv_path, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS)
        w.writeheader()
        w.writerows(unique)

    # التقرير
    by_spec = {}
    for r in unique:
        by_spec[r["specialty"] or "(بدون اختصاص)"] = by_spec.get(r["specialty"] or "(بدون اختصاص)", 0) + 1
    print("\nالاختصاصات: " + "، ".join(f"{k} ({v})" for k, v in
                                        sorted(by_spec.items(), key=lambda x: -x[1])))
    inherited = [r.get("source_image") for r in results if r.get("inherited_specialty")]
    if inherited:
        print(f"صفحات أخذت الاختصاص من الصفحة اللي قبلها ({len(inherited)}): "
              + "، ".join(inherited))

    flagged = [r for r in unique if "⚠" in r["notes"]]
    bad_pages = [(res.get("source_image"), res.get("review_reason", ""))
                 for res in results if res.get("needs_review")]

    print(f"\nالمجموع: {len(unique)} مقدم خدمة  →  {csv_path}  و  {json_path}")
    if bad_pages:
        print(f"\nصفحات محتاجة مراجعة ({len(bad_pages)}):")
        for img, why in bad_pages:
            print(f"  - {img}: {why}")
    if flagged:
        print(f"\nصفوف عليها ملاحظة ({len(flagged)}):")
        for r in flagged[:40]:
            print(f"  - ص{r['source_page']} {r['name']} ({r['phone']}) — {r['notes']}")
        if len(flagged) > 40:
            print(f"  ... و {len(flagged)-40} غيرهم، شوفهم بعمود notes")
    if failures:
        print(f"\nصور فشلت ({len(failures)}): " + "، ".join(n for n, _ in failures))


if __name__ == "__main__":
    main()
