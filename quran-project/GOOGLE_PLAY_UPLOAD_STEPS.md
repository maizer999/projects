# Google Play Console — Upload Steps

Signed release bundle: `Quran/build/app/outputs/bundle/release/app-release.aab` (55.2 MB)

## Prerequisites (do first if not done)
1. **Pay the $25** at https://play.google.com/console/signup and complete identity verification (can take a few days for personal accounts).
2. **Host a privacy policy** somewhere public (GitHub Pages works — add a `quran-project/privacy.html` and link it from `maizer999.github.io/projects/quran-project/privacy.html`). Play **will reject** without one.
3. Prepare these assets:
   - App icon 512×512 PNG
   - Feature graphic 1024×500 PNG
   - 2–8 phone screenshots (from a real device: `flutter screenshot` after `flutter install --release`)
   - Short description (≤80 chars) and full description (≤4000 chars), ideally bilingual

## Upload steps in Play Console

### Step 1 — Create the app
https://play.google.com/console → **Create app**
- App name: `Al-Quran` (or your preferred title)
- Default language: Arabic or English
- App or game: **App**
- Free or paid: **Free**
- Accept declarations

### Step 2 — Fill required forms
(Left sidebar — all need green checks before you can publish.)

**App content:**
- Privacy policy URL
- App access: all functionality available without login
- Ads: No
- Content rating: run the IARC questionnaire (religious reference, no violence → likely "Everyone")
- Target audience: 13+ or 18+ (your call)
- News app: No
- COVID-19 contact tracing: No
- Data safety: declare no data collected; add `cdn.islamic.network` as a third-party service for audio streaming
- Government app: No
- Financial features: No
- Health: No

**Store listing:** app name, short + full description, icon, feature graphic, screenshots, category (Books & Reference).

**Store settings:** category, contact email (`maizer99@gmail.com`), website (optional).

### Step 3 — First release (use Internal testing, not Production yet)
Left sidebar → **Testing → Internal testing** → **Create new release**
- Play App Signing prompt appears → click **Continue** (Google generates the real signing key; your `.jks` becomes an upload-only key — exactly what you want).
- **Upload** → drag `app-release.aab`.
- Release name: auto-filled `2 (1.0.1)`.
- Release notes (bilingual):

```
<en-US>
Initial release — Al-Quran Mushaf reader with 20 reciters, offline text, bookmarks, and memorization mode.
</en-US>
<ar>
الإصدار الأول — قارئ مصحف القرآن الكريم مع 20 قارئاً، نص بدون إنترنت، إشارات مرجعية، ووضع الحفظ.
</ar>
```

- **Save → Review release → Start rollout to Internal testing**.
- Add testers: go to the **Testers** tab, create an email list (yourself at minimum), copy the **opt-in URL**, open it on your Android phone → install from Play.

### Step 4 — After internal testing works
- Promote to **Closed testing** (12 testers for 14 days is required before Production for new personal accounts).
- Then **Open testing**, then **Production**.

## Common first-upload rejections to pre-empt
- Missing privacy policy URL → biggest blocker.
- Data safety form says "no data" but app makes network requests → declare `cdn.islamic.network` connections.
- Screenshots that show status bar with notifications/battery issues → use clean device screenshots.
- App name/icon that infringes (e.g. using "Quran Kareem" when another publisher owns it) → use a distinctive name.

## Upload key fingerprints (for reference)
- SHA1: `73:74:64:D3:49:1A:C5:B7:D8:7E:7D:40:06:C5:ED:C4:FB:A4:E9:86`
- SHA256: `0A:FE:6E:FD:F9:DB:98:86:8F:F1:1B:0B:81:51:B2:0E:12:D3:22:3D:AB:F5:AF:B4:90:30:90:83:70:E9:00:A4`

Keystore lives at `~/keys/quran-app-upload.jks`. **Back it up to at least two safe places.** If lost after Play App Signing enrollment, recovery is possible via Google support (that's the whole point of enrolling).
