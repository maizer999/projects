#!/usr/bin/env python3
"""
sync_from_sheet.py — يقرأ شيت جوجل، يشيل المكرر، ويخزّن doctors.json
ويبني نسخة جاهزة من الموقع (index.html).

الاستخدام:
    # الشيت لازم يكون مشارك: "أي شخص لديه الرابط — مُشاهد"
    python3 sync_from_sheet.py --sheet 1GoJjOWHCoVVt93PUgBC-ifqTRDybq2mmMfSGRc6IAvk \\
        --out "~/Library/CloudStorage/GoogleDrive-maizer99@gmail.com/My Drive/mednet"

    # أو من ملف CSV منزّل يدوياً
    python3 sync_from_sheet.py --csv ~/Downloads/doctors.csv --out ~/mednet

الناتج داخل مجلد --out:
    doctors.json      البيانات بعد إزالة المكرر
    doctors.xlsx      نسخة إكسل جاهزة (نسخة احتياطية / للفتح على الماك)
    index.html        الموقع (بيقرا doctors.json من جنبه إذا كان مرفوع على سيرفر)
    duplicates.csv    الصفوف المحذوفة، للمراجعة

إذا فشلت قراءة الشيت كـ CSV، السكربت بينزّله تلقائياً بصيغة xlsx وبيقراه منها.

إذا خليت --out داخل مجلد Google Drive for Desktop، الملفات بترفع لدرايف
تلقائياً وبتقعد جنب الشيت بنفس المجلد.
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import re
import sys
import urllib.request
from pathlib import Path

# ترجمة رؤوس الأعمدة العربية لأسماء الحقول
HEADER_MAP = {
    "اسم مقدم الخدمة": "name", "إسم مقدم الخدمة": "name", "name": "name",
    "الطبيب": "doctor", "doctor": "doctor",
    "النوع": "type", "type": "type",
    "الاختصاص": "specialty", "specialty": "specialty",
    "المحافظة": "city", "city": "city",
    "المنطقة": "area", "area": "area",
    "العنوان": "address", "address": "address",
    "رقم الهاتف": "phone", "phone": "phone",
    "رقم الاتصال الدولي": "phone_dial", "phone_dial": "phone_dial",
    "الشبكة": "network", "network": "network",
    "صفحة الدليل": "source_page", "source_page": "source_page",
    "ملاحظات": "notes", "notes": "notes",
    "صورة المصدر": "source_image", "source_image": "source_image",
}

AMMAN = "عمّان"


def _download(sheet_id: str, gid: str | None, fmt: str) -> bytes:
    url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/export?format={fmt}"
    if gid:
        url += f"&gid={gid}"
    with urllib.request.urlopen(url, timeout=60) as r:
        return r.read()


def fetch_sheet(sheet_id: str, gid: str | None, keep_xlsx: Path | None = None) -> list[dict]:
    """يجرب CSV أولاً، وإذا ما زبط بينزّل نسخة xlsx ويقرا منها."""
    csv_err = None
    try:
        data = _download(sheet_id, gid, "csv").decode("utf-8-sig")
        if not data.lstrip().lower().startswith("<!doctype html"):
            return read_rows(data)
        csv_err = "الرد كان صفحة تسجيل دخول (الشيت مش مشارك)"
    except Exception as e:
        csv_err = str(e)

    print(f"تعذّرت قراءة CSV ({csv_err}) — بجرّب تنزيل نسخة إكسل...")
    try:
        blob = _download(sheet_id, gid, "xlsx")
    except Exception as e:
        sys.exit(f"وكمان تنزيل الإكسل فشل: {e}\n"
                 "تأكد من المشاركة: Share ← Anyone with the link ← Viewer\n"
                 "أو نزّل الملف يدوياً وشغّل السكربت بـ --csv أو --xlsx")
    if keep_xlsx:
        keep_xlsx.parent.mkdir(parents=True, exist_ok=True)
        keep_xlsx.write_bytes(blob)
        print(f"انحفظت نسخة الإكسل: {keep_xlsx}")
    return read_xlsx(io.BytesIO(blob))


def read_xlsx(source) -> list[dict]:
    try:
        from openpyxl import load_workbook
    except ImportError:
        sys.exit("لقراءة ملفات الإكسل لازم: pip install openpyxl")
    wb = load_workbook(source, data_only=True, read_only=True)
    ws = wb[wb.sheetnames[0]]
    rows_iter = ws.iter_rows(values_only=True)
    header = [str(c or "").strip() for c in next(rows_iter)]
    out = []
    for values in rows_iter:
        row = {}
        for h, v in zip(header, values):
            key = HEADER_MAP.get(h)
            if key:
                row[key] = ("" if v is None else str(v)).strip()
        if row.get("name"):
            out.append(row)
    wb.close()
    return out


def read_rows(text: str) -> list[dict]:
    reader = csv.DictReader(io.StringIO(text))
    rows = []
    for raw in reader:
        row = {}
        for k, v in raw.items():
            key = HEADER_MAP.get((k or "").strip())
            if key:
                row[key] = (v or "").strip()
        if row.get("name"):
            rows.append(row)
    return rows


def digits(s: str) -> str:
    return re.sub(r"\D", "", s or "")


def dial(phone: str) -> str:
    d = digits(phone)
    if len(d) == 9 and d.startswith("0"):      # أرضي مع مفتاح المحافظة
        return "+962" + d[1:]
    if len(d) == 10 and d.startswith("0"):     # خلوي
        return "+962" + d[1:]
    if len(d) == 7:                            # أرضي بدون مفتاح — نفترض عمّان
        return "+9626" + d
    return ""


def clean(row: dict, idx: int) -> dict:
    name = row.get("name", "")
    typ = row.get("type", "")
    if typ not in ("طبيب", "عيادة/مركز", "doctor", "clinic"):
        typ = "عيادة/مركز" if re.search(r"عياد|مركز|مجمع|كلينك|ميد", name) else "طبيب"
    typ = {"doctor": "طبيب", "clinic": "عيادة/مركز"}.get(typ, typ)
    phone = digits(row.get("phone", ""))
    if len(phone) == 7:
        phone = "06" + phone
    area = row.get("area", "")
    return {
        "id": idx,
        "name": name,
        "doctor": row.get("doctor", ""),
        "type": "clinic" if typ == "عيادة/مركز" else "doctor",
        "specialty": row.get("specialty", ""),
        "city": row.get("city", "") or AMMAN,
        "area": area,
        "address": row.get("address", "") or area,
        "phone": phone or row.get("phone", ""),
        "phone_dial": row.get("phone_dial", "") or dial(phone),
        "network": row.get("network", "") or "MedNet",
        "source_page": row.get("source_page", ""),
        "notes": row.get("notes", ""),
    }


def dedupe(rows: list[dict]) -> tuple[list[dict], list[dict]]:
    """مفتاح التكرار: الاسم + الرقم + العنوان. الفروع (نفس الاسم بعنوان ثاني) بتضل."""
    seen, keep, dropped = {}, [], []
    for r in rows:
        key = (r["name"].strip(), digits(r["phone"]), r["address"].strip())
        if key in seen:
            first = seen[key]
            # بنحافظ على أطول ملاحظات وأكمل بيانات بين النسختين
            for f in ("doctor", "notes", "specialty", "city", "source_page"):
                if not first.get(f) and r.get(f):
                    first[f] = r[f]
            dropped.append(r)
            continue
        seen[key] = r
        keep.append(r)
    for i, r in enumerate(keep, 1):
        r["id"] = i
    return keep, dropped


def write_xlsx(rows: list[dict], path: Path) -> bool:
    try:
        from openpyxl import Workbook
        from openpyxl.styles import Alignment, Font, PatternFill
        from openpyxl.utils import get_column_letter
    except ImportError:
        print("تخطيت ملف الإكسل (مش منصّب openpyxl). للتنصيب: pip install openpyxl")
        return False

    headers = ["اسم مقدم الخدمة", "الطبيب", "النوع", "الاختصاص", "المحافظة",
               "المنطقة", "العنوان", "رقم الهاتف", "رقم الاتصال الدولي",
               "الشبكة", "صفحة الدليل", "ملاحظات"]
    keys = ["name", "doctor", "type", "specialty", "city", "area", "address",
            "phone", "phone_dial", "network", "source_page", "notes"]
    widths = [32, 20, 12, 14, 12, 20, 30, 16, 18, 10, 12, 40]

    wb = Workbook()
    ws = wb.active
    ws.title = "مقدمو الخدمة"
    ws.sheet_view.rightToLeft = True

    head_font = Font(name="Arial", bold=True, color="FFFFFF")
    fill = PatternFill("solid", fgColor="4A6696")
    ws.append(headers)
    for i, cell in enumerate(ws[1], 1):
        cell.font = head_font
        cell.fill = fill
        cell.alignment = Alignment(horizontal="center", vertical="center")
        ws.column_dimensions[get_column_letter(i)].width = widths[i - 1]
    ws.freeze_panes = "A2"

    body = Font(name="Arial")
    for r in rows:
        vals = []
        for k in keys:
            v = r.get(k, "")
            vals.append({"clinic": "عيادة/مركز", "doctor": "طبيب"}.get(v, v) if k == "type" else v)
        ws.append(vals)
        for cell in ws[ws.max_row]:
            cell.font = body
        # الأرقام كنص عشان ما يضيع الصفر الأول
        for col in (8, 9):
            ws.cell(row=ws.max_row, column=col).number_format = "@"

    ws.auto_filter.ref = f"A1:{get_column_letter(len(headers))}{ws.max_row}"
    wb.save(path)
    return True


def main() -> None:
    ap = argparse.ArgumentParser(description="مزامنة الموقع مع شيت جوجل")
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--sheet", help="معرّف شيت جوجل (اللي بالرابط بين /d/ و /edit)")
    src.add_argument("--csv", help="ملف CSV محلي بدل الشيت")
    src.add_argument("--xlsx", help="ملف إكسل محلي بدل الشيت")
    ap.add_argument("--gid", help="معرّف التبويب داخل الشيت (اختياري)")
    ap.add_argument("--out", default=".", help="مجلد الإخراج")
    ap.add_argument("--template", default="site_template.html",
                    help="قالب الموقع اللي فيه __DATA__")
    args = ap.parse_args()

    out_dir = Path(args.out).expanduser()
    out_dir.mkdir(parents=True, exist_ok=True)

    if args.csv:
        raw = read_rows(Path(args.csv).expanduser().read_text(encoding="utf-8-sig"))
    elif args.xlsx:
        raw = read_xlsx(Path(args.xlsx).expanduser())
    else:
        raw = fetch_sheet(args.sheet, args.gid, keep_xlsx=out_dir / "sheet-backup.xlsx")

    if not raw:
        sys.exit("ما لقيت صفوف. تأكد من رؤوس الأعمدة بالشيت.")

    rows = [clean(r, i) for i, r in enumerate(raw, 1)]
    rows, dropped = dedupe(rows)

    cities = {}
    for r in rows:
        cities[r["city"]] = cities.get(r["city"], 0) + 1
    ordered_cities = sorted(cities, key=lambda c: (c != AMMAN, -cities[c], c))

    data = {
        "meta": {
            "source": "شيت جوجل — دليل شبكة MedNet",
            "count": len(rows),
            "specialties": sorted({r["specialty"] for r in rows if r["specialty"]}),
            "cities": ordered_cities,
            "areas": sorted({r["area"] for r in rows if r["area"]}),
        },
        "providers": rows,
    }

    json_path = out_dir / "doctors.json"
    json_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")

    if dropped:
        dup_path = out_dir / "duplicates.csv"
        with open(dup_path, "w", encoding="utf-8-sig", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(dropped[0].keys()))
            w.writeheader()
            w.writerows(dropped)

    xlsx_path = out_dir / "doctors.xlsx"
    has_xlsx = write_xlsx(rows, xlsx_path)

    tpl = Path(args.template).expanduser()
    if tpl.exists():
        html = tpl.read_text(encoding="utf-8").replace(
            "__DATA__", json.dumps(data, ensure_ascii=False))
        (out_dir / "index.html").write_text(html, encoding="utf-8")

    print(f"الصفوف بعد التنظيف: {len(rows)}   |   محذوف كمكرر: {len(dropped)}")
    print(f"المحافظات: " + "، ".join(f"{c} ({cities[c]})" for c in ordered_cities))
    print(f"\nالملفات: {json_path}")
    if has_xlsx:
        print(f"         {xlsx_path}")
    if dropped:
        print(f"         {out_dir/'duplicates.csv'}  (راجعها قبل ما تحذفها من الشيت)")
    if tpl.exists():
        print(f"         {out_dir/'index.html'}")
    else:
        print(f"\nما لقيت القالب {tpl} — تخطيت بناء الموقع.")


if __name__ == "__main__":
    main()
