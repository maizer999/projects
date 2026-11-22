# Baytoti · WhatsApp OTP Auth Plan

تحقق موبايل عبر واتس اب لتطبيق **بيتي**. مجاني بالكامل باستخدام مكتبة
[Baileys](https://github.com/WhiskeySockets/Baileys) غير الرسمية على سيرفر
`mazier.website` (Oracle Always-Free ARM).

> **لماذا هذا الحل؟** واتس اب كلاود API الرسمي من Meta يحتاج Business
> verification وأرقام مخصصة ومدفوعات. Firebase Phone Auth يرسل SMS فقط لا
> واتس اب. Baileys = صفر تكلفة، نشر فوري، مناسب لـ MVP ومستخدمين محدودين.
>
> **المخاطر:** واتس اب ممكن يحظر الرقم عند النشاط الكثيف أو اعتباره بوت.
> الحل: استخدم رقم مخصص (ليس شخصي)، وحدّد معدل الإرسال، وخطّط للهجرة إلى
> الـ Cloud API الرسمي عند الحاجة.

---

## المعمارية

```
┌─────────────┐   HTTPS   ┌────────────────────┐   localhost   ┌──────────────────┐
│  Flutter    │  ──────▶  │  PHP API           │  ──────────▶  │  Node + Baileys  │
│  app        │           │  /api/auth/*       │   :3100       │  (WhatsApp Web)  │
└─────────────┘           └────────────────────┘               └──────────────────┘
                                   │                                     │
                                   ▼                                     ▼
                              ┌─────────┐                           ┌────────┐
                              │ MariaDB │                           │ Auth   │
                              │ baytoti │                           │ folder │
                              └─────────┘                           │ (disk) │
                                                                    └────────┘
```

- **Baileys service**: Node.js تشتغل على `127.0.0.1:3100` فقط — ما تطّلع عالنت.
- **PHP** يناديها عبر `curl` من داخل السيرفر مع `X-Service-Key` كحماية.
- **MariaDB** يخزن OTPs والتوكنات واليوزرز.

---

## 1. Schema (إضافات على `backend/schema.sql`)

```sql
CREATE TABLE IF NOT EXISTS users (
  id         VARCHAR(16)  NOT NULL,
  phone_e164 VARCHAR(20)  NOT NULL,
  name       VARCHAR(50)  NULL,
  created_at DATETIME     NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_phone (phone_e164)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS phone_otps (
  phone_e164  VARCHAR(20)  NOT NULL,
  code_hash   VARCHAR(64)  NOT NULL,   -- SHA-256 لا نخزن الكود مكشوف
  attempts    TINYINT      NOT NULL DEFAULT 0,
  expires_at  DATETIME     NOT NULL,
  created_at  DATETIME     NOT NULL,
  PRIMARY KEY (phone_e164)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS auth_tokens (
  token_hash  VARCHAR(64)  NOT NULL,   -- SHA-256 للتوكن
  user_id     VARCHAR(16)  NOT NULL,
  created_at  DATETIME     NOT NULL,
  last_seen   DATETIME     NOT NULL,
  PRIMARY KEY (token_hash),
  KEY ix_tokens_user (user_id),
  CONSTRAINT fk_tokens_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

> **ملاحظة:** جداول `lists` / `members` / `purchases` ما بتتغير. القوائم بتظل
> مشتركة بالـ `inviteCode`. الـ auth بس يضيف هوية موحّدة.

---

## 2. Baileys Service (Node.js)

**المسار على السيرفر:** `/var/www/baileys-service/`

**الملفات:**
```
baileys-service/
├── package.json
├── server.js          # Express + Baileys
├── .env               # SERVICE_KEY, PORT=3100
└── auth_info_baileys/ # جلسة واتس اب (تُنشأ تلقائيًا)
```

**Endpoint واحد فقط:**
```
POST http://127.0.0.1:3100/send
Header: X-Service-Key: <secret shared with PHP>
Body:   { "phone": "962791234567", "text": "رمز بيتي: 439821" }
Resp:   200 { "ok": true } | 4xx/5xx { "error": "..." }
```

**systemd unit** (`/etc/systemd/system/baileys.service`) علشان يشتغل دائم:
```ini
[Unit]
Description=Baileys WhatsApp bridge for Baytoti
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/baileys-service
ExecStart=/usr/bin/node server.js
Restart=on-failure
EnvironmentFile=/var/www/baileys-service/.env

[Install]
WantedBy=multi-user.target
```

**أول تشغيل (QR pairing):**
```bash
sudo systemctl start baileys
sudo journalctl -u baileys -f    # يظهر QR في الـ logs
```
افتح واتس اب على موبايل مخصص → الأجهزة المربوطة → مسح QR.
الجلسة تتحفظ تحت `auth_info_baileys/` وتظل شغالة.

---

## 3. PHP Endpoints

**ملف جديد:** `/var/www/baytoti-api/auth.php` (مستدعى من `index.php` حسب المسار).

| Method | Path                  | Request                       | Response                                      |
|--------|-----------------------|-------------------------------|-----------------------------------------------|
| POST   | `/api/auth/send-otp`  | `{ phone: "+962791234567" }`  | `{ ok: true, resendIn: 60 }`                  |
| POST   | `/api/auth/verify-otp`| `{ phone, code: "439821" }`   | `{ token, user: { id, phone, name } }`        |
| GET    | `/api/auth/me`        | Header `Authorization: Bearer`| `{ user: { id, phone, name } }` أو `401`       |
| POST   | `/api/auth/logout`    | Header `Authorization: Bearer`| `{ ok: true }`                                |

**قواعد الحماية:**
- OTP: 6 أرقام، صلاحية 5 دقائق، حد أقصى 5 محاولات
- Rate limit: عنوان IP لا يطلب أكثر من 3 OTPs خلال 10 دقائق
- التوكن: 256-bit عشوائي، مخزن كـ SHA-256 (نرسل القيمة الأصلية للموبايل مرة وحدة)
- فورمات موبايل: E.164 فقط (`+962791234567`) — نرفض أي شيء ثاني

---

## 4. Flutter

**ملفات جديدة:**
```
lib/
├── data/
│   └── auth_api.dart        # sendOtp / verifyOtp / me / logout
└── ui/
    ├── phone_login_screen.dart   # إدخال رقم الموبايل
    └── otp_verify_screen.dart    # إدخال الكود (6 خانات)
```

**تدفق المستخدم:**
```
LandingScreen (مع auth)
   │
   ├── مش مسجل  →  PhoneLoginScreen  →  OtpVerifyScreen  →  حفظ التوكن  →  LandingScreen
   └── مسجل     →  ListScreen مباشرة
```

**تخزين التوكن:** `shared_preferences` بالمفتاح `bayti_auth_token`.

**تعديل `repository.dart`:** كل طلب HTTP يضيف الهيدر
`Authorization: Bearer <token>` إذا موجود.

---

## 5. ترتيب التنفيذ

| # | الخطوة                                    | ملفات                                    | يتحقق بـ                             |
|---|-------------------------------------------|------------------------------------------|--------------------------------------|
| 1 | إضافة جداول users / phone_otps / auth_tokens | `backend/schema.sql`                  | `SHOW TABLES` على MariaDB            |
| 2 | كتابة Baileys service                      | `baileys-service/server.js`              | `curl -X POST ...` من داخل السيرفر   |
| 3 | نشر Baileys + systemd + QR pairing         | `/etc/systemd/system/baileys.service`    | `systemctl status baileys` = active  |
| 4 | كتابة PHP endpoints                        | `backend/auth.php`, `backend/index.php`  | `curl /api/auth/send-otp` من اللاب   |
| 5 | شاشة Login + OTP في فلاتر                   | `lib/ui/phone_login_screen.dart` + OTP   | تشغيل التطبيق — وصلت رسالة واتس اب   |
| 6 | ربط التوكن بكل طلبات API                   | `lib/data/repository.dart`               | `GET /api/auth/me` يرجع اليوزر        |
| 7 | اختبار كامل E2E                            | —                                        | تسجيل حساب جديد ثم إنشاء قائمة        |

---

## 6. ملاحظات التشغيل

- **حماية الرقم:** استخدم رقم SIM مخصص للـ WhatsApp Business. لا تشاركه مع
  جهات اتصال شخصية. خفّف الرسائل (خلّي OTP كل عملية مش لكل ضغطة زر).
- **النسخ الاحتياطي:** مجلد `auth_info_baileys/` حيوي — إذا راح رح تحتاج
  تعيد مسح QR. ضمّنه في نسخة احتياطية يومية.
- **الهجرة المستقبلية:** عند تجاوز 500 يوزر، فكّر بالتحوّل إلى
  [WhatsApp Cloud API](https://developers.facebook.com/docs/whatsapp/cloud-api/)
  أو [Twilio WhatsApp API](https://www.twilio.com/whatsapp). واجهة PHP
  هي نفسها — فقط بدّل الـ transport في `baileys-service` أو ألغيها.
